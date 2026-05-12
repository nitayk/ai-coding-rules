#!/usr/bin/env bash
# scan.sh — enumerate skill files, extract frontmatter and UTC mtime
# Usage: scan.sh [CWD_SKILLS_DIR]
# Output: JSON to stdout
#
# When CWD_SKILLS_DIR is omitted, defaults to $PWD/.claude/skills so the
# script always picks up project-level skills without relying on the caller.
#
# Environment:
#   SKILL_STOCKTAKE_GLOBAL_DIR   Override ~/.claude/skills (for testing only;
#                                do not set in production — intended for bats tests)
#   SKILL_STOCKTAKE_PROJECT_DIR  Override project dir detection (for testing only)

set -euo pipefail

GLOBAL_DIR="${SKILL_STOCKTAKE_GLOBAL_DIR:-$HOME/.claude/skills}"
CWD_SKILLS_DIR="${SKILL_STOCKTAKE_PROJECT_DIR:-${1:-$PWD/.claude/skills}}"
# Path to JSONL file containing tool-use observations (optional; used for usage frequency counts).
# Override via SKILL_STOCKTAKE_OBSERVATIONS env var if your setup uses a different path.
OBSERVATIONS="${SKILL_STOCKTAKE_OBSERVATIONS:-$HOME/.claude/observations.jsonl}"

# Validate CWD_SKILLS_DIR looks like a .claude/skills path (defense-in-depth).
# Only warn when the path exists — a nonexistent path poses no traversal risk.
if [[ -n "$CWD_SKILLS_DIR" && -d "$CWD_SKILLS_DIR" && "$CWD_SKILLS_DIR" != */.claude/skills* ]]; then
  echo "Warning: CWD_SKILLS_DIR does not look like a .claude/skills path: $CWD_SKILLS_DIR" >&2
fi

# Extract a frontmatter field (handles both quoted and unquoted single-line values).
# Does NOT support multi-line YAML blocks (| or >) or nested YAML keys.
extract_field() {
  local file="$1" field="$2"
  awk -v f="$field" '
    BEGIN { fm=0 }
    /^---$/ { fm++; next }
    fm==1 {
      n = length(f) + 2
      if (substr($0, 1, n) == f ": ") {
        val = substr($0, n+1)
        gsub(/^"/, "", val)
        gsub(/"$/, "", val)
        print val
        exit
      }
    }
    fm>=2 { exit }
  ' "$file"
}

# Get UTC timestamp N days ago (supports both macOS and GNU date)
date_ago() {
  local n="$1"
  date -u -v-"${n}d" +%Y-%m-%dT%H:%M:%SZ 2>/dev/null ||
  date -u -d "${n} days ago" +%Y-%m-%dT%H:%M:%SZ
}

# Count observations matching a file path since a cutoff timestamp
count_obs() {
  local file="$1" cutoff="$2"
  if [[ ! -f "$OBSERVATIONS" ]]; then
    echo 0
    return
  fi
  jq -r --arg p "$file" --arg c "$cutoff" \
    'select(.tool=="Read" and .path==$p and .timestamp>=$c) | 1' \
    "$OBSERVATIONS" 2>/dev/null | wc -l | tr -d ' '
}

# Scan a directory and produce a JSON array of skill objects
scan_dir_to_json() {
  local dir="$1"
  local c7 c30
  c7=$(date_ago 7)
  c30=$(date_ago 30)

  local tmpdir
  tmpdir=$(mktemp -d)
  # Use a function to avoid embedding $tmpdir in a quoted string (prevents injection
  # if TMPDIR were crafted to contain shell metacharacters).
  local _scan_tmpdir="$tmpdir"
  _scan_cleanup() { rm -rf "$_scan_tmpdir"; }
  trap _scan_cleanup RETURN

  # Pre-aggregate observation counts once per window (one jq pass each) into
  # newline-bounded lookup strings of the form "\t<path>\t<count>\n". Per-file
  # lookup uses a bash regex match (no subprocess) — Bash 3.2-compatible.
  local obs_7d_lookup obs_30d_lookup
  obs_7d_lookup=$'\n'
  obs_30d_lookup=$'\n'
  if [[ -f "$OBSERVATIONS" ]]; then
    # `uniq -c` emits "  N path"; reformat via awk to "\t<path>\t<N>\n" so we
    # can match `\t<file>\t([0-9]+)\n` exactly without false positives.
    obs_7d_lookup+=$(jq -r --arg c "$c7" \
      'select(.tool=="Read" and .timestamp>=$c) | .path' \
      "$OBSERVATIONS" 2>/dev/null \
      | sort | uniq -c \
      | awk '{cnt=$1; $1=""; sub(/^ +/,""); printf "\t%s\t%d\n", $0, cnt}')
    obs_7d_lookup+=$'\n'
    obs_30d_lookup+=$(jq -r --arg c "$c30" \
      'select(.tool=="Read" and .timestamp>=$c) | .path' \
      "$OBSERVATIONS" 2>/dev/null \
      | sort | uniq -c \
      | awk '{cnt=$1; $1=""; sub(/^ +/,""); printf "\t%s\t%d\n", $0, cnt}')
    obs_30d_lookup+=$'\n'
  fi

  local i=0
  while IFS= read -r file; do
    local name desc mtime u7 u30 dp
    name=$(extract_field "$file" "name")
    desc=$(extract_field "$file" "description")
    mtime=$(date -u -r "$file" +%Y-%m-%dT%H:%M:%SZ)
    # In-process bash regex lookup keyed by exact file path. Uses a tab-delimited
    # frame to avoid path-substring false matches. Counts default to 0 on miss.
    u7=0
    if [[ $'\n'"$obs_7d_lookup" =~ $'\t'"${file}"$'\t'([0-9]+) ]]; then
      u7="${BASH_REMATCH[1]}"
    fi
    u30=0
    if [[ $'\n'"$obs_30d_lookup" =~ $'\t'"${file}"$'\t'([0-9]+) ]]; then
      u30="${BASH_REMATCH[1]}"
    fi
    dp="${file/#$HOME/~}"

    jq -n \
      --arg path "$dp" \
      --arg name "$name" \
      --arg description "$desc" \
      --arg mtime "$mtime" \
      --argjson use_7d "$u7" \
      --argjson use_30d "$u30" \
      '{path:$path,name:$name,description:$description,use_7d:$use_7d,use_30d:$use_30d,mtime:$mtime}' \
      > "$tmpdir/$i.json"
    i=$((i+1))
  done < <(find "$dir" -name "*.md" -type f 2>/dev/null | sort)

  if [[ $i -eq 0 ]]; then
    echo "[]"
  else
    jq -s '.' "$tmpdir"/*.json
  fi
}

# --- Main ---

# Canonicalize both dirs so we don't scan the same path twice when the user
# invokes the script from $HOME (CWD_SKILLS_DIR == GLOBAL_DIR after resolution).
_canon() {
  command -v realpath >/dev/null 2>&1 && realpath "$1" 2>/dev/null || echo "$1"
}
_global_canon=""
_cwd_canon=""
[[ -d "$GLOBAL_DIR" ]] && _global_canon=$(_canon "$GLOBAL_DIR")
[[ -n "$CWD_SKILLS_DIR" && -d "$CWD_SKILLS_DIR" ]] && _cwd_canon=$(_canon "$CWD_SKILLS_DIR")

global_found="false"
global_count=0
global_skills="[]"

if [[ -n "$_global_canon" ]]; then
  global_found="true"
  global_skills=$(scan_dir_to_json "$GLOBAL_DIR")
  global_count=$(echo "$global_skills" | jq 'length')
fi

project_found="false"
project_path=""
project_count=0
project_skills="[]"

# Skip the project scan entirely when it canonicalizes to the same path as
# GLOBAL_DIR — otherwise every skill is reported twice (and a per-file dedupe
# would still waste a full directory walk).
if [[ -n "$_cwd_canon" && "$_cwd_canon" != "$_global_canon" ]]; then
  project_found="true"
  project_path="$CWD_SKILLS_DIR"
  project_skills=$(scan_dir_to_json "$CWD_SKILLS_DIR")
  project_count=$(echo "$project_skills" | jq 'length')
fi

# Merge global + project skills into one array
all_skills=$(jq -s 'add' <(echo "$global_skills") <(echo "$project_skills"))

jq -n \
  --arg global_found "$global_found" \
  --argjson global_count "$global_count" \
  --arg project_found "$project_found" \
  --arg project_path "$project_path" \
  --argjson project_count "$project_count" \
  --argjson skills "$all_skills" \
  '{
    scan_summary: {
      global: { found: ($global_found == "true"), count: $global_count },
      project: { found: ($project_found == "true"), path: $project_path, count: $project_count }
    },
    skills: $skills
  }'
