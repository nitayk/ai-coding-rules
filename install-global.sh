#!/bin/bash
# Install ai-coding-rules globally for ALL Cursor projects.
#
# Installs to:
#   ~/.cursor/skills-cursor/   (global skills - available in every project)
#   ~/.cursor/rules/           (global rules - available in every project)
#   ~/.cursor/agents/          (global agents)
#   ~/.cursor/commands/        (global commands)
#
# Usage:
#   bash install-global.sh
#   bash install-global.sh --dry-run    # Preview what would happen
#   bash install-global.sh --uninstall  # Remove everything installed
#
# After installing, restart Cursor. Every project gets the skills + rules.
# No per-project setup needed!

set -eo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
CURSOR_HOME="$HOME/.cursor"
DRY_RUN=false
UNINSTALL=false

# Colors
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
RED='\033[0;31m'
NC='\033[0m'

# Parse arguments
while [[ $# -gt 0 ]]; do
  case $1 in
    --dry-run) DRY_RUN=true; shift ;;
    --uninstall) UNINSTALL=true; shift ;;
    --help|-h)
      echo "Usage: $0 [OPTIONS]"
      echo ""
      echo "Installs ai-coding-rules globally for all Cursor projects."
      echo ""
      echo "Options:"
      echo "  --dry-run      Preview changes without applying"
      echo "  --uninstall    Remove all installed skills/rules/agents/commands"
      echo "  --help         Show this help"
      echo ""
      echo "Installs to:"
      echo "  ~/.cursor/skills-cursor/   Global skills"
      echo "  ~/.cursor/rules/           Global rules (.mdc files)"
      echo "  ~/.cursor/agents/          Global agents"
      echo "  ~/.cursor/commands/        Global commands"
      exit 0
      ;;
    *) echo "Unknown option: $1"; exit 1 ;;
  esac
done

log_info() { echo -e "${BLUE}[info]${NC} $1"; }
log_ok() { echo -e "${GREEN}[ok]${NC} $1"; }
log_warn() { echo -e "${YELLOW}[warn]${NC} $1"; }
log_rm() { echo -e "${RED}[rm]${NC} $1"; }

STATS_INSTALLED=0
STATS_SKIPPED=0

# ─────────────────────────────────────────────────────────────
# Track what we install (for clean uninstall)
# ─────────────────────────────────────────────────────────────
MANIFEST="$CURSOR_HOME/.ai-coding-rules-manifest"

write_manifest() {
  if [ "$DRY_RUN" = false ]; then
    echo "$1" >> "$MANIFEST"
  fi
}

# ─────────────────────────────────────────────────────────────
# Uninstall
# ─────────────────────────────────────────────────────────────
if [ "$UNINSTALL" = true ]; then
  echo ""
  echo "Uninstalling ai-coding-rules from global Cursor..."
  echo ""

  if [ ! -f "$MANIFEST" ]; then
    log_warn "No manifest found at $MANIFEST"
    log_warn "Nothing to uninstall (or was installed manually)."
    exit 0
  fi

  count=0
  while IFS= read -r item; do
    if [ -e "$item" ]; then
      if [ "$DRY_RUN" = true ]; then
        log_rm "Would remove: $item"
      else
        rm -rf "$item"
        log_rm "Removed: $item"
      fi
      ((count+=1))
    fi
  done < "$MANIFEST"

  if [ "$DRY_RUN" = false ]; then
    rm -f "$MANIFEST"
  fi

  echo ""
  log_ok "Uninstalled $count items. Restart Cursor to apply."
  exit 0
fi

# ─────────────────────────────────────────────────────────────
# Install
# ─────────────────────────────────────────────────────────────
echo ""
echo "=========================================="
echo "  ai-coding-rules: Global Install"
echo "=========================================="
echo ""
echo "Source: $SCRIPT_DIR"
echo "Target: $CURSOR_HOME"
echo ""

if [ "$DRY_RUN" = true ]; then
  log_warn "DRY RUN - no changes will be made"
  echo ""
fi

# Clear manifest for fresh install
if [ "$DRY_RUN" = false ]; then
  rm -f "$MANIFEST"
fi

# ─── Skills (copy to ~/.cursor/skills-cursor/) ───
SKILLS_DIR="$CURSOR_HOME/skills-cursor"
log_info "Installing skills to $SKILLS_DIR/"

if [ "$DRY_RUN" = false ]; then
  mkdir -p "$SKILLS_DIR"
fi

for skill_dir in "$SCRIPT_DIR/skills"/*/; do
  [ -d "$skill_dir" ] || continue
  [ -f "$skill_dir/SKILL.md" ] || continue
  skill_name=$(basename "$skill_dir")
  dest="$SKILLS_DIR/$skill_name"

  if [ "$DRY_RUN" = true ]; then
    log_ok "  Would install skill: $skill_name"
  else
    rm -rf "$dest"
    cp -r "$skill_dir" "$dest"
    write_manifest "$dest"
    log_ok "  $skill_name"
  fi
  ((STATS_INSTALLED+=1))
done

# ─── Rules (copy .mdc files to ~/.cursor/rules/) ───
RULES_DIR="$CURSOR_HOME/rules"
echo ""
log_info "Installing rules to $RULES_DIR/"

if [ "$DRY_RUN" = false ]; then
  mkdir -p "$RULES_DIR"
fi

# Copy the router and index
for file in ROUTER.mdc index.mdc; do
  if [ -f "$SCRIPT_DIR/$file" ]; then
    dest="$RULES_DIR/$file"
    if [ "$DRY_RUN" = false ]; then
      cp "$SCRIPT_DIR/$file" "$dest"
      write_manifest "$dest"
    fi
    log_ok "  $file"
    ((STATS_INSTALLED+=1))
  fi
done

# Copy rule directories
for dir in generic backend frontend mobile tools meta; do
  if [ -d "$SCRIPT_DIR/$dir" ]; then
    dest="$RULES_DIR/$dir"
    if [ "$DRY_RUN" = false ]; then
      rm -rf "$dest"
      cp -r "$SCRIPT_DIR/$dir" "$dest"
      write_manifest "$dest"
    fi
    file_count=$(find "$SCRIPT_DIR/$dir" -name "*.mdc" 2>/dev/null | wc -l | tr -d ' ')
    log_ok "  $dir/ ($file_count rules)"
    ((STATS_INSTALLED+=1))
  fi
done

# ─── Agents (copy to ~/.cursor/agents/) ───
AGENTS_DIR="$CURSOR_HOME/agents"
echo ""
log_info "Installing agents to $AGENTS_DIR/"

if [ "$DRY_RUN" = false ]; then
  mkdir -p "$AGENTS_DIR"
fi

for agent_file in "$SCRIPT_DIR/agents"/*.md; do
  [ -f "$agent_file" ] || continue
  agent_name=$(basename "$agent_file")
  [ "$agent_name" = "README.md" ] && continue
  dest="$AGENTS_DIR/$agent_name"

  if [ "$DRY_RUN" = false ]; then
    cp "$agent_file" "$dest"
    write_manifest "$dest"
  fi
  log_ok "  $agent_name"
  ((STATS_INSTALLED+=1))
done

# ─── Commands (copy to ~/.cursor/commands/) ───
COMMANDS_DIR="$CURSOR_HOME/commands"
echo ""
log_info "Installing commands to $COMMANDS_DIR/"

if [ "$DRY_RUN" = false ]; then
  mkdir -p "$COMMANDS_DIR"
fi

for cmd_file in "$SCRIPT_DIR/commands"/*.md; do
  [ -f "$cmd_file" ] || continue
  cmd_name=$(basename "$cmd_file")
  [ "$cmd_name" = "README.md" ] && continue
  dest="$COMMANDS_DIR/$cmd_name"

  if [ "$DRY_RUN" = false ]; then
    cp "$cmd_file" "$dest"
    write_manifest "$dest"
  fi
  log_ok "  $cmd_name"
  ((STATS_INSTALLED+=1))
done

# ─── Summary ───
echo ""
echo "=========================================="
echo "  Summary"
echo "=========================================="
echo "  Installed: $STATS_INSTALLED items"
echo ""
echo "  Skills:   $SKILLS_DIR/"
echo "  Rules:    $RULES_DIR/"
echo "  Agents:   $AGENTS_DIR/"
echo "  Commands: $COMMANDS_DIR/"
echo ""

if [ "$DRY_RUN" = true ]; then
  log_warn "Dry run complete. Run without --dry-run to install."
else
  log_ok "Global install complete!"
  echo ""
  echo "  Restart Cursor. Every project now has access to:"
  echo "    - 34 skills (type / to see commands)"
  echo "    - 200+ language rules (auto-loaded by file type)"
  echo "    - 1 agent (code-reviewer)"
  echo "    - 3 commands (brainstorm, execute-plan, write-plan)"
  echo ""
  echo "  To update later:"
  echo "    cd $SCRIPT_DIR"
  echo "    git pull && bash update-community.sh"
  echo "    bash install-global.sh"
  echo ""
  echo "  To uninstall:"
  echo "    bash install-global.sh --uninstall"
fi
