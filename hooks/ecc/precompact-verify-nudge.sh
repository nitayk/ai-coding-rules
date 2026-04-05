#!/usr/bin/env bash
# ECC / Longform: optional PreCompact reminder to run verification before context is compressed.
# Claude Code only (Cursor has no PreCompact hook). Default off — no stderr unless opted in.
#
# Env: MCR_ECC_PRECOMPACT_NUDGE=1 to enable

set -euo pipefail

if [[ "${MCR_ECC_PRECOMPACT_NUDGE:-0}" != "1" ]]; then
  exit 0
fi

cat >/dev/null 2>&1 || true

echo "[ECC] PreCompact: context will shrink — if you have not yet, run /verification-before-completion or your test command before relying on this session alone." >&2
exit 0
