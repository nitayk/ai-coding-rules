#!/bin/bash
# Link ai-coding-rules into a project directory.
#
# Instead of git submodules, this creates a symlink from your project's
# .cursor/rules/shared (or .claude/rules/shared) to this repo.
# One clone, many projects. Update once, all projects benefit.
#
# Usage:
#   bash ~/ai-coding-rules/link-to-project.sh /path/to/my-project
#   bash ~/ai-coding-rules/link-to-project.sh .                    # current dir
#   bash ~/ai-coding-rules/link-to-project.sh /path/to/project --claude  # Claude Code too
#   bash ~/ai-coding-rules/link-to-project.sh /path/to/project --both    # Cursor + Claude
#
# After linking, run the install script to sync skills/agents/commands:
#   bash .cursor/rules/shared/install-cursor.sh

set -eo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
SETUP_CURSOR=true
SETUP_CLAUDE=false

# Parse arguments
PROJECT_DIR=""
for arg in "$@"; do
  case "$arg" in
    --claude) SETUP_CURSOR=false; SETUP_CLAUDE=true ;;
    --both) SETUP_CURSOR=true; SETUP_CLAUDE=true ;;
    --cursor) SETUP_CURSOR=true; SETUP_CLAUDE=false ;;
    --help|-h)
      echo "Usage: $0 <project-dir> [--cursor|--claude|--both]"
      echo ""
      echo "Links ai-coding-rules into a project via symlink."
      echo "Default: --cursor"
      echo ""
      echo "Examples:"
      echo "  $0 ~/projects/my-app              # Cursor only"
      echo "  $0 ~/projects/my-app --both        # Cursor + Claude Code"
      echo "  $0 .                               # Current directory"
      echo ""
      echo "After linking:"
      echo "  cd <project>"
      echo "  bash .cursor/rules/shared/install-cursor.sh"
      echo "  # or: bash .claude/rules/shared/install-claude.sh"
      exit 0
      ;;
    *) PROJECT_DIR="$arg" ;;
  esac
done

if [ -z "$PROJECT_DIR" ]; then
  echo "Error: Please provide a project directory."
  echo "Usage: $0 <project-dir> [--cursor|--claude|--both]"
  exit 1
fi

# Resolve to absolute path
PROJECT_DIR="$(cd "$PROJECT_DIR" 2>/dev/null && pwd)" || {
  echo "Error: Directory '$1' does not exist."
  exit 1
}

echo "Linking ai-coding-rules into: $PROJECT_DIR"
echo "Source: $SCRIPT_DIR"
echo ""

# --- Cursor ---
if [ "$SETUP_CURSOR" = true ]; then
  CURSOR_TARGET="$PROJECT_DIR/.cursor/rules/shared"

  if [ -L "$CURSOR_TARGET" ]; then
    echo "[skip] .cursor/rules/shared already linked -> $(readlink "$CURSOR_TARGET")"
  elif [ -d "$CURSOR_TARGET" ]; then
    echo "[warn] .cursor/rules/shared exists as a directory (not a symlink)."
    echo "       Remove it first if you want to link: rm -rf $CURSOR_TARGET"
  else
    mkdir -p "$PROJECT_DIR/.cursor/rules"
    ln -s "$SCRIPT_DIR" "$CURSOR_TARGET"
    echo "[ok] Linked .cursor/rules/shared -> $SCRIPT_DIR"
  fi

  echo ""
  echo "Next: cd $PROJECT_DIR && bash .cursor/rules/shared/install-cursor.sh"
fi

# --- Claude Code ---
if [ "$SETUP_CLAUDE" = true ]; then
  CLAUDE_TARGET="$PROJECT_DIR/.claude/rules/shared"

  if [ -L "$CLAUDE_TARGET" ]; then
    echo "[skip] .claude/rules/shared already linked -> $(readlink "$CLAUDE_TARGET")"
  elif [ -d "$CLAUDE_TARGET" ]; then
    echo "[warn] .claude/rules/shared exists as a directory (not a symlink)."
    echo "       Remove it first if you want to link: rm -rf $CLAUDE_TARGET"
  else
    mkdir -p "$PROJECT_DIR/.claude/rules"
    ln -s "$SCRIPT_DIR" "$CLAUDE_TARGET"
    echo "[ok] Linked .claude/rules/shared -> $SCRIPT_DIR"
  fi

  echo ""
  echo "Next: cd $PROJECT_DIR && bash .claude/rules/shared/install-claude.sh"
fi

echo ""
echo "Done! Remember to add to .gitignore if needed:"
echo "  .cursor/rules/shared  # symlink to global ai-coding-rules"
echo "  .claude/rules/shared  # symlink to global ai-coding-rules"
