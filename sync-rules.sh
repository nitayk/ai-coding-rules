#!/bin/bash
# Sync script for ai-coding-rules submodule
# Syncs from submodule for Cursor and/or Claude Code (see --target).
# Skills → .agents/skills + .claude/skills (copies). Agents/commands/hooks → .cursor/ or .claude/
#
# Targets: --target cursor|claude|comma-separated (default: cursor)
#
# MANAGED vs USER CONTENT:
# ┌─────────────┬──────────────────────┬──────────────────────┬──────────────────────────────────────────────┐
# │ Type        │ Managed (we sync)    │ User (preserved)     │ How we tell them apart                        │
# ├─────────────┼──────────────────────┼──────────────────────┼──────────────────────────────────────────────┤
# │ Rules       │ .cursor/rules/shared │ .cursor/repo-rules/  │ Submodule vs extra .mdc (never delete unknown │
# │             │ (submodule)          │ + consumer rules     │ consumer rules).                              │
# │ Skills      │ .agents/skills/      │ .cursor/skills/      │ COPY from submodule (never symlink skills —   │
# │             │ (Cursor) +           │ custom names +       │ Cursor & Claude Code won't index symlinked    │
# │             │ .claude/skills/      │ *-workspace/         │ skill trees).                                 │
# │ .gitignore  │ (consumer repo)      │ —                    │ Auto: .agents/, skill *-workspace/, memory    │
# ├─────────────┼──────────────────────┼──────────────────────┼──────────────────────────────────────────────┤
# │ Agents /    │ .cursor|claude/      │ same directories     │ Managed = symlinks into submodule. Extra      │
# │ subagents   │ agents/              │                      │ .md = consumer subagents (preserved).         │
# │ Commands    │ .cursor|claude/      │ same                 │ Same: symlink vs real file = managed vs user. │
# │             │ commands/            │                      │                                               │
# │ Hooks       │ .cursor|claude/hooks │ merged + extras      │ Shared scripts symlinked; repo hooks merged   │
# │             │ + hooks.json/        │                      │ in hooks.json (consumer blocks kept).         │
# │             │ settings.json        │                      │                                               │
# └─────────────┴──────────────────────┴──────────────────────┴──────────────────────────────────────────────┘
#
# Submodule: always at .cursor/rules/shared (never under .claude/rules/ — Claude Code
# auto-loads ALL .md files there, causing context explosion with ~500 files / 2+ MB).
# Run from repo root: bash .cursor/rules/shared/sync-rules.sh
#
# Options:
#   --target       cursor|claude|comma-separated (default: cursor)
#   --dry-run      Show what would be done without making changes
#   --verbose      Show detailed output
#   --force        Force overwrite managed copies when they differ from submodule source
#   --backup       Create backup before overwriting (default: false)

set -eo pipefail

# Configuration
TARGET="cursor"
SKILLS_FILTER="defaults"
NO_SKILLS_FILTER=""
DRY_RUN=false
VERBOSE=false
FORCE=false
BACKUP=false
USE_SYMLINKS=true
STATS_COPIED=0
STATS_SKIPPED=0
STATS_UPDATED=0
STATS_ERRORS=0

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

# Parse command line arguments
while [[ $# -gt 0 ]]; do
  case $1 in
    --dry-run)
      DRY_RUN=true
      shift
      ;;
    --verbose|-v)
      VERBOSE=true
      shift
      ;;
    --force|-f)
      FORCE=true
      shift
      ;;
    --no-backup)
      BACKUP=false
      shift
      ;;
    --backup)
      BACKUP=true
      shift
      ;;
    --copy|--no-symlinks)
      USE_SYMLINKS=false
      shift
      ;;
    --symlinks)
      USE_SYMLINKS=true
      shift
      ;;
    --target)
      if [[ -z "${2:-}" ]] || [[ "$2" == --* ]]; then
        echo "Error: --target requires cursor, claude, or comma-separated combinations"
        exit 1
      fi
      TARGET="$2"
      shift 2
      ;;
    --skills)
      if [[ -z "${2:-}" ]] || [[ "$2" == --* ]]; then
        echo "Error: --skills requires comma-separated groups (e.g. core,git) or 'all'"
        exit 1
      fi
      SKILLS_FILTER="$2"
      shift 2
      ;;
    --no-skills)
      if [[ -z "${2:-}" ]] || [[ "$2" == --* ]]; then
        echo "Error: --no-skills requires comma-separated groups to exclude (e.g. scala,office)"
        exit 1
      fi
      NO_SKILLS_FILTER="$2"
      shift 2
      ;;
    --help|-h)
      echo "Usage: $0 [OPTIONS]"
      echo ""
      echo "Options:"
      echo "  --target       cursor|claude|comma-separated (default: cursor)"
      echo "  --skills       Comma-separated skill groups to sync (e.g. core,git,testing) or 'all'"
      echo "  --no-skills    Comma-separated skill groups to exclude (e.g. scala,office)"
      echo "  --dry-run      Show what would be done without making changes"
      echo "  --verbose      Show detailed output"
      echo "  --force        Overwrite managed files when they differ (does not delete extra consumer files)"
      echo "  --backup       Create backups before overwriting"
      echo "  --no-backup    Don't create backups before overwriting (default)"
      echo "  --copy         Use file copying instead of symlinks (fallback)"
      echo "  --symlinks     Use symlinks (default - faster, automatic updates)"
      echo "  --help         Show this help message"
      echo ""
      echo "Default: Uses symlinks (faster, automatic updates from submodule)"
      echo "Fallback: Use --copy if symlinks don't work in your environment"
      echo ""
      echo "Skill groups (see config/skill-groups.yaml for full list):"
      echo "  core, git, quality, testing, debug, docs, research, agent,"
      echo "  workflow, golang, frontend, office, infra, api, misc, scala"
      exit 0
      ;;
    *)
      echo "Unknown option: $1"
      echo "Use --help for usage information"
      exit 1
      ;;
  esac
done

# Logging functions
log_info() {
  echo -e "${BLUE}ℹ${NC} $1"
}

log_success() {
  echo -e "${GREEN}✓${NC} $1"
  ((STATS_COPIED+=1))
}

log_warn() {
  echo -e "${YELLOW}⚠${NC} $1"
  ((STATS_SKIPPED+=1))
}

log_error() {
  echo -e "${RED}✗${NC} $1" >&2
  ((STATS_ERRORS+=1))
}

log_verbose() {
  if [ "$VERBOSE" = true ]; then
    echo "  [DEBUG] $1"
  fi
}

GITIGNORE_MANAGED_MARKER_BEGIN="# --- ai-coding-rules managed (auto; do not remove) ---"
GITIGNORE_MANAGED_MARKER_END="# --- end ai-coding-rules managed ---"

ensure_managed_gitignore_paths() {
  local repo_root="$1"
  local gi="$repo_root/.gitignore"

  if [ "$DRY_RUN" = true ]; then
    if [ ! -f "$gi" ] || ! grep -qF "$GITIGNORE_MANAGED_MARKER_BEGIN" "$gi" 2>/dev/null; then
      log_info "Would ensure .gitignore has managed entries (.agents/, skill *-workspace/)"
    fi
    return 0
  fi

  if [ -f "$gi" ] && grep -qF "$GITIGNORE_MANAGED_MARKER_BEGIN" "$gi" 2>/dev/null; then
    log_verbose ".gitignore already contains ai-coding-rules managed block"
    return 0
  fi

  if [ ! -f "$gi" ]; then
    touch "$gi"
    log_success "Created .gitignore at repo root"
  fi

  {
    echo ""
    echo "$GITIGNORE_MANAGED_MARKER_BEGIN"
    echo "# Regenerate managed skills: bash .cursor/rules/shared/install.sh"
    echo ".agents/"
    echo "# Skill-creator / eval scratch dirs (not real skills)"
    echo ".cursor/skills/*-workspace/"
    echo ".claude/skills/*-workspace/"
    echo "$GITIGNORE_MANAGED_MARKER_END"
  } >> "$gi"
  log_success "Appended managed paths to .gitignore (.agents/, *-workspace/)"
}

# One-time cleanups for legacy layouts
migrate_deprecated_consumer_paths() {
  local repo_root="$1"

  if [ "$DRY_RUN" = true ]; then
    log_verbose "Would migrate deprecated symlinks under .agents/skills / .claude/skills (if present)"
    return 0
  fi

  # Managed skill trees must be real directories (Cursor / Claude do not index symlinked skill dirs)
  if [ -L "$repo_root/.agents/skills" ]; then
    log_info "Removing deprecated .agents/skills symlink (skills must be copied directories)"
    rm -f "$repo_root/.agents/skills"
  fi
  if [ -L "$repo_root/.claude/skills" ]; then
    log_info "Removing deprecated .claude/skills symlink (Claude requires copied skill directories)"
    rm -f "$repo_root/.claude/skills"
  fi
  if [ -L "$repo_root/.cursor/skills" ]; then
    local t
    t=$(readlink "$repo_root/.cursor/skills" 2>/dev/null || true)
    if [ "$t" = "../.agents/skills" ] || [ "$t" = ".agents/skills" ]; then
      log_info "Removing deprecated .cursor/skills → .agents/skills symlink"
      rm -f "$repo_root/.cursor/skills"
    fi
  fi
}

# Check dependencies
check_dependencies() {
  local missing_deps=()
  if ! command -v jq &> /dev/null; then
    missing_deps+=("jq")
  fi
  if [ ${#missing_deps[@]} -gt 0 ]; then
    log_warn "Missing dependencies: ${missing_deps[*]}"
    log_warn "Some features may not work (e.g., hooks.json merging)"
    log_warn "Install with: brew install jq (macOS) or apt-get install jq (Linux)"
  fi
}

# Resolve skill groups from config/skill-groups.yaml into a newline-separated skill list.
# Uses line-based YAML parsing (no yq/python dependency).
resolve_skill_filter() {
  local include_groups="$1"
  local exclude_groups="${2:-}"
  local config_file="$3"
  local skills_source_dir="${4:-}"

  if [ "$include_groups" = "all" ] && [ -z "$exclude_groups" ]; then
    echo "all"
    return 0
  fi

  if [ ! -f "$config_file" ]; then
    echo -e "${YELLOW}⚠${NC} Skill groups config not found: $config_file — syncing all skills" >&2
    echo "all"
    return 0
  fi

  if [ "$include_groups" = "defaults" ]; then
    local defaults_val
    defaults_val=$(grep -E '^defaults:' "$config_file" | head -1 | sed 's/^defaults:[[:space:]]*//')
    if [ -z "$exclude_groups" ]; then
      local auto_exclude
      auto_exclude=$(grep -E '^exclude_from_defaults:' "$config_file" | head -1 | sed 's/^exclude_from_defaults:[[:space:]]*//')
      if [ -n "$auto_exclude" ]; then
        exclude_groups="$auto_exclude"
      fi
    fi
    if [ -z "$defaults_val" ] || [ "$defaults_val" = "all" ]; then
      if [ -z "$exclude_groups" ]; then
        echo "all"
        return 0
      fi
      include_groups="all"
    else
      include_groups="$defaults_val"
    fi
  fi

  local all_skills=""

  include_groups=$(echo "$include_groups" | tr -d ' ')
  exclude_groups=$(echo "$exclude_groups" | tr -d ' ')

  if [[ ",$include_groups," == *",all,"* ]]; then
    include_groups="all"
  fi

  if [ "$include_groups" = "all" ]; then
    if [ -n "$skills_source_dir" ] && [ -d "$skills_source_dir" ]; then
      for d in "$skills_source_dir"/*/; do
        [ -d "$d" ] && [ -f "$d/SKILL.md" ] && all_skills="$all_skills $(basename "$d")"
      done
    else
      echo "all"
      return 0
    fi
  else
    local known_groups=""
    while IFS= read -r line || [ -n "$line" ]; do
      if [[ "$line" =~ ^\ \ [a-z] ]] && [[ "$line" =~ :$ ]]; then
        known_groups="$known_groups $(echo "$line" | sed 's/^[[:space:]]*//' | sed 's/:$//')"
      fi
    done < "$config_file"

    local current_group=""
    local in_groups=false
    IFS=',' read -ra INCLUDE_ARRAY <<< "$include_groups"

    for g in "${INCLUDE_ARRAY[@]}"; do
      if ! echo "$known_groups" | tr ' ' '\n' | grep -qx "$g"; then
        echo -e "${YELLOW}⚠${NC} Unknown skill group: '$g' (see config/skill-groups.yaml)" >&2
      fi
    done

    while IFS= read -r line || [ -n "$line" ]; do
      [[ "$line" =~ ^[[:space:]]*# ]] && continue
      [[ "$line" =~ ^[[:space:]]*$ ]] && continue

      if [[ "$line" == "groups:" ]]; then
        in_groups=true
        continue
      fi
      [ "$in_groups" = false ] && continue

      if [[ "$line" =~ ^\ \ [a-z] ]] && [[ "$line" =~ :$ ]]; then
        current_group=$(echo "$line" | sed 's/^[[:space:]]*//' | sed 's/:$//')
        continue
      fi

      if [[ "$line" =~ ^\ \ \ \ -\  ]] && [ -n "$current_group" ]; then
        local skill_name
        skill_name=$(echo "$line" | sed 's/^[[:space:]]*-[[:space:]]*//')
        for g in "${INCLUDE_ARRAY[@]}"; do
          if [ "$g" = "$current_group" ]; then
            all_skills="$all_skills $skill_name"
            break
          fi
        done
      fi
    done < "$config_file"
  fi

  if [ -n "$exclude_groups" ]; then
    local exclude_skills=""
    local current_group=""
    local in_groups=false
    IFS=',' read -ra EXCLUDE_ARRAY <<< "$exclude_groups"

    while IFS= read -r line || [ -n "$line" ]; do
      [[ "$line" =~ ^[[:space:]]*# ]] && continue
      [[ "$line" =~ ^[[:space:]]*$ ]] && continue
      if [[ "$line" == "groups:" ]]; then in_groups=true; continue; fi
      [ "$in_groups" = false ] && continue
      if [[ "$line" =~ ^\ \ [a-z] ]] && [[ "$line" =~ :$ ]]; then
        current_group=$(echo "$line" | sed 's/^[[:space:]]*//' | sed 's/:$//')
        continue
      fi
      if [[ "$line" =~ ^\ \ \ \ -\  ]] && [ -n "$current_group" ]; then
        local skill_name
        skill_name=$(echo "$line" | sed 's/^[[:space:]]*-[[:space:]]*//')
        for g in "${EXCLUDE_ARRAY[@]}"; do
          if [ "$g" = "$current_group" ]; then
            exclude_skills="$exclude_skills $skill_name"
            break
          fi
        done
      fi
    done < "$config_file"

    local filtered=""
    for s in $all_skills; do
      local excluded=false
      for e in $exclude_skills; do
        [ "$s" = "$e" ] && excluded=true && break
      done
      [ "$excluded" = false ] && filtered="$filtered $s"
    done
    all_skills="$filtered"
  fi

  echo "$all_skills" | tr ' ' '\n' | sort -u | grep -v '^$'
}

skill_is_allowed() {
  local name="$1"
  local allowed="$2"
  [ "$allowed" = "all" ] && return 0
  echo "$allowed" | grep -qx "$name"
}

# Resolve agent groups from config/skill-groups.yaml based on selected skill groups.
resolve_agent_filter() {
  local include_groups="$1"
  local exclude_groups="${2:-}"
  local config_file="$3"
  local agents_source_dir="${4:-}"

  if [ "$include_groups" = "all" ] && [ -z "$exclude_groups" ]; then
    echo "all"
    return 0
  fi

  if [ ! -f "$config_file" ]; then
    echo "all"
    return 0
  fi

  if [ "$include_groups" = "defaults" ]; then
    local defaults_val
    defaults_val=$(grep -E '^defaults:' "$config_file" | head -1 | sed 's/^defaults:[[:space:]]*//')
    if [ -z "$exclude_groups" ]; then
      local auto_exclude
      auto_exclude=$(grep -E '^exclude_from_defaults:' "$config_file" | head -1 | sed 's/^exclude_from_defaults:[[:space:]]*//')
      if [ -n "$auto_exclude" ]; then
        exclude_groups="$auto_exclude"
      fi
    fi
    if [ -z "$defaults_val" ] || [ "$defaults_val" = "all" ]; then
      if [ -z "$exclude_groups" ]; then
        echo "all"
        return 0
      fi
      include_groups="all"
    else
      include_groups="$defaults_val"
    fi
  fi

  include_groups=$(echo "$include_groups" | tr -d ' ')
  exclude_groups=$(echo "$exclude_groups" | tr -d ' ')

  if [[ ",$include_groups," == *",all,"* ]]; then
    include_groups="all"
  fi

  local all_agents=""
  local in_agent_groups=false
  local current_group=""

  if [ "$include_groups" = "all" ]; then
    if [ -n "$agents_source_dir" ] && [ -d "$agents_source_dir" ]; then
      for f in "$agents_source_dir"/*.md; do
        [ -f "$f" ] || continue
        local bn=$(basename "$f" .md)
        [ "$bn" = "README" ] || [ "$bn" = "UPDATE" ] && continue
        all_agents="$all_agents $bn"
      done
    else
      echo "all"
      return 0
    fi
  else
    IFS=',' read -ra INCLUDE_ARRAY <<< "$include_groups"
    while IFS= read -r line || [ -n "$line" ]; do
      [[ "$line" =~ ^[[:space:]]*# ]] && continue
      [[ "$line" =~ ^[[:space:]]*$ ]] && continue
      if [[ "$line" == "agent_groups:" ]]; then in_agent_groups=true; continue; fi
      if [ "$in_agent_groups" = true ] && [[ "$line" =~ ^[a-z] ]]; then in_agent_groups=false; continue; fi
      [ "$in_agent_groups" = false ] && continue

      if [[ "$line" =~ ^\ \ [a-z] ]] && [[ "$line" =~ :$ ]]; then
        current_group=$(echo "$line" | sed 's/^[[:space:]]*//' | sed 's/:$//')
        continue
      fi
      if [[ "$line" =~ ^\ \ \ \ -\  ]] && [ -n "$current_group" ]; then
        local agent_name
        agent_name=$(echo "$line" | sed 's/^[[:space:]]*-[[:space:]]*//')
        for g in "${INCLUDE_ARRAY[@]}"; do
          if [ "$g" = "$current_group" ]; then
            all_agents="$all_agents $agent_name"
            break
          fi
        done
      fi
    done < "$config_file"
  fi

  if [ -n "$exclude_groups" ]; then
    local exclude_agents=""
    local in_agent_groups=false
    local current_group=""
    IFS=',' read -ra EXCLUDE_ARRAY <<< "$exclude_groups"
    while IFS= read -r line || [ -n "$line" ]; do
      [[ "$line" =~ ^[[:space:]]*# ]] && continue
      [[ "$line" =~ ^[[:space:]]*$ ]] && continue
      if [[ "$line" == "agent_groups:" ]]; then in_agent_groups=true; continue; fi
      if [ "$in_agent_groups" = true ] && [[ "$line" =~ ^[a-z] ]]; then in_agent_groups=false; continue; fi
      [ "$in_agent_groups" = false ] && continue
      if [[ "$line" =~ ^\ \ [a-z] ]] && [[ "$line" =~ :$ ]]; then
        current_group=$(echo "$line" | sed 's/^[[:space:]]*//' | sed 's/:$//')
        continue
      fi
      if [[ "$line" =~ ^\ \ \ \ -\  ]] && [ -n "$current_group" ]; then
        local agent_name
        agent_name=$(echo "$line" | sed 's/^[[:space:]]*-[[:space:]]*//')
        for g in "${EXCLUDE_ARRAY[@]}"; do
          if [ "$g" = "$current_group" ]; then
            exclude_agents="$exclude_agents $agent_name"
            break
          fi
        done
      fi
    done < "$config_file"

    local filtered=""
    for a in $all_agents; do
      local excluded=false
      for e in $exclude_agents; do
        [ "$a" = "$e" ] && excluded=true && break
      done
      [ "$excluded" = false ] && filtered="$filtered $a"
    done
    all_agents="$filtered"
  fi

  echo "$all_agents" | tr ' ' '\n' | sort -u | grep -v '^$'
}

agent_is_allowed() {
  local name="$1"
  local allowed="$2"
  [ "$allowed" = "all" ] && return 0
  local base="${name%.md}"
  echo "$allowed" | grep -qx "$base"
}

validate_json() {
  local file="$1"
  [ ! -f "$file" ] && return 0
  if command -v jq &> /dev/null; then
    if ! jq empty "$file" 2>/dev/null; then
      log_error "Invalid JSON: $file"
      return 1
    fi
  fi
  return 0
}

get_checksum() {
  local file="$1"
  if command -v md5sum &> /dev/null; then
    md5sum < "$file" | cut -d' ' -f1
  elif command -v md5 &> /dev/null; then
    md5 -q "$file"
  elif command -v shasum &> /dev/null; then
    shasum -a 256 < "$file" | cut -d' ' -f1 | head -c 32
  else
    stat -f%z%m "$file" 2>/dev/null || stat -c%s%Y "$file" 2>/dev/null || echo "unknown"
  fi
}

files_identical() {
  local file1="$1"
  local file2="$2"
  [ ! -f "$file1" ] || [ ! -f "$file2" ] && return 1
  if diff -q "$file1" "$file2" > /dev/null 2>&1; then
    return 0
  fi
  local sum1=$(get_checksum "$file1")
  local sum2=$(get_checksum "$file2")
  [ "$sum1" = "$sum2" ]
}

create_backup() {
  local file="$1"
  local backup_dir="$2"
  [ "$BACKUP" = false ] && return 0
  if [ -f "$file" ]; then
    mkdir -p "$backup_dir"
    local backup_file="$backup_dir/$(basename "$file").backup.$(date +%Y%m%d_%H%M%S)"
    if [ "$DRY_RUN" = false ]; then
      cp "$file" "$backup_file"
      log_verbose "Backed up to: $backup_file"
    fi
  fi
}

cleanup_old_backups() {
  local backup_base_dir="$1"
  local max_backups=3
  [ "$BACKUP" = false ] || [ "$DRY_RUN" = true ] && return 0
  local backup_parent_dir=$(dirname "$backup_base_dir")
  local backup_dirs=()
  if [ -d "$backup_parent_dir" ]; then
    while IFS= read -r line; do
      [ -n "$line" ] && backup_dirs+=("$line")
    done < <(find "$backup_parent_dir" -maxdepth 1 -type d -name ".setup-backup-*" -exec stat -f '%m %N' {} \; 2>/dev/null | sort -n | cut -d' ' -f2-)
  fi
  local count=${#backup_dirs[@]}
  if [ "$count" -gt "$max_backups" ]; then
    local to_remove=$((count - max_backups))
    log_info "Found $count backup dirs, keeping $max_backups, removing $to_remove oldest"
    for ((i=0; i<to_remove; i++)); do
      local dir_to_remove="${backup_dirs[$i]}"
      [ -d "$dir_to_remove" ] && rm -rf "$dir_to_remove" || true
    done
  fi
}

merge_hooks_json() {
  local shared_file="$1"
  local repo_file="$2"
  local output_file="$3"
  ! validate_json "$shared_file" && { log_error "Shared hooks.json is invalid"; return 1; }
  [ -f "$repo_file" ] && ! validate_json "$repo_file" && { log_error "Repo hooks.json is invalid"; return 1; }

  if [ ! -f "$repo_file" ]; then
    [ "$DRY_RUN" = false ] && cp "$shared_file" "$output_file"
    log_verbose "No repo hooks.json, copying shared hooks.json"
    return 0
  fi

  if command -v jq &> /dev/null; then
    if [ "$DRY_RUN" = false ]; then
      jq -s '
        .[0] as $shared | .[1] as $repo |
        {
          version: ($shared.version // $repo.version // 1),
          hooks: (
            ($shared.hooks // {}) as $shared_hooks |
            ($repo.hooks // {}) as $repo_hooks |
            (($shared_hooks | keys) + ($repo_hooks | keys) | unique) as $all_keys |
            reduce $all_keys[] as $key ({};
              .[$key] = (
                (($shared_hooks[$key] // []) + ($repo_hooks[$key] // [])) |
                reduce .[] as $item ([]; if index($item) then . else . + [$item] end)
              )
            )
          )
        }
      ' "$shared_file" "$repo_file" > "$output_file"
      if ! validate_json "$output_file"; then
        log_error "Merged hooks.json is invalid, keeping repo version"
        cp "$repo_file" "$output_file"
        return 1
      fi
    else
      log_verbose "Would merge hooks.json (shared + repo-specific)"
    fi
  else
    log_warn "jq not found. Cannot merge hooks.json automatically. Copying shared hooks.json."
    [ "$DRY_RUN" = false ] && cp "$shared_file" "$output_file"
  fi
}

# Shared hooks.json contains both Claude (PascalCase) and Cursor (camelCase) keys.
# Strip the irrelevant keys for each harness.
filter_hooks_json_for_target() {
  local file="$1"
  local target="$2"
  [ ! -f "$file" ] || ! command -v jq &>/dev/null && return 0
  [ "$DRY_RUN" = true ] && { log_verbose "Would filter hooks.json for target $target"; return 0; }

  local tmp
  tmp=$(mktemp)
  if [ "$target" = "cursor" ]; then
    if ! jq 'del(.hooks.SessionStart, .hooks.PreToolUse, .hooks.PostToolUse, .hooks.PreCompact, .hooks.Stop)' "$file" >"$tmp"; then
      rm -f "$tmp"
      log_warn "hooks.json filter failed for cursor (jq error); leaving file unchanged"
      return 0
    fi
  elif [ "$target" = "claude" ]; then
    if ! jq 'del(.hooks.postToolUse, .hooks.sessionStart, .hooks.stop)' "$file" >"$tmp"; then
      rm -f "$tmp"
      log_warn "hooks.json filter failed for claude (jq error); leaving file unchanged"
      return 0
    fi
  else
    rm -f "$tmp"
    return 0
  fi
  mv "$tmp" "$file"
  log_verbose "Filtered hooks.json for target $target"
}

create_symlink() {
  local source="$1"
  local dest="$2"
  local item_name="$3"

  if [ ! -e "$source" ]; then
    log_error "Source not found: $source"
    return 1
  fi

  local dest_dir=$(dirname "$dest")
  [ "$DRY_RUN" = false ] && mkdir -p "$dest_dir"
  local source_abs=$(cd "$(dirname "$source")" && pwd)/$(basename "$source")

  local dest_dir_abs
  if [ -d "$dest_dir" ]; then
    dest_dir_abs=$(cd "$dest_dir" && pwd)
  else
    dest_dir_abs="$PWD/${dest_dir#./}"
  fi

  local relative_path=$(python3 -c "
import os
source = '$source_abs'
dest_dir = '$dest_dir_abs'
rel = os.path.relpath(source, dest_dir)
print(rel)
" 2>/dev/null || echo "../rules/shared/$(basename "$source")")

  if [ -L "$dest" ]; then
    local current_target=$(readlink "$dest")
    local normalized_current="$current_target"
    local normalized_new="$relative_path"
    if [ -d "$dest_dir" ]; then
      normalized_current=$(cd "$dest_dir" && cd "$current_target" 2>/dev/null && pwd || echo "$current_target")
      normalized_new=$(cd "$dest_dir" && cd "$relative_path" 2>/dev/null && pwd || echo "$relative_path")
    fi
    if [ "$normalized_current" = "$normalized_new" ] || [ "$current_target" = "$relative_path" ]; then
      log_verbose "Skipping $item_name (symlink already correct)"
      return 0
    fi
  fi

  if [ -e "$dest" ] && [ ! -L "$dest" ]; then
    if [ "$FORCE" = false ]; then
      log_warn "Skipping $item_name (repo-specific file exists, use --force to overwrite)"
      return 0
    fi
  fi

  if [ "$DRY_RUN" = false ]; then
    mkdir -p "$dest_dir"
    rm -f "$dest"
    ln -sf "$relative_path" "$dest"
    log_success "Linked $item_name → $relative_path"
  else
    log_info "Would link $item_name → $relative_path"
  fi

  ((STATS_UPDATED+=1))
  return 0
}

smart_copy() {
  local source="$1"
  local dest="$2"
  local item_name="$3"
  local backup_dir="${4:-}"
  local make_executable="${5:-false}"

  if [ ! -f "$source" ]; then
    log_error "Source file not found: $source"
    return 1
  fi

  if [ "$USE_SYMLINKS" = true ]; then
    create_symlink "$source" "$dest" "$item_name"
    return $?
  fi

  if [ -f "$dest" ]; then
    if files_identical "$source" "$dest"; then
      log_verbose "Skipping $item_name (already up to date)"
      return 0
    fi
    if [ ! -L "$dest" ] && [ "$FORCE" = false ]; then
      log_warn "Skipping $item_name (repo-specific file exists, use --force to overwrite)"
      return 0
    fi
    [ -n "$backup_dir" ] && create_backup "$dest" "$backup_dir"
  fi

  if [ "$DRY_RUN" = false ]; then
    mkdir -p "$(dirname "$dest")"
    cp "$source" "$dest"
    [ "$make_executable" = true ] && chmod +x "$dest"
    log_success "Synced $item_name"
  else
    log_info "Would sync $item_name"
  fi

  ((STATS_UPDATED+=1))
  return 0
}

smart_copy_dir() {
  local source_dir="$1"
  local dest_dir="$2"
  local item_name="$3"
  local backup_dir="${4:-}"

  if [ ! -d "$source_dir" ]; then
    log_error "Source directory not found: $source_dir"
    return 1
  fi

  if [ "$USE_SYMLINKS" = true ]; then
    create_symlink "$source_dir" "$dest_dir" "$item_name"
    return $?
  fi

  if [ -d "$dest_dir" ] && [ ! -L "$dest_dir" ]; then
    local main_file=""
    [ -f "$source_dir/SKILL.md" ] && main_file="SKILL.md"
    [ -z "$main_file" ] && [ -f "$source_dir/README.md" ] && main_file="README.md"

    if [ -n "$main_file" ] && [ -f "$dest_dir/$main_file" ]; then
      if files_identical "$source_dir/$main_file" "$dest_dir/$main_file"; then
        log_verbose "Skipping $item_name (already up to date)"
        return 0
      fi
    fi

    if [ "$FORCE" = false ]; then
      log_warn "Skipping $item_name (repo-specific directory exists, use --force to overwrite)"
      return 0
    fi

    [ -n "$backup_dir" ] && create_backup "$dest_dir" "$backup_dir" 2>/dev/null || true
  fi

  if [ "$DRY_RUN" = false ]; then
    mkdir -p "$(dirname "$dest_dir")"
    rm -rf "$dest_dir"
    cp -r "$source_dir" "$dest_dir"
    log_success "Synced $item_name"
  else
    log_info "Would sync $item_name"
  fi

  ((STATS_UPDATED+=1))
  return 0
}

sync_file_directory() {
  local source_dir="$1"
  local dest_dir="$2"
  local item_type="$3"
  local backup_subdir="$4"
  local skip_pattern="${5:-README.md}"

  if [ ! -d "$source_dir" ]; then
    log_verbose "${item_type^}s directory not found (OK if running from the repo itself)"
    return 0
  fi

  echo ""
  local cap="${item_type:0:1}"
  cap=$(echo "$cap" | tr '[:lower:]' '[:upper:]')
  cap="${cap}${item_type:1}"
  log_info "Syncing ${cap}s..."
  [ "$DRY_RUN" = false ] && mkdir -p "$dest_dir"

  local count=0
  if [ "$item_type" = "skill" ]; then
    # Skills MUST be copied — Cursor & Claude Code do not discover symlinked skill dirs
    local original_use_symlinks="$USE_SYMLINKS"
    USE_SYMLINKS=false

    for item_path in "$source_dir"/*/; do
      if [ -d "$item_path" ] && [ -f "$item_path/SKILL.md" ]; then
        local item_name=$(basename "$item_path")
        if ! skill_is_allowed "$item_name" "$RESOLVED_SKILLS"; then
          log_verbose "Skipped skill (not in selected groups): $item_name"
          continue
        fi
        smart_copy_dir "$item_path" "$dest_dir/$item_name" "${item_type}: $item_name" "$BACKUP_DIR/$backup_subdir" || true
        ((count+=1))
      fi
    done

    USE_SYMLINKS="$original_use_symlinks"
  else
    for item_file in "$source_dir"/*.md; do
      if [ -f "$item_file" ]; then
        local item_name=$(basename "$item_file")
        [ "$item_name" = "$skip_pattern" ] && continue
        if [ "$item_type" = "agent" ] && ! agent_is_allowed "$item_name" "$RESOLVED_AGENTS"; then
          log_verbose "Skipped agent (not in selected groups): ${item_name%.md}"
          continue
        fi
        smart_copy "$item_file" "$dest_dir/$item_name" "${item_type}: $item_name" "$BACKUP_DIR/$backup_subdir" || true
        ((count+=1))
      fi
    done
  fi

  # Remove managed items excluded by filter. Custom/consumer items are never touched.
  local removed=0
  if [ "$item_type" = "skill" ]; then
    for dest_item in "$dest_dir"/*/; do
      [ -d "$dest_item" ] || continue
      local dest_name=$(basename "$dest_item")
      if [ -d "$source_dir/$dest_name" ] && [ -f "$source_dir/$dest_name/SKILL.md" ]; then
        if ! skill_is_allowed "$dest_name" "$RESOLVED_SKILLS"; then
          if [ "$DRY_RUN" = true ]; then
            log_info "Would remove excluded skill: $dest_name"
          else
            rm -rf "$dest_item"
            log_verbose "Removed excluded skill: $dest_name"
          fi
          ((removed+=1))
        fi
      fi
    done
  elif [ "$item_type" = "agent" ]; then
    for dest_file in "$dest_dir"/*.md; do
      [ -f "$dest_file" ] || continue
      local dest_name=$(basename "$dest_file")
      [ "$dest_name" = "$skip_pattern" ] && continue
      if [ -f "$source_dir/$dest_name" ]; then
        if ! agent_is_allowed "$dest_name" "$RESOLVED_AGENTS"; then
          if [ "$DRY_RUN" = true ]; then
            log_info "Would remove excluded agent: ${dest_name%.md}"
          else
            rm -f "$dest_file"
            log_verbose "Removed excluded agent: ${dest_name%.md}"
          fi
          ((removed+=1))
        fi
      fi
    done
  fi

  echo ""
  local cap="${item_type:0:1}"
  cap=$(echo "$cap" | tr '[:lower:]' '[:upper:]')
  cap="${cap}${item_type:1}"
  if [ "$USE_SYMLINKS" = true ]; then
    log_info "${cap}s linked (using symlinks - automatic updates)"
  else
    log_info "${cap}s synced (copied)"
  fi
  [ "$removed" -gt 0 ] && log_info "Removed $removed excluded ${item_type}(s) from prior install"
}

resolve_target_paths() {
  local t="$1"
  case "$t" in
    cursor)
      SKILLS_DEST=".agents/skills"
      USER_SKILLS_DIR=".cursor/skills"
      MIGRATE_CURSOR_SKILLS=true
      MIGRATE_CLAUDE_SKILLS=false
      AGENTS_DEST=".cursor/agents"
      COMMANDS_DEST=".cursor/commands"
      MEMORY_DIR=".cursor/memory"
      HOOKS_DIR=".cursor/hooks"
      HOOKS_JSON=".cursor/hooks.json"
      BACKUP_BASE=".cursor"
      ;;
    claude)
      SKILLS_DEST=".claude/skills"
      USER_SKILLS_DIR=""
      MIGRATE_CURSOR_SKILLS=false
      MIGRATE_CLAUDE_SKILLS=false
      AGENTS_DEST=".claude/agents"
      COMMANDS_DEST=".claude/commands"
      MEMORY_DIR=".claude/memory"
      HOOKS_DIR=".claude/hooks"
      HOOKS_JSON=".claude/hooks.json"
      BACKUP_BASE=".claude"
      ;;
    *)
      log_error "Unknown target: $t (use cursor, claude, or comma-separated)"
      exit 1
      ;;
  esac
}

# Prevent Claude Code from loading Cursor-specific paths
ensure_claude_isolation() {
  local repo_root="$1"
  local settings_file="$repo_root/.claude/settings.json"
  local deny_patterns='["Read(./.cursor/**)","Read(./.agent-rules/**)"]'
  local allow_patterns='["Bash(rm -rf .claude/skills/*)","Bash(rm -rf .claude/agents/*)","Bash(rm -rf .claude/hooks/*)","Bash(rm -rf .agents/skills/*)","Bash(rm .claude/*)","Bash(rm .agents/*)"]'

  if [ "$DRY_RUN" = true ]; then
    log_info "Would ensure Claude isolation: permissions.deny + allow in $settings_file"
    return 0
  fi

  mkdir -p "$repo_root/.claude"
  if [ -f "$settings_file" ]; then
    if command -v jq &>/dev/null; then
      if ! jq -e ".permissions.deny" "$settings_file" &>/dev/null; then
        jq --argjson deny "$deny_patterns" '. + {permissions: ((.permissions // {}) + {deny: $deny})}' "$settings_file" > "${settings_file}.tmp" && mv "${settings_file}.tmp" "$settings_file"
        log_success "Added permissions.deny to .claude/settings.json (Claude isolation)"
      else
        log_verbose "permissions.deny already present in .claude/settings.json"
      fi
      if ! jq -e ".permissions.allow" "$settings_file" &>/dev/null; then
        jq --argjson allow "$allow_patterns" '.permissions.allow = $allow' "$settings_file" > "${settings_file}.tmp" && mv "${settings_file}.tmp" "$settings_file"
        log_success "Added permissions.allow to .claude/settings.json (managed path cleanup)"
      else
        log_verbose "permissions.allow already present in .claude/settings.json"
      fi
    else
      log_warn "jq not found - cannot update .claude/settings.json for isolation"
    fi
  else
    if command -v jq &>/dev/null; then
      echo "{\"permissions\":{\"deny\":$deny_patterns,\"allow\":$allow_patterns}}" | jq . > "$settings_file"
    else
      echo "{\"permissions\":{\"deny\":$deny_patterns,\"allow\":$allow_patterns}}" > "$settings_file"
    fi
    log_success "Created .claude/settings.json with permissions (deny + allow)"
  fi
}

# Main script
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# Detect repo root
if [ -n "${REPO_ROOT:-}" ] && [ -d "${REPO_ROOT}" ]; then
  log_info "Using REPO_ROOT from environment"
elif [[ "$SCRIPT_DIR" == *"/.cursor/rules/shared" ]] || [[ "$SCRIPT_DIR" == *"/.claude/rules/shared" ]]; then
  REPO_ROOT="$(cd "$SCRIPT_DIR/../../.." && pwd)"
  log_info "Detected submodule at $( [[ "$SCRIPT_DIR" == *"/.claude/"* ]] && echo ".claude/rules/shared/" || echo ".cursor/rules/shared/" )"
elif [[ "$SCRIPT_DIR" == *"/ai-coding-rules" ]]; then
  REPO_ROOT="$SCRIPT_DIR"
  log_info "Running from ai-coding-rules repo (development mode)"
else
  REPO_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"
  log_warn "Script not in .cursor/rules/shared/ or .claude/rules/shared/"
  log_warn "Continuing anyway..."
fi

if [ "$DRY_RUN" = true ]; then
  log_info "DRY RUN MODE - No changes will be made"
  echo ""
fi

log_info "Setting up ai-coding-rules..."
log_verbose "Repo root: $REPO_ROOT"
log_verbose "Script dir: $SCRIPT_DIR"

# Validate submodule is initialized (if running as submodule)
if [[ "$SCRIPT_DIR" == *"/.cursor/rules/shared" ]] || [[ "$SCRIPT_DIR" == *"/.claude/rules/shared" ]]; then
  if [ ! -d "$SCRIPT_DIR/skills" ] && [ ! -d "$SCRIPT_DIR/agents" ] && [ ! -d "$SCRIPT_DIR/commands" ]; then
    log_error "Submodule appears to be uninitialized!"
    log_error "Source directories not found: $SCRIPT_DIR/{skills,agents,commands}"
    log_error ""
    log_error "Please initialize the submodule first:"
    log_error "  git submodule update --init --recursive .cursor/rules/shared"
    exit 1
  fi
fi

check_dependencies

# Validate TARGET
TARGET_INVALID=false
VALID_TARGET_COUNT=0
IFS=',' read -ra _TARGET_PARTS <<< "$TARGET"
for _part in "${_TARGET_PARTS[@]}"; do
  [ -z "$_part" ] && continue
  case "$_part" in
    cursor|claude) VALID_TARGET_COUNT=$((VALID_TARGET_COUNT + 1)) ;;
    *) TARGET_INVALID=true ;;
  esac
done
if [ "$TARGET_INVALID" = true ] || [ "$VALID_TARGET_COUNT" -eq 0 ]; then
  log_error "Invalid --target: $TARGET (each segment must be cursor or claude)"
  exit 1
fi

BACKUP_DIR="$REPO_ROOT/.cursor/.setup-backup-$(date +%Y%m%d_%H%M%S)"
if [ "$BACKUP" = true ] && [ "$DRY_RUN" = false ]; then
  mkdir -p "$BACKUP_DIR"
fi

ensure_managed_gitignore_paths "$REPO_ROOT"
migrate_deprecated_consumer_paths "$REPO_ROOT"

# Resolve skill and agent filters
SKILL_GROUPS_CONFIG="$SCRIPT_DIR/config/skill-groups.yaml"
RESOLVED_SKILLS=$(resolve_skill_filter "$SKILLS_FILTER" "$NO_SKILLS_FILTER" "$SKILL_GROUPS_CONFIG" "$SCRIPT_DIR/skills")
if [ "$RESOLVED_SKILLS" != "all" ]; then
  SKILL_COUNT=$(echo "$RESOLVED_SKILLS" | wc -l | tr -d ' ')
  log_info "Skill filter: $SKILL_COUNT skills selected (groups: ${SKILLS_FILTER}${NO_SKILLS_FILTER:+, excluding: $NO_SKILLS_FILTER})"
else
  log_verbose "Skills: syncing all (no filter)"
fi

RESOLVED_AGENTS=$(resolve_agent_filter "$SKILLS_FILTER" "$NO_SKILLS_FILTER" "$SKILL_GROUPS_CONFIG" "$SCRIPT_DIR/agents")
if [ "$RESOLVED_AGENTS" != "all" ]; then
  AGENT_COUNT=$(echo "$RESOLVED_AGENTS" | wc -l | tr -d ' ')
  log_info "Agent filter: $AGENT_COUNT agents selected (matching skill groups)"
else
  log_verbose "Agents: syncing all (no filter)"
fi

# Loop over each target
for CURRENT_TARGET in ${TARGET//,/ }; do
  resolve_target_paths "$CURRENT_TARGET"

  echo ""
  log_info "=== Syncing for target: $CURRENT_TARGET ==="

  if [ "$DRY_RUN" = false ]; then
    mkdir -p "$REPO_ROOT/.cursor" "$REPO_ROOT/.claude" "$REPO_ROOT/.agents" 2>/dev/null || true
    mkdir -p "$REPO_ROOT/$SKILLS_DEST" "$REPO_ROOT/$AGENTS_DEST" "$REPO_ROOT/$COMMANDS_DEST"
  fi

  sync_file_directory "$SCRIPT_DIR/skills" "$REPO_ROOT/$SKILLS_DEST" "skill" "skills"

  # Remove managed skills from .cursor/skills (migration to .agents/skills)
  if [ -n "$USER_SKILLS_DIR" ] && [ -d "$REPO_ROOT/$USER_SKILLS_DIR" ] && [ -d "$SCRIPT_DIR/skills" ]; then
    if [ "$MIGRATE_CURSOR_SKILLS" = true ]; then
      for item_path in "$SCRIPT_DIR/skills"/*/; do
        if [ -d "$item_path" ] && [ -f "$item_path/SKILL.md" ]; then
          item_name=$(basename "$item_path")
          if [ -d "$REPO_ROOT/$USER_SKILLS_DIR/$item_name" ]; then
            if [ "$DRY_RUN" = true ]; then
              log_info "Would remove managed skill from $USER_SKILLS_DIR: $item_name (now in $SKILLS_DEST)"
            else
              rm -rf "$REPO_ROOT/$USER_SKILLS_DIR/$item_name"
              log_verbose "Removed managed skill from $USER_SKILLS_DIR: $item_name"
            fi
          fi
        fi
      done
    fi
  fi

  sync_file_directory "$SCRIPT_DIR/agents" "$REPO_ROOT/$AGENTS_DEST" "agent" "agents" "README.md"
  sync_file_directory "$SCRIPT_DIR/commands" "$REPO_ROOT/$COMMANDS_DEST" "command" "commands" "README.md"

  # Setup Memory Storage
  echo ""
  log_info "Setting up local memory for $CURRENT_TARGET..."
  MEMORY_FULL="$REPO_ROOT/$MEMORY_DIR"

  if [ "$DRY_RUN" = false ]; then
    mkdir -p "$MEMORY_FULL"
    if [ ! -f "$MEMORY_FULL/active_context.md" ]; then
      cat > "$MEMORY_FULL/active_context.md" <<EOF
# Active Context
## Current Focus
(No active task)

## Recent Decisions
- Setup complete

## Scratchpad
Use this space for temporary notes.
EOF
      log_success "Created private memory: $MEMORY_DIR/active_context.md"
    fi
    GITIGNORE="$REPO_ROOT/.gitignore"
    [ ! -f "$GITIGNORE" ] && touch "$GITIGNORE"
    if ! grep -qF "$MEMORY_DIR/" "$GITIGNORE" 2>/dev/null; then
      printf '\n# Agent Memory (Private State)\n%s/\n' "$MEMORY_DIR" >> "$GITIGNORE"
      log_success "Added $MEMORY_DIR/ to .gitignore"
    fi
    if ! grep -qF "# ECC: agent sessions + hook logs" "$GITIGNORE" 2>/dev/null; then
      cat >> "$GITIGNORE" <<'EOF'

# ECC: agent sessions + hook logs
.claude/sessions/
.cursor/sessions/
.claude/hooks/logs/
.cursor/hooks/logs/
EOF
      log_success "Added ECC session/hook log paths to .gitignore"
    fi
  else
    log_info "Would create memory dir: $MEMORY_FULL"
  fi

  # Sync hooks
  if [ -d "$SCRIPT_DIR/hooks" ]; then
    echo ""
    log_info "Syncing hooks for $CURRENT_TARGET..."
    [ "$DRY_RUN" = false ] && mkdir -p "$REPO_ROOT/$HOOKS_DIR"

    while IFS= read -r -d '' hook_file; do
      rel="${hook_file#"$SCRIPT_DIR/hooks/"}"
      dest_file="$REPO_ROOT/$HOOKS_DIR/$rel"
      if [ "$CURRENT_TARGET" = "cursor" ] && [[ "$rel" == *"/"* ]]; then
        dest_file="$REPO_ROOT/$HOOKS_DIR/$(basename "$rel")"
      fi
      smart_copy "$hook_file" "$dest_file" "hook: $rel" "$BACKUP_DIR/hooks" "true" || true
    done < <(find "$SCRIPT_DIR/hooks" -type f \( -name '*.sh' -o -name '*.py' -o -name '*.js' -o -name '*.cmd' -o -name 'session-start' \) ! -path '*/ecc-hooks/*' -print0 2>/dev/null)

    shared_hooks_json="$SCRIPT_DIR/hooks/hooks.json"
    repo_hooks_json="$REPO_ROOT/$HOOKS_JSON"
    output_hooks_json="$REPO_ROOT/$HOOKS_JSON"
    repo_hooks_exists=false
    repo_hooks_different=false

    if [ -f "$shared_hooks_json" ]; then
      if [ -f "$repo_hooks_json" ]; then
        repo_hooks_exists=true
        if ! files_identical "$shared_hooks_json" "$repo_hooks_json"; then
          repo_hooks_different=true
          [ "$DRY_RUN" = false ] && create_backup "$repo_hooks_json" "$BACKUP_DIR/hooks" 2>/dev/null || true
        fi
      fi

      if [ "$USE_SYMLINKS" = true ] && [ "$repo_hooks_different" = false ]; then
        create_symlink "$shared_hooks_json" "$output_hooks_json" "hooks.json"
      else
        merge_hooks_json "$shared_hooks_json" "$repo_hooks_json" "$output_hooks_json"
        if [ "$repo_hooks_different" = true ]; then
          log_success "Merged hooks.json (shared + repo-specific)"
        elif [ "$repo_hooks_exists" = true ]; then
          log_success "Synced hooks.json (up to date)"
        else
          log_success "Created hooks.json from shared"
        fi
      fi

      if [ -f "$output_hooks_json" ] && [ "$DRY_RUN" = false ]; then
        [ -L "$output_hooks_json" ] && { rm -f "$output_hooks_json"; cp "$shared_hooks_json" "$output_hooks_json"; }
        if command -v jq &>/dev/null; then
          filter_hooks_json_for_target "$output_hooks_json" "$CURRENT_TARGET"

          if [ "$CURRENT_TARGET" = "claude" ]; then
            claude_settings="$REPO_ROOT/.claude/settings.json"
            if [ -f "$claude_settings" ]; then
              tmp_settings=$(mktemp)
              jq -s '
                .[0] as $settings | .[1] as $new_hooks |
                ($settings.hooks // {}) as $existing_hooks |
                ($new_hooks.hooks // {}) as $incoming_hooks |
                (($existing_hooks | keys) + ($incoming_hooks | keys) | unique) as $all_keys |
                (reduce $all_keys[] as $key ({};
                  .[$key] = (
                    (($existing_hooks[$key] // []) + ($incoming_hooks[$key] // [])) |
                    reduce .[] as $item ([]; if index($item) then . else . + [$item] end)
                  )
                )) as $merged_hooks |
                $settings + {hooks: $merged_hooks}
              ' "$claude_settings" "$output_hooks_json" > "$tmp_settings" && mv "$tmp_settings" "$claude_settings"
              log_success "Injected hooks into .claude/settings.json"
            else
              jq '{hooks: .hooks}' "$output_hooks_json" > "$claude_settings"
              log_success "Created .claude/settings.json with hooks"
            fi
            rm -f "$output_hooks_json"
            log_verbose "Removed redundant $output_hooks_json (hooks live in settings.json)"
          fi
        else
          log_warn "jq not installed: hooks.json not filtered per target; install jq for proper Claude/Cursor hook split"
        fi
      fi
    fi

    echo ""
    log_info "Hooks synced for $CURRENT_TARGET"
  fi

  if [ "$CURRENT_TARGET" = "claude" ]; then
    ensure_claude_isolation "$REPO_ROOT"
  fi

done

# Summary
echo ""
if [ "$DRY_RUN" = true ]; then
  log_info "DRY RUN COMPLETE - No changes were made"
else
  log_success "Setup complete!"
fi

echo ""
log_info "Summary:"
echo "  Copied/Updated: $STATS_UPDATED"
echo "  Skipped: $STATS_SKIPPED"
[ "$STATS_ERRORS" -gt 0 ] && echo "  Errors: $STATS_ERRORS"

if [ "$BACKUP" = true ] && [ "$DRY_RUN" = false ] && [ -d "$BACKUP_DIR" ] && [ "$(ls -A "$BACKUP_DIR" 2>/dev/null)" ]; then
  echo ""
  log_info "Backups created in: $BACKUP_DIR"
fi

[ "$BACKUP" = true ] && [ "$DRY_RUN" = false ] && cleanup_old_backups "$REPO_ROOT/.cursor/.setup-backup-placeholder" || true

echo ""
log_info "Synced to (target: $TARGET):"
for t in ${TARGET//,/ }; do
  resolve_target_paths "$t"
  echo "  [$t] skills: $SKILLS_DEST, agents: $AGENTS_DEST, commands: $COMMANDS_DEST"
done

echo ""
if [ "$USE_SYMLINKS" = true ]; then
  log_info "ℹ️  Using symlinks (default - faster, automatic updates)"
  log_info "   If not discovered, use --copy flag to use file copying instead"
else
  log_info "ℹ️  Using file copying (--copy flag enabled)"
fi
echo ""
log_info "📋 Next steps:"
echo "    1. Restart Cursor or Claude Code to pick up new content"
echo ""
log_info "📋 To update later:"
echo "    $ git submodule update --remote .cursor/rules/shared"
echo "    $ bash .cursor/rules/shared/sync-rules.sh --target $TARGET"

[ "$DRY_RUN" = true ] && { echo ""; log_info "Run without --dry-run to apply changes"; }
