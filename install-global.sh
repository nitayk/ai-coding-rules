#!/bin/bash
# Install ai-coding-rules globally for ALL Cursor projects.
#
# WARNING: If you also use company repos that have their own .cursor/skills/,
# global skills will appear alongside project skills (possible duplicates).
# Use --skills-only or setup-project.sh if you need clean separation.
#
# What gets installed:
#   ~/.cursor/skills/     Global skills (officially supported by Cursor)
#   ~/.cursor/agents/     Global agents
#   ~/.cursor/commands/   Global commands
#
# What CANNOT be installed globally:
#   Rules (.mdc files) - Cursor only supports user rules via Settings UI,
#   not filesystem. Use setup-project.sh for per-project rules.
#
# Usage:
#   bash install-global.sh              # Install skills + agents + commands
#   bash install-global.sh --dry-run    # Preview what would happen
#   bash install-global.sh --uninstall  # Remove everything we installed

set -eo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
CURSOR_HOME="$HOME/.cursor"
DRY_RUN=false
UNINSTALL=false

GREEN='\033[0;32m'; YELLOW='\033[1;33m'; BLUE='\033[0;34m'; RED='\033[0;31m'; NC='\033[0m'

while [[ $# -gt 0 ]]; do
  case $1 in
    --dry-run) DRY_RUN=true; shift ;;
    --uninstall) UNINSTALL=true; shift ;;
    --help|-h)
      echo "Usage: $0 [OPTIONS]"
      echo ""
      echo "Installs skills, agents, and commands globally."
      echo ""
      echo "  --dry-run      Preview changes"
      echo "  --uninstall    Remove installed items"
      echo ""
      echo "Installs to:"
      echo "  ~/.cursor/skills/     Global skills (per Cursor docs)"
      echo "  ~/.cursor/agents/     Global agents"
      echo "  ~/.cursor/commands/   Global commands"
      echo ""
      echo "Note: Rules need per-project setup (use setup-project.sh)"
      exit 0
      ;;
    *) echo "Unknown: $1"; exit 1 ;;
  esac
done

log_info() { echo -e "${BLUE}[info]${NC} $1"; }
log_ok() { echo -e "${GREEN}[ok]${NC} $1"; }
log_warn() { echo -e "${YELLOW}[warn]${NC} $1"; }
log_rm() { echo -e "${RED}[rm]${NC} $1"; }

MANIFEST="$CURSOR_HOME/.ai-coding-rules-manifest"

write_manifest() { [ "$DRY_RUN" = false ] && echo "$1" >> "$MANIFEST"; }

# ── Uninstall ──
if [ "$UNINSTALL" = true ]; then
  echo ""; echo "Uninstalling ai-coding-rules from global Cursor..."; echo ""
  if [ ! -f "$MANIFEST" ]; then
    log_warn "No manifest found. Nothing to uninstall."; exit 0
  fi
  count=0
  while IFS= read -r item; do
    if [ -e "$item" ]; then
      [ "$DRY_RUN" = true ] && log_rm "Would remove: $item" || { rm -rf "$item"; log_rm "Removed: $item"; }
      ((count+=1))
    fi
  done < "$MANIFEST"
  [ "$DRY_RUN" = false ] && rm -f "$MANIFEST"
  echo ""; log_ok "Uninstalled $count items. Restart Cursor."; exit 0
fi

# ── Install ──
echo ""
echo "=========================================="
echo "  ai-coding-rules: Global Install"
echo "=========================================="
echo "Source: $SCRIPT_DIR"
echo "Target: $CURSOR_HOME"
echo ""
[ "$DRY_RUN" = true ] && { log_warn "DRY RUN"; echo ""; }
[ "$DRY_RUN" = false ] && rm -f "$MANIFEST"

STATS=0

# ── Skills -> ~/.cursor/skills/ ──
SKILLS_DIR="$CURSOR_HOME/skills"
log_info "Skills -> $SKILLS_DIR/"
[ "$DRY_RUN" = false ] && mkdir -p "$SKILLS_DIR"

for skill_dir in "$SCRIPT_DIR/skills"/*/; do
  [ -d "$skill_dir" ] && [ -f "$skill_dir/SKILL.md" ] || continue
  skill_name=$(basename "$skill_dir")
  dest="$SKILLS_DIR/$skill_name"
  if [ "$DRY_RUN" = true ]; then
    log_ok "  $skill_name"
  else
    rm -rf "$dest"; cp -r "$skill_dir" "$dest"; write_manifest "$dest"
    log_ok "  $skill_name"
  fi
  ((STATS+=1))
done

# ── Agents -> ~/.cursor/agents/ ──
echo ""
log_info "Agents -> $CURSOR_HOME/agents/"
[ "$DRY_RUN" = false ] && mkdir -p "$CURSOR_HOME/agents"
for f in "$SCRIPT_DIR/agents"/*.md; do
  [ -f "$f" ] || continue
  name=$(basename "$f"); [ "$name" = "README.md" ] && continue
  dest="$CURSOR_HOME/agents/$name"
  [ "$DRY_RUN" = false ] && { cp "$f" "$dest"; write_manifest "$dest"; }
  log_ok "  $name"; ((STATS+=1))
done

# ── Commands -> ~/.cursor/commands/ ──
echo ""
log_info "Commands -> $CURSOR_HOME/commands/"
[ "$DRY_RUN" = false ] && mkdir -p "$CURSOR_HOME/commands"
for f in "$SCRIPT_DIR/commands"/*.md; do
  [ -f "$f" ] || continue
  name=$(basename "$f"); [ "$name" = "README.md" ] && continue
  dest="$CURSOR_HOME/commands/$name"
  [ "$DRY_RUN" = false ] && { cp "$f" "$dest"; write_manifest "$dest"; }
  log_ok "  $name"; ((STATS+=1))
done

# ── Summary ──
echo ""
echo "=========================================="
echo "  Installed $STATS items"
echo "=========================================="
if [ "$DRY_RUN" = true ]; then
  log_warn "Dry run. Run without --dry-run to install."
else
  log_ok "Done! Restart Cursor."
  echo ""
  echo -e "  ${YELLOW}Rules (.mdc) not installed globally -- Cursor doesn't support it.${NC}"
  echo "  For per-project rules: bash $SCRIPT_DIR/setup-project.sh <path>"
  echo ""
  echo "  Update:    cd $SCRIPT_DIR && git pull && bash update-community.sh && bash install-global.sh"
  echo "  Uninstall: bash install-global.sh --uninstall"
fi
