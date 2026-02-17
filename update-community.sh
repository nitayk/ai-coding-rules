#!/bin/bash
# Update community skills, agents, commands, and hooks from upstream sources.
#
# Sources:
#   - obra/superpowers  (skills, agents, commands, hooks)
#   - anthropics/skills (skills, spec, template)
#
# Usage:
#   bash update-community.sh              # Update all
#   bash update-community.sh --dry-run    # Show what would change
#   bash update-community.sh --diff       # Show diffs before applying
#
# After running, review changes with `git diff` and commit.

set -eo pipefail

# Configuration
DRY_RUN=false
SHOW_DIFF=false
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
CACHE_DIR="/tmp/ai-coding-rules-upstream"

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

# Parse arguments
while [[ $# -gt 0 ]]; do
  case $1 in
    --dry-run) DRY_RUN=true; shift ;;
    --diff) SHOW_DIFF=true; shift ;;
    --help|-h)
      echo "Usage: $0 [OPTIONS]"
      echo ""
      echo "Updates community skills from upstream repos."
      echo ""
      echo "Options:"
      echo "  --dry-run    Show what would change without applying"
      echo "  --diff       Show diffs before applying changes"
      echo "  --help       Show this help message"
      echo ""
      echo "Sources:"
      echo "  obra/superpowers   -> skills/, agents/, commands/, hooks/"
      echo "  anthropics/skills  -> skills/, spec/, template/"
      echo ""
      echo "After running, review with 'git diff' and commit."
      exit 0
      ;;
    *) echo "Unknown option: $1"; exit 1 ;;
  esac
done

log_info() { echo -e "${BLUE}[info]${NC} $1"; }
log_ok() { echo -e "${GREEN}[ok]${NC} $1"; }
log_warn() { echo -e "${YELLOW}[warn]${NC} $1"; }
log_change() { echo -e "${GREEN}[changed]${NC} $1"; }
log_skip() { echo -e "  [skip] $1"; }

# ─────────────────────────────────────────────────────────────
# Source definitions
# ─────────────────────────────────────────────────────────────
# Format: REPO_URL  LOCAL_NAME
SOURCES=(
  "https://github.com/obra/superpowers.git|superpowers"
  "https://github.com/anthropics/skills.git|anthropics-skills"
)

# What to copy from each source
# Format: SOURCE_DIR|DEST_DIR|TYPE  (TYPE: skills-dirs, files, dir-copy)
SUPERPOWERS_ITEMS=(
  "skills|skills|skills-dirs"
  "agents|agents|files"
  "commands|commands|files"
  "hooks|hooks|files"
)

ANTHROPICS_ITEMS=(
  "skills/docx|skills/docx|dir-copy"
  "skills/pdf|skills/pdf|dir-copy"
  "skills/xlsx|skills/xlsx|dir-copy"
  "skills/pptx|skills/pptx|dir-copy"
  "skills/mcp-builder|skills/mcp-builder|dir-copy"
  "skills/skill-creator|skills/skill-creator|dir-copy"
  "skills/webapp-testing|skills/webapp-testing|dir-copy"
  "skills/frontend-design|skills/frontend-design|dir-copy"
  "skills/web-artifacts-builder|skills/web-artifacts-builder|dir-copy"
  "spec|spec|dir-copy"
  "template|template|dir-copy"
)

# ─────────────────────────────────────────────────────────────
# Clone or update upstream repos
# ─────────────────────────────────────────────────────────────
clone_or_pull() {
  local url="$1"
  local name="$2"
  local dest="$CACHE_DIR/$name"

  if [ -d "$dest/.git" ]; then
    log_info "Updating $name..."
    git -C "$dest" fetch --depth 1 origin main 2>/dev/null || git -C "$dest" fetch --depth 1 origin master 2>/dev/null
    git -C "$dest" reset --hard FETCH_HEAD 2>/dev/null
  else
    log_info "Cloning $name..."
    mkdir -p "$CACHE_DIR"
    git clone --depth 1 "$url" "$dest" 2>/dev/null
  fi

  # Show version info
  local sha=$(git -C "$dest" rev-parse --short HEAD 2>/dev/null)
  local date=$(git -C "$dest" log -1 --format='%ci' 2>/dev/null | cut -d' ' -f1)
  log_ok "$name @ $sha ($date)"
}

# ─────────────────────────────────────────────────────────────
# Sync helpers
# ─────────────────────────────────────────────────────────────
STATS_UPDATED=0
STATS_UNCHANGED=0
STATS_NEW=0

sync_skills_dirs() {
  local src_base="$1"
  local dst_base="$2"

  for skill_dir in "$src_base"/*/; do
    [ -d "$skill_dir" ] || continue
    [ -f "$skill_dir/SKILL.md" ] || continue
    local name=$(basename "$skill_dir")
    sync_dir "$skill_dir" "$dst_base/$name" "skill: $name"
  done
}

sync_files() {
  local src_dir="$1"
  local dst_dir="$2"

  for src_file in "$src_dir"/*; do
    [ -f "$src_file" ] || continue
    local name=$(basename "$src_file")
    [ "$name" = "README.md" ] && continue
    sync_file "$src_file" "$dst_dir/$name" "$name"
  done
}

sync_dir() {
  local src="$1"
  local dst="$2"
  local label="$3"

  if [ ! -d "$dst" ]; then
    if [ "$DRY_RUN" = true ]; then
      log_change "NEW: $label"
    else
      cp -r "$src" "$dst"
      log_change "NEW: $label"
    fi
    ((STATS_NEW+=1))
    return
  fi

  # Check if anything changed (compare recursively)
  if diff -rq "$src" "$dst" >/dev/null 2>&1; then
    log_skip "$label (unchanged)"
    ((STATS_UNCHANGED+=1))
  else
    if [ "$SHOW_DIFF" = true ]; then
      echo ""
      diff -ru "$dst" "$src" 2>/dev/null | head -50 || true
      echo ""
    fi
    if [ "$DRY_RUN" = true ]; then
      log_change "UPDATED: $label"
    else
      rm -rf "$dst"
      cp -r "$src" "$dst"
      log_change "UPDATED: $label"
    fi
    ((STATS_UPDATED+=1))
  fi
}

sync_file() {
  local src="$1"
  local dst="$2"
  local label="$3"

  if [ ! -f "$dst" ]; then
    if [ "$DRY_RUN" = true ]; then
      log_change "NEW: $label"
    else
      mkdir -p "$(dirname "$dst")"
      cp "$src" "$dst"
      log_change "NEW: $label"
    fi
    ((STATS_NEW+=1))
    return
  fi

  if diff -q "$src" "$dst" >/dev/null 2>&1; then
    log_skip "$label (unchanged)"
    ((STATS_UNCHANGED+=1))
  else
    if [ "$SHOW_DIFF" = true ]; then
      echo ""
      diff -u "$dst" "$src" 2>/dev/null | head -30 || true
      echo ""
    fi
    if [ "$DRY_RUN" = true ]; then
      log_change "UPDATED: $label"
    else
      cp "$src" "$dst"
      log_change "UPDATED: $label"
    fi
    ((STATS_UPDATED+=1))
  fi
}

# ─────────────────────────────────────────────────────────────
# Main
# ─────────────────────────────────────────────────────────────
echo ""
echo "=========================================="
echo "  ai-coding-rules: Update Community Sources"
echo "=========================================="
echo ""

if [ "$DRY_RUN" = true ]; then
  log_warn "DRY RUN MODE - no changes will be made"
  echo ""
fi

# Step 1: Clone/update upstream repos
for source in "${SOURCES[@]}"; do
  IFS='|' read -r url name <<< "$source"
  clone_or_pull "$url" "$name"
done

echo ""

# Step 2: Sync from obra/superpowers
log_info "Syncing from obra/superpowers..."
SP="$CACHE_DIR/superpowers"

for item in "${SUPERPOWERS_ITEMS[@]}"; do
  IFS='|' read -r src_rel dst_rel type <<< "$item"
  case "$type" in
    skills-dirs) sync_skills_dirs "$SP/$src_rel" "$SCRIPT_DIR/$dst_rel" ;;
    files)       sync_files "$SP/$src_rel" "$SCRIPT_DIR/$dst_rel" ;;
    dir-copy)    sync_dir "$SP/$src_rel" "$SCRIPT_DIR/$dst_rel" "$dst_rel" ;;
  esac
done

echo ""

# Step 3: Sync from anthropics/skills
log_info "Syncing from anthropics/skills..."
AS="$CACHE_DIR/anthropics-skills"

for item in "${ANTHROPICS_ITEMS[@]}"; do
  IFS='|' read -r src_rel dst_rel type <<< "$item"
  case "$type" in
    skills-dirs) sync_skills_dirs "$AS/$src_rel" "$SCRIPT_DIR/$dst_rel" ;;
    files)       sync_files "$AS/$src_rel" "$SCRIPT_DIR/$dst_rel" ;;
    dir-copy)    sync_dir "$AS/$src_rel" "$SCRIPT_DIR/$dst_rel" "$dst_rel" ;;
  esac
done

# ─────────────────────────────────────────────────────────────
# Summary
# ─────────────────────────────────────────────────────────────
echo ""
echo "=========================================="
echo "  Summary"
echo "=========================================="
echo "  New:       $STATS_NEW"
echo "  Updated:   $STATS_UPDATED"
echo "  Unchanged: $STATS_UNCHANGED"
echo ""

if [ "$DRY_RUN" = true ]; then
  log_warn "Dry run complete. Run without --dry-run to apply."
elif [ "$STATS_UPDATED" -gt 0 ] || [ "$STATS_NEW" -gt 0 ]; then
  log_ok "Updates applied. Review with:"
  echo "  cd $(pwd)"
  echo "  git diff"
  echo "  git add -A && git commit -m 'chore: update community skills from upstream'"
else
  log_ok "Everything is up to date."
fi

echo ""
echo "Upstream cache: $CACHE_DIR"
echo "  (delete to force fresh clone: rm -rf $CACHE_DIR)"
