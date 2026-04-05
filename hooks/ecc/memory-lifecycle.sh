#!/usr/bin/env bash
# ECC-aligned session memory: lifecycle logging + snapshots of active_context (Longform guide).
# Subcommands: start | pre-compact | stop
# Resolves .claude/ vs .cursor/ from project root (same idea as tool-observe.sh).

set -euo pipefail

CMD="${1:-}"

ROOT="${CLAUDE_PROJECT_DIR:-${CURSOR_PROJECT_DIR:-}}"
if [[ -z "$ROOT" ]] && git rev-parse --show-toplevel &>/dev/null; then
  ROOT="$(git rev-parse --show-toplevel)"
fi
ROOT="${ROOT:-.}"
if [[ -d "$ROOT" ]]; then
  ROOT="$(cd "$ROOT" && pwd)"
fi

if [[ -d "$ROOT/.claude" ]]; then
  MEM="$ROOT/.claude/memory"
  SSN="$ROOT/.claude/sessions"
elif [[ -d "$ROOT/.cursor" ]]; then
  MEM="$ROOT/.cursor/memory"
  SSN="$ROOT/.cursor/sessions"
else
  MEM="$ROOT/.claude/memory"
  SSN="$ROOT/.claude/sessions"
fi

mkdir -p "$MEM" "$SSN"

ts() { date '+%Y-%m-%dT%H:%M:%S%z' 2>/dev/null || date; }

# One session id per harness "start" (persisted for pre-compact/stop lines in lifecycle.log).
gen_session_id() {
  local rnd
  rnd="$(openssl rand -hex 4 2>/dev/null || printf '%04x%04x' "${RANDOM:-0}" "${RANDOM:-0}")"
  printf '%s-%s' "$(date '+%Y%m%d-%H%M%S')" "$rnd"
}

session_id_read() {
  local sid=""
  if [[ -f "$SSN/.session_id" ]]; then
    read -r sid <"$SSN/.session_id" || true
    if [[ -n "${sid:-}" ]]; then
      echo "$sid"
      return
    fi
  fi
  echo "unknown"
}

case "$CMD" in
  start)
    sid="$(gen_session_id)"
    printf '%s' "$sid" >"$SSN/.session_id"
    echo "[$(ts)] session_start session_id=$sid" >>"$SSN/lifecycle.log"
    if [[ -f "$MEM/active_context.md" ]]; then
      echo "[$(ts)] session_id=$sid active_context.md lines=$(wc -l <"$MEM/active_context.md" | tr -d ' ')" >>"$SSN/lifecycle.log"
    fi
    ;;
  pre-compact)
    sid="$(session_id_read)"
    echo "[$(ts)] pre_compact session_id=$sid" >>"$SSN/lifecycle.log"
    if [[ -f "$MEM/active_context.md" ]]; then
      cp "$MEM/active_context.md" "$SSN/active_context-before-compact-$(date +%Y%m%d-%H%M%S).md" 2>/dev/null || true
    fi
    ;;
  stop)
    sid="$(session_id_read)"
    echo "[$(ts)] stop session_id=$sid" >>"$SSN/lifecycle.log"
    if [[ -f "$MEM/active_context.md" ]]; then
      cp "$MEM/active_context.md" "$SSN/session-end-$(date +%Y%m%d-%H%M%S).md" 2>/dev/null || true
    fi
    ;;
  *)
    exit 0
    ;;
esac

exit 0
