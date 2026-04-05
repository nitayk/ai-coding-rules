#!/bin/bash
# Install script for ai-coding-rules (Cursor)
# Syncs skills, agents, commands, hooks, and memory into .cursor/
#
# REQUIRED: This repo MUST be at .cursor/rules/shared/
# Run from repo root: bash .cursor/rules/shared/install-cursor.sh
#
# Options:
#   --symlinks     Use symlinks (default - faster, auto-updates)
#   --copy         Use file copying instead
#   --dry-run      Show what would be done
#   --verbose      Show detailed output
#   --force        Force overwrite repo-specific files
#   --backup       Create backup before overwriting

set -eo pipefail

# Configuration
USE_SYMLINKS=true
DRY_RUN=false
VERBOSE=false
FORCE=false
BACKUP=false
STATS_COPIED=0
STATS_SKIPPED=0
STATS_UPDATED=0
STATS_ERRORS=0

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

# Parse arguments
while [[ $# -gt 0 ]]; do
  case $1 in
    --copy|--no-symlinks) USE_SYMLINKS=false; shift ;;
    --symlinks) USE_SYMLINKS=true; shift ;;
    --dry-run) DRY_RUN=true; shift ;;
    --verbose|-v) VERBOSE=true; shift ;;
    --force|-f) FORCE=true; shift ;;
    --backup) BACKUP=true; shift ;;
    --no-backup) BACKUP=false; shift ;;
    --help|-h)
      echo "Usage: $0 [OPTIONS]"
      echo ""
      echo "Syncs ai-coding-rules into .cursor/ for Cursor IDE discovery."
      echo ""
      echo "Options:"
      echo "  --symlinks     Symlink .cursor/skills -> rules/shared/skills; symlink agents/commands/hooks (default)"
      echo "  --copy         Copy each skill dir into .cursor/skills (legacy; use if Cursor ignores symlinked skills)"
      echo "  --dry-run      Show what would be done without making changes"
      echo "  --verbose      Show detailed output"
      echo "  --force        Force overwrite repo-specific files"
      echo "  --backup       Create backups before overwriting"
      echo "  --help         Show this help message"
      exit 0
      ;;
    *) echo "Unknown option: $1. Use --help for usage."; exit 1 ;;
  esac
done

# Logging
log_info() { echo -e "${BLUE}i${NC} $1"; }
log_success() { echo -e "${GREEN}+${NC} $1"; ((STATS_COPIED+=1)); }
log_warn() { echo -e "${YELLOW}!${NC} $1"; ((STATS_SKIPPED+=1)); }
log_error() { echo -e "${RED}x${NC} $1" >&2; ((STATS_ERRORS+=1)); }
log_verbose() { if [ "$VERBOSE" = true ]; then echo "  [DEBUG] $1"; fi; }

# Create symlink or copy file
smart_link_or_copy() {
  local source="$1"
  local dest="$2"
  local name="$3"

  if [ ! -e "$source" ]; then
    log_error "Source not found: $source"
    return 1
  fi

  # Skip if destination exists and is repo-specific (not a symlink)
  if [ -e "$dest" ] && [ ! -L "$dest" ] && [ "$FORCE" = false ]; then
    log_warn "Skipping $name (repo-specific exists, use --force to overwrite)"
    return 0
  fi

  if [ "$DRY_RUN" = true ]; then
    log_info "Would sync $name"
    return 0
  fi

  mkdir -p "$(dirname "$dest")"

  if [ "$USE_SYMLINKS" = true ]; then
    local dest_dir=$(dirname "$dest")
    local relative_path=$(python3 -c "
import os
source = os.path.realpath('$source')
dest_dir = os.path.realpath('$dest_dir')
print(os.path.relpath(source, dest_dir))
" 2>/dev/null || echo "$source")
    rm -rf "$dest"
    ln -sf "$relative_path" "$dest"
    log_success "Linked $name"
  else
    rm -rf "$dest"
    if [ -d "$source" ]; then
      cp -r "$source" "$dest"
    else
      cp "$source" "$dest"
    fi
    log_success "Copied $name"
  fi

  ((STATS_UPDATED+=1))
  return 0
}

# Detect paths
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

if [[ "$SCRIPT_DIR" == *"/.cursor/rules/shared" ]]; then
  REPO_ROOT="$(cd "$SCRIPT_DIR/../../.." && pwd)"
  log_info "Detected submodule at .cursor/rules/shared/"
elif [[ "$SCRIPT_DIR" == *"/ai-coding-rules" ]]; then
  REPO_ROOT="$SCRIPT_DIR"
  log_info "Running from ai-coding-rules repo (development mode)"
else
  REPO_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"
  log_warn "Unexpected location. Expected .cursor/rules/shared/"
fi

if [ "$DRY_RUN" = true ]; then
  log_info "DRY RUN MODE - No changes will be made"
  echo ""
fi

log_info "Setting up ai-coding-rules for Cursor..."
log_verbose "Repo root: $REPO_ROOT"
log_verbose "Script dir: $SCRIPT_DIR"

# Create .cursor directory
if [ "$DRY_RUN" = false ]; then
  mkdir -p "$REPO_ROOT/.cursor"
fi

# ---------------------------------------------------
# Skills: default = one symlink .cursor/skills -> rules/shared/skills (tracks submodule)
#         --copy  = copy each skill dir (legacy)
# ---------------------------------------------------
echo ""
log_info "Syncing Skills..."
CURSOR_SKILLS="$REPO_ROOT/.cursor/skills"
SKILLS_REL_TARGET="rules/shared/skills"

if [ "$USE_SYMLINKS" = true ]; then
  if [ "$DRY_RUN" = true ]; then
    log_info "Would symlink $CURSOR_SKILLS -> $SKILLS_REL_TARGET"
  else
    mkdir -p "$REPO_ROOT/.cursor"
    if [ -e "$CURSOR_SKILLS" ]; then
      if [ -L "$CURSOR_SKILLS" ]; then
        cur=$(readlink "$CURSOR_SKILLS")
        if [ "$cur" = "$SKILLS_REL_TARGET" ]; then
          log_info ".cursor/skills already -> $SKILLS_REL_TARGET"
        elif [ "$FORCE" = true ]; then
          rm -f "$CURSOR_SKILLS"
          ln -sfn "$SKILLS_REL_TARGET" "$CURSOR_SKILLS"
          log_success "Relinked .cursor/skills -> $SKILLS_REL_TARGET"
        else
          log_warn ".cursor/skills is a symlink to $cur (not $SKILLS_REL_TARGET); use --force to replace"
        fi
      elif [ "$FORCE" = true ]; then
        rm -rf "$CURSOR_SKILLS"
        ln -sfn "$SKILLS_REL_TARGET" "$CURSOR_SKILLS"
        log_success "Replaced .cursor/skills with symlink -> $SKILLS_REL_TARGET"
      else
        log_warn ".cursor/skills exists as a directory; use --force to replace with symlink -> $SKILLS_REL_TARGET"
      fi
    else
      ln -sfn "$SKILLS_REL_TARGET" "$CURSOR_SKILLS"
      log_success "Linked .cursor/skills -> $SKILLS_REL_TARGET"
    fi
  fi
else
  mkdir -p "$CURSOR_SKILLS"
  saved_use_symlinks="$USE_SYMLINKS"
  USE_SYMLINKS=false
  for skill_dir in "$SCRIPT_DIR/skills"/*/; do
    if [ -d "$skill_dir" ] && [ -f "$skill_dir/SKILL.md" ]; then
      skill_name=$(basename "$skill_dir")
      smart_link_or_copy "$skill_dir" "$CURSOR_SKILLS/$skill_name" "skill: $skill_name" || true
    fi
  done
  USE_SYMLINKS="$saved_use_symlinks"
  log_info "Skills copied into .cursor/skills/ (--copy)"
fi

# ---------------------------------------------------
# Sync Agents
# ---------------------------------------------------
echo ""
log_info "Syncing Agents..."
mkdir -p "$REPO_ROOT/.cursor/agents"

for agent_file in "$SCRIPT_DIR/agents"/*.md; do
  if [ -f "$agent_file" ]; then
    agent_name=$(basename "$agent_file")
    [ "$agent_name" = "README.md" ] && continue
    smart_link_or_copy "$agent_file" "$REPO_ROOT/.cursor/agents/$agent_name" "agent: $agent_name" || true
  fi
done

# ---------------------------------------------------
# Sync Commands
# ---------------------------------------------------
if [ -d "$SCRIPT_DIR/commands" ]; then
  echo ""
  log_info "Syncing Commands..."
  mkdir -p "$REPO_ROOT/.cursor/commands"

  for cmd_file in "$SCRIPT_DIR/commands"/*.md; do
    if [ -f "$cmd_file" ]; then
      cmd_name=$(basename "$cmd_file")
      [ "$cmd_name" = "README.md" ] && continue
      smart_link_or_copy "$cmd_file" "$REPO_ROOT/.cursor/commands/$cmd_name" "command: $cmd_name" || true
    fi
  done
fi

# ---------------------------------------------------
# Sync Hooks
# ---------------------------------------------------
if [ -d "$SCRIPT_DIR/hooks" ]; then
  echo ""
  log_info "Syncing Hooks..."
  mkdir -p "$REPO_ROOT/.cursor/hooks"

  for hook_file in "$SCRIPT_DIR/hooks"/*; do
    if [ -f "$hook_file" ]; then
      hook_name=$(basename "$hook_file")
      if [ "$hook_name" = "hooks-cursor.json" ]; then
        smart_link_or_copy "$hook_file" "$REPO_ROOT/.cursor/hooks.json" "hooks.json" || true
      elif [ "$hook_name" = "hooks.json" ]; then
        : # Skip Claude Code hooks.json (different format)
      else
        smart_link_or_copy "$hook_file" "$REPO_ROOT/.cursor/hooks/$hook_name" "hook: $hook_name" || true
      fi
    fi
  done
fi

# ---------------------------------------------------
# Setup Memory Storage
# ---------------------------------------------------
echo ""
log_info "Setting up local memory..."
MEMORY_DIR="$REPO_ROOT/.cursor/memory"

if [ "$DRY_RUN" = false ]; then
  mkdir -p "$MEMORY_DIR"

  if [ ! -f "$MEMORY_DIR/active_context.md" ]; then
    cat > "$MEMORY_DIR/active_context.md" <<EOF
# Active Context
## Current Focus
(No active task)

## Recent Decisions
- Setup complete

## Scratchpad
Use this space for temporary notes.
EOF
    log_success "Created memory: .cursor/memory/active_context.md"
  fi

  # Add to .gitignore
  GITIGNORE="$REPO_ROOT/.gitignore"
  if [ -f "$GITIGNORE" ]; then
    if ! grep -q ".cursor/memory/" "$GITIGNORE" 2>/dev/null; then
      echo "" >> "$GITIGNORE"
      echo "# Cursor Memory (Private State)" >> "$GITIGNORE"
      echo ".cursor/memory/" >> "$GITIGNORE"
      log_success "Added .cursor/memory/ to .gitignore"
    fi
  fi
fi

# ---------------------------------------------------
# Summary
# ---------------------------------------------------
echo ""
if [ "$DRY_RUN" = true ]; then
  log_info "DRY RUN COMPLETE - No changes were made"
else
  log_success "Setup complete!"
fi

echo ""
log_info "Summary:"
echo "  Updated: $STATS_UPDATED"
echo "  Skipped: $STATS_SKIPPED"
if [ "$STATS_ERRORS" -gt 0 ]; then
  echo "  Errors: $STATS_ERRORS"
fi

echo ""
log_info "Synced to:"
echo "  Skills:   .cursor/skills/"
echo "  Agents:   .cursor/agents/"
echo "  Commands: .cursor/commands/"
echo "  Hooks:    .cursor/hooks/"
echo "  Memory:   .cursor/memory/"

echo ""
log_info "Next steps:"
echo "  1. Restart Cursor to discover new content"
echo ""
log_info "To update later:"
echo "  git submodule update --remote .cursor/rules/shared"
echo "  bash .cursor/rules/shared/install-cursor.sh"
