#!/usr/bin/env bash
# Install git pre-commit hook for ai-coding-rules
#
# Usage: ./scripts/install-hooks.sh
#
# Creates a pre-commit hook that validates before each commit.

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_DIR="$(dirname "$SCRIPT_DIR")"
HOOKS_DIR="$REPO_DIR/.git/hooks"

mkdir -p "$HOOKS_DIR"

PRE_COMMIT="$HOOKS_DIR/pre-commit"

if [ -f "$PRE_COMMIT" ] && grep -q "ai-coding-rules" "$PRE_COMMIT" 2>/dev/null; then
  echo "Pre-commit hook already installed."
  exit 0
fi

cat > "$PRE_COMMIT" << 'HOOK_EOF'
#!/usr/bin/env bash
# Pre-commit hook: validate skills, rules, agents before commit
# Skip with: git commit --no-verify

set -euo pipefail

REPO_ROOT="$(git rev-parse --show-toplevel)"

if [ -x "$REPO_ROOT/scripts/validate.sh" ]; then
  echo "Running pre-commit validation..."
  "$REPO_ROOT/scripts/validate.sh" --quick
fi
HOOK_EOF

chmod +x "$PRE_COMMIT"
echo "Pre-commit hook installed at $PRE_COMMIT"
echo "Runs validate.sh --quick before each commit."
echo "Skip with: git commit --no-verify"
