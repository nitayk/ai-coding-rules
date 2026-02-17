#!/usr/bin/env bash
# Local validation for ai-coding-rules
# Run manually or via pre-commit hook
#
# Usage:
#   ./scripts/validate.sh          # Full validation
#   ./scripts/validate.sh --quick  # YAML only (no agnix)

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_DIR="$(dirname "$SCRIPT_DIR")"
QUICK="${1:-}"
ERRORS=0

red() { printf "\033[31m%s\033[0m\n" "$1"; }
green() { printf "\033[32m%s\033[0m\n" "$1"; }
yellow() { printf "\033[33m%s\033[0m\n" "$1"; }

echo "Validating ai-coding-rules..."
echo ""

# --- 1. YAML Frontmatter Validation ---
echo "--- YAML Frontmatter ---"
if [ -x "$REPO_DIR/hooks/validate-yaml.py" ]; then
  if (cd "$REPO_DIR" && python3 hooks/validate-yaml.py) 2>/dev/null; then
    green "  PASS: YAML frontmatter valid"
  else
    red "  FAIL: YAML frontmatter errors found"
    ERRORS=$((ERRORS + 1))
  fi
else
  yellow "  SKIP: validate-yaml.py not found"
fi

# --- 2. agnix Linting (skip in --quick mode) ---
if [ "$QUICK" != "--quick" ]; then
  echo ""
  echo "--- agnix Config Linting ---"
  if command -v agnix &> /dev/null; then
    if (cd "$REPO_DIR" && agnix) 2>/dev/null; then
      green "  PASS: agnix validation passed"
    else
      yellow "  WARN: agnix found issues (review above)"
      # Don't fail on agnix warnings - it's advisory
    fi
  elif command -v npx &> /dev/null; then
    yellow "  INFO: agnix not installed globally, trying npx..."
    if (cd "$REPO_DIR" && npx -y agnix) 2>/dev/null; then
      green "  PASS: agnix validation passed"
    else
      yellow "  WARN: agnix found issues (review above)"
    fi
  else
    yellow "  SKIP: agnix not installed (npm install -g agnix)"
  fi
fi

# --- 3. Check for common issues ---
echo ""
echo "--- Common Issues ---"

# Check for skills missing SKILL.md
missing_skills=0
for dir in "$REPO_DIR"/skills/*/; do
  if [ ! -f "$dir/SKILL.md" ]; then
    red "  FAIL: $(basename "$dir") has no SKILL.md"
    missing_skills=$((missing_skills + 1))
  fi
done
if [ "$missing_skills" -eq 0 ]; then
  green "  PASS: All skill directories have SKILL.md"
fi

# Check for agents missing frontmatter
missing_frontmatter=0
for agent in "$REPO_DIR"/agents/*.md; do
  [ -e "$agent" ] || continue
  [[ "$(basename "$agent")" == "README.md" ]] && continue
  if ! head -1 "$agent" | grep -q "^---"; then
    red "  FAIL: $(basename "$agent") missing YAML frontmatter"
    missing_frontmatter=$((missing_frontmatter + 1))
  fi
done
if [ "$missing_frontmatter" -eq 0 ]; then
  green "  PASS: All agents have YAML frontmatter"
fi

# (Description length checks not needed for Cursor - .mdc handles context via globs/alwaysApply)

# --- Summary ---
echo ""
if [ "$ERRORS" -gt 0 ]; then
  red "FAILED: $ERRORS error(s) found"
  exit 1
else
  green "PASSED: All checks passed"
  exit 0
fi
