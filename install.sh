#!/bin/bash
# Unified installer for ai-coding-rules
# Handles submodule setup, syncing, and migration to symlinks automatically.
#
# Usage: bash install.sh [OPTIONS]
#
# Options:
#   --profile      generic (default — the only profile; kept for future extensibility)
#   --target       cursor|claude|comma-separated (default: cursor)
#   --symlinks     Use symlinks (default - faster)
#   --copy         Use file copying instead
#   --dry-run      Show what would be done
#   --verbose      Show detailed output
#   --help         Show help message

set -eo pipefail

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

# Configuration
TARGET="cursor"
SKILLS_FILTER="defaults"
NO_SKILLS_FILTER=""
PROFILE=""
USE_SYMLINKS=true
DRY_RUN=false
VERBOSE=false

# Parse arguments
while [[ $# -gt 0 ]]; do
  case $1 in
    --copy)
      USE_SYMLINKS=false
      shift
      ;;
    --symlinks)
      USE_SYMLINKS=true
      shift
      ;;
    --dry-run)
      DRY_RUN=true
      shift
      ;;
    --verbose|-v)
      VERBOSE=true
      shift
      ;;
    --force|-f)
      # No-op: install always runs sync with --force (kept for backward compatibility)
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
    --profile)
      if [[ -z "${2:-}" ]] || [[ "$2" == --* ]]; then
        echo "Error: --profile only supports: generic"
        exit 1
      fi
      PROFILE="$2"
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
      echo "Complete setup script for ai-coding-rules."
      echo "Handles submodule setup, syncing, and migration automatically."
      echo ""
      echo "Options:"
      echo "  --profile      Only 'generic' is supported (default)"
      echo "  --target       cursor|claude|comma-separated (default: cursor)"
      echo "  --skills       Comma-separated skill groups to sync (e.g. core,git,testing) or 'all'"
      echo "  --no-skills    Comma-separated skill groups to exclude (e.g. scala,office)"
      echo "  --copy         Use file copying instead of symlinks (fallback)"
      echo "  --symlinks     Use symlinks (default - faster, automatic updates)"
      echo "  --dry-run      Show what would be done without making changes"
      echo "  --verbose      Show detailed output"
      echo "  --help         Show this help message"
      echo ""
      echo "Note: Submodule always lives at .cursor/rules/shared (never under .claude/rules/ to avoid"
      echo "      Claude Code context explosion). sync-rules.sh handles copying skills/agents/commands"
      echo "      to the correct .claude/ paths; the submodule itself stays out of Claude's auto-load."
      echo ""
      echo "Examples:"
      echo "  bash install.sh                        # Generic profile, Cursor (default)"
      echo "  bash install.sh --target claude        # Claude Code–oriented paths"
      echo "  bash install.sh --target cursor,claude # Both targets"
      echo "  bash install.sh --skills core,git      # Only core + git skills"
      echo "  bash install.sh --no-skills scala      # All skills except Scala"
      echo "  bash install.sh --dry-run              # Preview changes"
      exit 0
      ;;
    *)
      echo "Unknown option: $1"
      echo "Use --help for usage information"
      exit 1
      ;;
  esac
done

# Validate profile if given
if [ -n "$PROFILE" ] && [ "$PROFILE" != "generic" ]; then
  echo "Error: Unknown profile '$PROFILE'. Only 'generic' is supported."
  exit 1
fi

log_info() {
  echo -e "${BLUE}ℹ${NC} $1"
}

log_success() {
  echo -e "${GREEN}✓${NC} $1"
}

log_warn() {
  echo -e "${YELLOW}⚠${NC} $1"
}

log_error() {
  echo -e "${RED}✗${NC} $1" >&2
}

# Detect repo root (where .git exists)
detect_repo_root() {
  local current_dir="$PWD"
  while [ "$current_dir" != "/" ]; do
    if [ -d "$current_dir/.git" ]; then
      echo "$current_dir"
      return 0
    fi
    current_dir=$(dirname "$current_dir")
  done
  return 1
}

# Main execution
REPO_ROOT=$(detect_repo_root)

if [ -z "$REPO_ROOT" ]; then
  log_error "Not in a git repository. Please run this from your project root."
  exit 1
fi

log_info "Detected repository root: $REPO_ROOT"
cd "$REPO_ROOT"

# Submodule always lives at .cursor/rules/shared — NEVER under .claude/rules/.
# Claude Code auto-loads ALL .md files under .claude/rules/ as context, so placing
# the entire ai-coding-rules repo there causes a context explosion (~500 files, 2+ MB).
# sync-rules.sh handles copying skills/agents/commands/hooks to the correct
# .claude/ paths; the submodule itself stays out of Claude's auto-load directory.
SUBMODULE_PATH=".cursor/rules/shared"
SETUP_SCRIPT="$SUBMODULE_PATH/sync-rules.sh"

if [ "$DRY_RUN" = true ]; then
  log_info "DRY RUN MODE - No changes will be made"
  echo ""
fi

# Step 0: Migrate legacy .claude/rules/shared submodule (context-explosion fix)
LEGACY_CLAUDE_SUBMODULE=".claude/rules/shared"
if [ -d "$LEGACY_CLAUDE_SUBMODULE" ] && [ -f "$LEGACY_CLAUDE_SUBMODULE/.git" ]; then
  log_warn "Found submodule at $LEGACY_CLAUDE_SUBMODULE (causes Claude Code context explosion)"
  log_info "Migrating to $SUBMODULE_PATH..."
  if [ "$DRY_RUN" = false ]; then
    git submodule deinit -f "$LEGACY_CLAUDE_SUBMODULE" 2>/dev/null || true
    git rm -f "$LEGACY_CLAUDE_SUBMODULE" 2>/dev/null || true
    rm -rf ".git/modules/$LEGACY_CLAUDE_SUBMODULE" 2>/dev/null || true
    rm -rf "$LEGACY_CLAUDE_SUBMODULE" 2>/dev/null || true
    if [ -d ".claude/rules" ] && [ -z "$(ls -A .claude/rules 2>/dev/null)" ]; then
      rmdir ".claude/rules" 2>/dev/null || true
    fi
    log_success "Removed legacy submodule at $LEGACY_CLAUDE_SUBMODULE"
  else
    log_info "Would remove legacy submodule at $LEGACY_CLAUDE_SUBMODULE"
  fi
fi

# Step 1: Check if submodule exists
log_info "Step 1: Checking submodule..."

# Detect if we're running from within ai-coding-rules itself
SCRIPT_REAL=$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)
RUNNING_FROM_REPO=false
if [ -f "$SCRIPT_REAL/sync-rules.sh" ] && [ -d "$SCRIPT_REAL/skills" ]; then
  RUNNING_FROM_REPO=true
fi

if [ ! -d "$SUBMODULE_PATH" ] || [ ! -f "$SUBMODULE_PATH/.git" ]; then
  log_warn "Submodule not found at $SUBMODULE_PATH"

  SSH_URL="git@github.com:nitayk/ai-coding-rules.git"
  HTTPS_URL="https://github.com/nitayk/ai-coding-rules.git"
  REMOTE_URL=$(git remote get-url origin 2>/dev/null || echo "")
  if [[ "$REMOTE_URL" == *"git@"* ]]; then
    SUBMODULE_URL="$SSH_URL"
  else
    SUBMODULE_URL="$HTTPS_URL"
  fi

  if [ "$DRY_RUN" = false ]; then
    # If running from the ai-coding-rules repo itself, run sync-rules.sh directly
    if [ "$RUNNING_FROM_REPO" = true ]; then
      log_info "Running from ai-coding-rules repo itself — using sync-rules.sh directly..."
      SYNC_ARGS=(--target "$TARGET" --force)
      [ "$DRY_RUN" = true ] && SYNC_ARGS+=(--dry-run)
      [ "$VERBOSE" = true ] && SYNC_ARGS+=(--verbose)
      [ "$USE_SYMLINKS" = false ] && SYNC_ARGS+=(--copy)
      [ "$SKILLS_FILTER" != "defaults" ] && SYNC_ARGS+=(--skills "$SKILLS_FILTER")
      [ -n "$NO_SKILLS_FILTER" ] && SYNC_ARGS+=(--no-skills "$NO_SKILLS_FILTER")
      bash "$SCRIPT_REAL/sync-rules.sh" "${SYNC_ARGS[@]}"
      exit $?
    fi

    log_info "Adding submodule..."
    mkdir -p "$(dirname "$SUBMODULE_PATH")"

    SUBMODULE_ADDED=false
    if git submodule add "$SUBMODULE_URL" "$SUBMODULE_PATH" 2>/dev/null; then
      SUBMODULE_ADDED=true
    elif [[ "$SUBMODULE_URL" == "$SSH_URL" ]]; then
      log_warn "SSH clone failed, retrying with HTTPS..."
      SUBMODULE_URL="$HTTPS_URL"
      if git submodule add "$SUBMODULE_URL" "$SUBMODULE_PATH" 2>/dev/null; then
        SUBMODULE_ADDED=true
      fi
    fi

    if [ "$SUBMODULE_ADDED" = false ]; then
      log_error "Failed to add submodule. You may need to add it manually:"
      log_error "  git submodule add $HTTPS_URL $SUBMODULE_PATH"
      exit 1
    fi
    log_success "Submodule added"
  else
    if [ "$RUNNING_FROM_REPO" = true ]; then
      log_info "Running from ai-coding-rules repo itself — would run sync-rules.sh directly"
      SYNC_ARGS=(--target "$TARGET" --force --dry-run)
      [ "$VERBOSE" = true ] && SYNC_ARGS+=(--verbose)
      [ "$USE_SYMLINKS" = false ] && SYNC_ARGS+=(--copy)
      [ "$SKILLS_FILTER" != "defaults" ] && SYNC_ARGS+=(--skills "$SKILLS_FILTER")
      [ -n "$NO_SKILLS_FILTER" ] && SYNC_ARGS+=(--no-skills "$NO_SKILLS_FILTER")
      bash "$SCRIPT_REAL/sync-rules.sh" "${SYNC_ARGS[@]}"
      exit 0
    else
      log_info "Would add submodule: $SUBMODULE_URL → $SUBMODULE_PATH"
    fi
  fi
else
  log_success "Submodule exists"
fi

# Step 2: Update submodule
log_info ""
log_info "Step 2: Updating submodule..."

if [ "$DRY_RUN" = false ]; then
  try_fix_submodule_url() {
    local current_url
    current_url=$(git config --file .gitmodules submodule."$SUBMODULE_PATH".url 2>/dev/null || echo "")
    if [[ "$current_url" == git@github.com:* ]]; then
      local https_url
      https_url=$(echo "$current_url" | sed 's|git@github.com:|https://github.com/|')
      log_warn "SSH access failed. Switching submodule URL to HTTPS..."
      git config --file .gitmodules submodule."$SUBMODULE_PATH".url "$https_url"
      git config submodule."$SUBMODULE_PATH".url "$https_url"
      return 0
    fi
    return 1
  }

  if [ ! -f "$SUBMODULE_PATH/.git" ] && [ ! -d "$SUBMODULE_PATH/.git" ]; then
    log_info "Initializing submodule..."
    if ! git submodule update --init --recursive "$SUBMODULE_PATH" 2>/dev/null; then
      if try_fix_submodule_url; then
        git submodule update --init --recursive "$SUBMODULE_PATH" || {
          log_error "Failed to initialize submodule (tried both SSH and HTTPS)"
          exit 1
        }
      else
        log_error "Failed to initialize submodule"
        exit 1
      fi
    fi
  fi

  submodule_path_is_git() {
    [ -f "$1/.git" ] || [ -d "$1/.git" ]
  }

  reset_submodule_tracked() {
    local path="$1"
    submodule_path_is_git "$path" || return 0
    if [ -n "$(git -C "$path" status --porcelain 2>/dev/null)" ]; then
      log_warn "Submodule $path has local changes; discarding tracked edits (git reset --hard)"
      git -C "$path" reset --hard -q HEAD 2>/dev/null || true
    fi
  }

  reset_submodule_tracked_and_untracked() {
    local path="$1"
    submodule_path_is_git "$path" || return 0
    log_warn "Submodule $path: removing untracked files (git clean -fd)"
    git -C "$path" reset --hard -q HEAD 2>/dev/null || true
    git -C "$path" clean -fdq 2>/dev/null || true
  }

  log_info "Updating submodule to latest..."
  reset_submodule_tracked "$SUBMODULE_PATH"
  if ! git submodule update --remote "$SUBMODULE_PATH" 2>/dev/null; then
    if try_fix_submodule_url; then
      reset_submodule_tracked "$SUBMODULE_PATH"
      if ! git submodule update --remote "$SUBMODULE_PATH" 2>/dev/null; then
        reset_submodule_tracked_and_untracked "$SUBMODULE_PATH"
        git submodule update --remote "$SUBMODULE_PATH" || {
          log_warn "Failed to update submodule (may be pinned to a specific commit)"
          log_info "Continuing with current submodule state..."
        }
      fi
    else
      reset_submodule_tracked_and_untracked "$SUBMODULE_PATH"
      if ! git submodule update --remote "$SUBMODULE_PATH" 2>/dev/null; then
        log_warn "Failed to update submodule (may be on a specific commit)"
        log_info "Continuing with current submodule state..."
      fi
    fi
  fi
  log_success "Submodule updated"
else
  log_info "Would update submodule: git submodule update --remote $SUBMODULE_PATH"
fi

# Step 3: Run sync script
log_info ""
log_info "Step 3: Running sync script..."

if [ ! -f "$SETUP_SCRIPT" ]; then
  if [ "$DRY_RUN" = true ]; then
    log_info "Would run: bash $SETUP_SCRIPT --target $TARGET (after submodule is added)"
  else
    log_error "Sync script not found: $SETUP_SCRIPT"
    log_error "Submodule may not be initialized correctly"
    exit 1
  fi
else

SETUP_ARGS=()
[ "$DRY_RUN" = true ] && SETUP_ARGS+=(--dry-run)
[ "$VERBOSE" = true ] && SETUP_ARGS+=(--verbose)
[ "$USE_SYMLINKS" = false ] && SETUP_ARGS+=(--copy)
SETUP_ARGS+=(--force)
SETUP_ARGS+=(--target "$TARGET")
[ "$SKILLS_FILTER" != "defaults" ] && SETUP_ARGS+=(--skills "$SKILLS_FILTER")
[ -n "$NO_SKILLS_FILTER" ] && SETUP_ARGS+=(--no-skills "$NO_SKILLS_FILTER")

if [ "$DRY_RUN" = false ]; then
  bash "$SETUP_SCRIPT" "${SETUP_ARGS[@]}" || {
    log_error "Sync script failed"
    exit 1
  }
else
  log_info "Would run: bash $SETUP_SCRIPT ${SETUP_ARGS[*]}"
fi
fi

# Step 4: Install post-merge hook (runs sync after git pull)
log_info ""
log_info "Step 4: Installing post-merge hook..."

GIT_COMMON_DIR=$(cd "$REPO_ROOT" && git rev-parse --git-common-dir 2>/dev/null || echo ".git")
[[ "$GIT_COMMON_DIR" == /* ]] && HOOKS_DIR="$GIT_COMMON_DIR/hooks" || HOOKS_DIR="$REPO_ROOT/$GIT_COMMON_DIR/hooks"
POST_MERGE="$HOOKS_DIR/post-merge"

HOOK_SYNC_ARGS="--force --target \"$TARGET\""
[ "$SKILLS_FILTER" != "defaults" ] && HOOK_SYNC_ARGS="$HOOK_SYNC_ARGS --skills \"$SKILLS_FILTER\""
[ -n "$NO_SKILLS_FILTER" ] && HOOK_SYNC_ARGS="$HOOK_SYNC_ARGS --no-skills \"$NO_SKILLS_FILTER\""

if [ "$DRY_RUN" = false ]; then
  mkdir -p "$HOOKS_DIR"
  if [ -f "$POST_MERGE" ]; then
    if grep -q "ai-coding-rules: sync after pull" "$POST_MERGE" 2>/dev/null; then
      log_success "Post-merge hook already installed"
    else
      cat >> "$POST_MERGE" << HOOK_BLOCK

# --- ai-coding-rules: sync after pull (only when submodule changed) ---
cd "\$(git rev-parse --show-toplevel)" 2>/dev/null || exit 0
if [ -f "$SUBMODULE_PATH/sync-rules.sh" ] && \\
   ! git diff --quiet HEAD^1 HEAD -- "$SUBMODULE_PATH" 2>/dev/null; then
  if [ -d "$SUBMODULE_PATH" ]; then
    git -C "$SUBMODULE_PATH" reset --hard -q HEAD 2>/dev/null || true
  fi
  if ! git submodule update --init "$SUBMODULE_PATH" 2>/dev/null; then
    git -C "$SUBMODULE_PATH" clean -fdq 2>/dev/null || true
    git submodule update --init "$SUBMODULE_PATH" 2>/dev/null || true
  fi
  bash "$SUBMODULE_PATH/sync-rules.sh" $HOOK_SYNC_ARGS 2>/dev/null || true
fi
HOOK_BLOCK
      chmod +x "$POST_MERGE"
      log_success "Appended sync to existing post-merge hook"
    fi
  else
    cat > "$POST_MERGE" << HOOK_EOF
#!/usr/bin/env bash
# Post-merge hook: sync ai-coding-rules when submodule reference changes
# Installed by $SUBMODULE_PATH/install.sh

cd "\$(git rev-parse --show-toplevel)" || exit 0
# --- ai-coding-rules: sync after pull (only when submodule changed) ---
if [ -f "$SUBMODULE_PATH/sync-rules.sh" ] && \\
   ! git diff --quiet HEAD^1 HEAD -- "$SUBMODULE_PATH" 2>/dev/null; then
  if [ -d "$SUBMODULE_PATH" ]; then
    git -C "$SUBMODULE_PATH" reset --hard -q HEAD 2>/dev/null || true
  fi
  if ! git submodule update --init "$SUBMODULE_PATH" 2>/dev/null; then
    git -C "$SUBMODULE_PATH" clean -fdq 2>/dev/null || true
    git submodule update --init "$SUBMODULE_PATH" 2>/dev/null || true
  fi
  bash "$SUBMODULE_PATH/sync-rules.sh" $HOOK_SYNC_ARGS 2>/dev/null || true
fi
HOOK_EOF
    chmod +x "$POST_MERGE"
    log_success "Post-merge hook installed"
  fi
else
  log_info "Would install post-merge hook to run sync after git pull"
fi

# Summary
log_info ""
log_success "Setup complete!"
echo ""
log_info "What was done:"
echo "  1. ✓ Submodule checked/added at $SUBMODULE_PATH"
echo "  2. ✓ Submodule updated to latest"
echo "  3. ✓ Files synced (target: $TARGET, --force)"
echo "  4. ✓ Post-merge hook installed (runs sync after git pull)"
if [ "$USE_SYMLINKS" = true ]; then
  echo "     → Using symlinks (automatic updates)"
else
  echo "     → Using file copying"
fi
echo ""
log_info "To update later:"
echo "  bash $SUBMODULE_PATH/install.sh"
echo ""
log_info "ℹ️  Post-merge hook: sync runs automatically after git pull"
