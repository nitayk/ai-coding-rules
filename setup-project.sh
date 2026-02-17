#!/bin/bash
# One-command setup for a personal project.
#
# Copies skills + rules + agents + commands into .cursor/ of the target project.
# Everything is project-local -- zero conflict with work repos.
#
# Usage:
#   bash ~/ai-coding-rules/setup-project.sh ~/projects/my-app
#   bash ~/ai-coding-rules/setup-project.sh .                  # current dir
#   bash ~/ai-coding-rules/setup-project.sh . --both           # Cursor + Claude
#
# To update a project later, re-run the same command.

set -eo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
SETUP_CURSOR=true
SETUP_CLAUDE=false
PROJECT_DIR=""

GREEN='\033[0;32m'; YELLOW='\033[1;33m'; BLUE='\033[0;34m'; NC='\033[0m'
log_info() { echo -e "${BLUE}[info]${NC} $1"; }
log_ok() { echo -e "${GREEN}[ok]${NC} $1"; }
log_warn() { echo -e "${YELLOW}[warn]${NC} $1"; }

for arg in "$@"; do
  case "$arg" in
    --claude) SETUP_CURSOR=false; SETUP_CLAUDE=true ;;
    --both) SETUP_CURSOR=true; SETUP_CLAUDE=true ;;
    --cursor) SETUP_CURSOR=true; SETUP_CLAUDE=false ;;
    --help|-h)
      echo "Usage: $0 <project-dir> [--cursor|--claude|--both]"
      echo ""
      echo "Sets up ai-coding-rules in a project (copies all files)."
      echo "Default: --cursor"
      echo ""
      echo "What gets installed (project-local):"
      echo "  .cursor/skills/     Skills (copied, Cursor discovers them)"
      echo "  .cursor/rules/      Rules (.mdc files with globs/alwaysApply)"
      echo "  .cursor/agents/     Agents"
      echo "  .cursor/commands/   Commands"
      echo ""
      echo "Examples:"
      echo "  $0 ~/projects/my-app          # Cursor only"
      echo "  $0 ~/projects/my-app --both   # Cursor + Claude"
      echo "  $0 .                           # Current directory"
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

PROJECT_DIR="$(cd "$PROJECT_DIR" 2>/dev/null && pwd)" || {
  echo "Error: Directory does not exist."; exit 1
}

echo ""
echo "=========================================="
echo "  ai-coding-rules: Project Setup"
echo "=========================================="
echo "Source:  $SCRIPT_DIR"
echo "Target:  $PROJECT_DIR"
echo ""

# ─────────────────────────────────────────────────
# Cursor
# ─────────────────────────────────────────────────
if [ "$SETUP_CURSOR" = true ]; then
  CURSOR_DIR="$PROJECT_DIR/.cursor"
  stats=0

  # ── Skills ──
  log_info "Skills -> $CURSOR_DIR/skills/"
  mkdir -p "$CURSOR_DIR/skills"
  for skill_dir in "$SCRIPT_DIR/skills"/*/; do
    [ -d "$skill_dir" ] && [ -f "$skill_dir/SKILL.md" ] || continue
    skill_name=$(basename "$skill_dir")
    rm -rf "$CURSOR_DIR/skills/$skill_name"
    cp -r "$skill_dir" "$CURSOR_DIR/skills/$skill_name"
    log_ok "  $skill_name"
    ((stats+=1))
  done

  # ── Rules ──
  echo ""
  log_info "Rules -> $CURSOR_DIR/rules/"
  mkdir -p "$CURSOR_DIR/rules"

  for file in ROUTER.mdc index.mdc; do
    if [ -f "$SCRIPT_DIR/$file" ]; then
      cp "$SCRIPT_DIR/$file" "$CURSOR_DIR/rules/$file"
      log_ok "  $file"
      ((stats+=1))
    fi
  done

  for dir in generic backend frontend mobile tools meta; do
    if [ -d "$SCRIPT_DIR/$dir" ]; then
      rm -rf "$CURSOR_DIR/rules/$dir"
      cp -r "$SCRIPT_DIR/$dir" "$CURSOR_DIR/rules/$dir"
      count=$(find "$SCRIPT_DIR/$dir" -name "*.mdc" 2>/dev/null | wc -l | tr -d ' ')
      log_ok "  $dir/ ($count rules)"
      ((stats+=1))
    fi
  done

  # ── Agents ──
  echo ""
  log_info "Agents -> $CURSOR_DIR/agents/"
  mkdir -p "$CURSOR_DIR/agents"
  for f in "$SCRIPT_DIR/agents"/*.md; do
    [ -f "$f" ] || continue
    name=$(basename "$f"); [ "$name" = "README.md" ] && continue
    cp "$f" "$CURSOR_DIR/agents/$name"
    log_ok "  $name"; ((stats+=1))
  done

  # ── Commands ──
  echo ""
  log_info "Commands -> $CURSOR_DIR/commands/"
  mkdir -p "$CURSOR_DIR/commands"
  for f in "$SCRIPT_DIR/commands"/*.md; do
    [ -f "$f" ] || continue
    name=$(basename "$f"); [ "$name" = "README.md" ] && continue
    cp "$f" "$CURSOR_DIR/commands/$name"
    log_ok "  $name"; ((stats+=1))
  done

  # ── AGENTS.md ──
  if [ -f "$SCRIPT_DIR/AGENTS.md" ] && [ ! -f "$CURSOR_DIR/../AGENTS.md" ]; then
    cp "$SCRIPT_DIR/AGENTS.md" "$PROJECT_DIR/AGENTS.md"
    log_ok "  AGENTS.md (project root)"
    ((stats+=1))
  fi

  echo ""
  log_ok "Cursor: $stats items installed"
fi

# ─────────────────────────────────────────────────
# Claude Code
# ─────────────────────────────────────────────────
if [ "$SETUP_CLAUDE" = true ]; then
  CLAUDE_DIR="$PROJECT_DIR/.claude"
  stats=0
  echo ""

  # ── Skills ──
  log_info "Skills -> $CLAUDE_DIR/skills/"
  mkdir -p "$CLAUDE_DIR/skills"
  for skill_dir in "$SCRIPT_DIR/skills"/*/; do
    [ -d "$skill_dir" ] && [ -f "$skill_dir/SKILL.md" ] || continue
    skill_name=$(basename "$skill_dir")
    rm -rf "$CLAUDE_DIR/skills/$skill_name"
    cp -r "$skill_dir" "$CLAUDE_DIR/skills/$skill_name"
    log_ok "  $skill_name"
    ((stats+=1))
  done

  # ── Rules (as markdown) ──
  echo ""
  log_info "Rules -> $CLAUDE_DIR/rules/"
  mkdir -p "$CLAUDE_DIR/rules"
  for dir in generic backend frontend mobile tools meta; do
    if [ -d "$SCRIPT_DIR/$dir" ]; then
      rm -rf "$CLAUDE_DIR/rules/$dir"
      cp -r "$SCRIPT_DIR/$dir" "$CLAUDE_DIR/rules/$dir"
      log_ok "  $dir/"
      ((stats+=1))
    fi
  done

  # ── CLAUDE.md ──
  if [ -f "$SCRIPT_DIR/CLAUDE.md" ]; then
    cp "$SCRIPT_DIR/CLAUDE.md" "$PROJECT_DIR/CLAUDE.md"
    log_ok "  CLAUDE.md (project root)"
    ((stats+=1))
  fi

  echo ""
  log_ok "Claude Code: $stats items installed"
fi

# ─────────────────────────────────────────────────
# Done
# ─────────────────────────────────────────────────
echo ""
echo "=========================================="
echo "  Setup complete!"
echo "=========================================="
echo ""
echo "  Restart Cursor / start new Claude session."
echo ""
echo "  To update later:"
echo "    cd ~/ai-coding-rules && git pull && bash update-community.sh"
echo "    bash ~/ai-coding-rules/setup-project.sh $PROJECT_DIR"
echo ""
echo "  Suggested .gitignore additions:"
echo "    .cursor/skills/"
echo "    .cursor/rules/"
echo "    .cursor/agents/"
echo "    .cursor/commands/"
