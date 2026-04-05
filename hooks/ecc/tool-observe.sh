#!/usr/bin/env bash
# Hook: Claude PreToolUse/PostToolUse; Cursor postToolUse (see hooks/README.md)
# Append-only JSONL-style lines for session/tool observability (opt-in learning pipelines).
# Fail-open: never blocks the agent; no secrets in output beyond stdin payload.

set -euo pipefail

PHASE="${1:-post}"

json_input=""
if [ -t 0 ]; then
  json_input="{}"
else
  json_input=$(cat || true)
fi

timestamp=$(date '+%Y-%m-%d %H:%M:%S')

# Prefer explicit project roots from harnesses, then git root.
ROOT="${CURSOR_PROJECT_DIR:-}"
if [ -z "$ROOT" ]; then
  ROOT="${CLAUDE_PROJECT_DIR:-}"
fi
if [ -z "$ROOT" ] && git rev-parse --show-toplevel &>/dev/null; then
  ROOT="$(git rev-parse --show-toplevel)"
fi
if [ -z "$ROOT" ]; then
  ROOT="${PWD:-.}"
fi

if [ -d "$ROOT" ]; then
  ROOT="$(cd "$ROOT" && pwd)"
else
  ROOT="."
fi

LOG_DIR=""
if [ -d "$ROOT/.claude/hooks" ]; then
  LOG_DIR="$ROOT/.claude/hooks/logs"
elif [ -d "$ROOT/.cursor/hooks" ]; then
  LOG_DIR="$ROOT/.cursor/hooks/logs"
else
  LOG_DIR="${TMPDIR:-/tmp}/mobile-cursor-rules-hook-logs"
fi

mkdir -p "$LOG_DIR"
day=$(date '+%Y-%m-%d')
log_file="$LOG_DIR/tool-observe-${day}.log"

# One line per event; truncate very large payloads (tool payloads can be huge).
line=$(printf '%s' "$json_input" | tr '\n' ' ' | head -c 16384)

{
  printf '[%s] [tool-observe %s] ' "$timestamp" "$PHASE"
  printf '%s\n' "$line"
} >> "$log_file"

exit 0
