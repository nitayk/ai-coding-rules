#!/usr/bin/env bash
# afterFileEdit hook: auto-format files after AI edits.
# Detects language by extension and runs the appropriate formatter if available.
# Silently skips if no formatter is found — never blocks or errors.

set -eo pipefail

INPUT=$(cat)
FILE=$(echo "$INPUT" | grep -o '"file"[[:space:]]*:[[:space:]]*"[^"]*"' | head -1 | sed 's/.*"file"[[:space:]]*:[[:space:]]*"//;s/"$//')

[ -z "$FILE" ] && exit 0
[ ! -f "$FILE" ] && exit 0

EXT="${FILE##*.}"

format_with() {
  if command -v "$1" &>/dev/null; then
    "$@" 2>/dev/null || true
    exit 0
  fi
}

case "$EXT" in
  js|jsx|ts|tsx|css|scss|json|html|md|yaml|yml|vue|svelte)
    format_with npx prettier --write "$FILE"
    format_with npx biome format --write "$FILE"
    ;;
  py)
    format_with black --quiet "$FILE"
    format_with ruff format "$FILE"
    ;;
  go)
    format_with gofmt -w "$FILE"
    ;;
  rs)
    format_with rustfmt "$FILE"
    ;;
  scala|sc)
    format_with scalafmt "$FILE"
    ;;
  rb)
    format_with rubocop -A --fail-level error "$FILE"
    ;;
  swift)
    format_with swift-format --in-place "$FILE"
    ;;
  kt|kts)
    format_with ktlint --format "$FILE"
    ;;
  java)
    format_with google-java-format --replace "$FILE"
    ;;
  php)
    format_with php-cs-fixer fix "$FILE" --quiet
    ;;
esac

exit 0
