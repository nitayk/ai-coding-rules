#!/bin/bash
# Install script for ai-coding-rules (Claude Code)
# Syncs skills, agents, commands, and rules into .claude/
#
# REQUIRED: This repo MUST be at .claude/rules/shared/
# Run from project root or inside .claude/rules/shared/

set -eo pipefail

# Determine locations
if [ -d ".claude/rules/shared" ]; then
  SHARED_DIR=".claude/rules/shared"
  PROJECT_ROOT="."
elif [[ "$(pwd)" == *".claude/rules/shared"* ]]; then
  SHARED_DIR="."
  PROJECT_ROOT="../../.."
elif [[ "$(pwd)" == *"/ai-coding-rules"* ]]; then
  SHARED_DIR="."
  PROJECT_ROOT="."
  echo "Running from ai-coding-rules repo (development mode)"
else
  echo "Error: Could not determine location."
  echo "Run from project root or inside .claude/rules/shared/"
  exit 1
fi

echo "Setting up ai-coding-rules for Claude Code..."
echo "Shared dir: $SHARED_DIR"
echo "Project root: $PROJECT_ROOT"

# Ensure directories exist
mkdir -p "$PROJECT_ROOT/.claude/agents"
mkdir -p "$PROJECT_ROOT/.claude/skills"
mkdir -p "$PROJECT_ROOT/.claude/commands"
mkdir -p "$PROJECT_ROOT/.claude/rules"

# Helper: create symlink if doesn't exist
create_symlink() {
  local target="$1"
  local link_name="$2"

  if [ -e "$link_name" ]; then
    echo "  Skip: $link_name (already exists)"
  else
    ln -s "$target" "$link_name"
    echo "  Link: $link_name -> $target"
  fi
}

# 1. Link Agents
echo ""
echo "Linking Agents..."
for agent in "$SHARED_DIR/agents"/*.md; do
  [ -e "$agent" ] || continue
  filename=$(basename "$agent")
  [ "$filename" = "README.md" ] && continue
  create_symlink "../rules/shared/agents/$filename" "$PROJECT_ROOT/.claude/agents/$filename"
done

# 2. Link Skills
echo ""
echo "Linking Skills..."
for skill in "$SHARED_DIR/skills"/*; do
  [ -d "$skill" ] || continue
  skill_name=$(basename "$skill")
  create_symlink "../rules/shared/skills/$skill_name" "$PROJECT_ROOT/.claude/skills/$skill_name"
done

# 3. Link Commands
echo ""
echo "Linking Commands..."
for command in "$SHARED_DIR/commands"/*.md; do
  [ -e "$command" ] || continue
  filename=$(basename "$command")
  [ "$filename" = "README.md" ] && continue
  create_symlink "../rules/shared/commands/$filename" "$PROJECT_ROOT/.claude/commands/$filename"
done

# 4. Link Rules
echo ""
echo "Linking Rules..."
if [ -L "$PROJECT_ROOT/.claude/rules/shared-rules" ]; then
  echo "  Skip: shared-rules (already linked)"
elif [ -e "$PROJECT_ROOT/.claude/rules/shared-rules" ]; then
  echo "  Error: .claude/rules/shared-rules exists and is not a symlink"
else
  create_symlink "shared/rules" "$PROJECT_ROOT/.claude/rules/shared-rules"
fi

# 5. Setup Memory
echo ""
echo "Setting up memory..."
MEMORY_DIR="$PROJECT_ROOT/.claude/memory"
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
  echo "  Created: .claude/memory/active_context.md"
fi

# Add memory to .gitignore
GITIGNORE="$PROJECT_ROOT/.gitignore"
if [ -f "$GITIGNORE" ]; then
  if ! grep -q ".claude/memory/" "$GITIGNORE" 2>/dev/null; then
    echo "" >> "$GITIGNORE"
    echo "# Claude Memory (Private State)" >> "$GITIGNORE"
    echo ".claude/memory/" >> "$GITIGNORE"
    echo "  Added .claude/memory/ to .gitignore"
  fi
fi

# 6. Create settings.json (only if missing)
echo ""
echo "Checking settings..."
SETTINGS_FILE="$PROJECT_ROOT/.claude/settings.json"
if [ ! -f "$SETTINGS_FILE" ]; then
  cat > "$SETTINGS_FILE" << 'SETTINGS_EOF'
{
  "permissions": {
    "deny": [
      "Read(./.claude/rules/shared/tools/**)",
      "Read(./.claude/rules/shared/docs/**)",
      "Read(./.claude/rules/shared/meta/**)"
    ]
  }
}
SETTINGS_EOF
  echo "  Created: $SETTINGS_FILE"
else
  echo "  Skip: $SETTINGS_FILE (already exists)"
fi

echo ""
echo "Setup complete! Claude Code should now detect all shared skills, agents, and commands."
echo ""
echo "Next steps:"
echo "  1. Start a new Claude Code session"
echo ""
echo "To update later:"
echo "  git submodule update --remote .claude/rules/shared"
echo "  bash .claude/rules/shared/install-claude.sh"
