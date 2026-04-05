#!/usr/bin/env bash
# Longform ECC pattern: nudge manual /compact after N Edit/Write-style tool calls (default 50).
# Env: MCR_STRATEGIC_COMPACT_THRESHOLD (default 50). Set to 0 to disable counting.
# Reads Claude Code PreToolUse JSON from stdin; fail-open.

set -euo pipefail

THRESHOLD="${MCR_STRATEGIC_COMPACT_THRESHOLD:-50}"
if ! [[ "$THRESHOLD" =~ ^[0-9]+$ ]]; then
  THRESHOLD=50
fi
if [[ "$THRESHOLD" -eq 0 ]]; then
  exit 0
fi

json_input=$(cat || true)

tool=""
if command -v jq &>/dev/null; then
  tool=$(echo "$json_input" | jq -r '.tool // .tool_name // .name // empty' 2>/dev/null || true)
fi

case "$tool" in
  Edit|Write|MultiEdit|StrReplace|NotebookEdit) ;;
  *) exit 0 ;;
esac

ROOT="${CLAUDE_PROJECT_DIR:-${CURSOR_PROJECT_DIR:-}}"
if [[ -z "$ROOT" ]] && git rev-parse --show-toplevel &>/dev/null; then
  ROOT="$(git rev-parse --show-toplevel)"
fi
ROOT="${ROOT:-.}"
if [[ -d "$ROOT" ]]; then
  ROOT="$(cd "$ROOT" && pwd)"
fi

if [[ -d "$ROOT/.claude" ]]; then
  SSN="$ROOT/.claude/sessions"
elif [[ -d "$ROOT/.cursor" ]]; then
  SSN="$ROOT/.cursor/sessions"
else
  SSN="$ROOT/.claude/sessions"
fi
mkdir -p "$SSN"

COUNT_FILE="$SSN/.strategic-compact-tool-count"
count=1
if [[ -f "$COUNT_FILE" ]]; then
  count=$(($(cat "$COUNT_FILE") + 1))
fi
echo "$count" >"$COUNT_FILE"

if [[ "$count" -eq "$THRESHOLD" ]] || [[ $((count % THRESHOLD)) -eq 0 ]]; then
  echo "[StrategicCompact] ${count} Edit/Write-class tool calls — consider running /compact at a natural breakpoint (see strategic-compact skill)." >&2
fi

exit 0
