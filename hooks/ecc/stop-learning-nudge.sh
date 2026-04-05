#!/usr/bin/env bash
# ECC / Longform: optional Stop-hook reminder for verification + continuous learning.
# Does not block; prints to stderr only when enabled.
#
# Env: MCR_ECC_STOP_NUDGE=1 to enable (default: off — avoids noise every response).

set -euo pipefail

if [[ "${MCR_ECC_STOP_NUDGE:-0}" != "1" ]]; then
  exit 0
fi

# Drain stdin (Stop hook may pass JSON) — ignore content
cat >/dev/null 2>&1 || true

echo "[ECC] End of turn: consider /verification-before-completion before claiming done; tool-observe logs + /continuous-learning-v2 for session patterns (see /ecc-harness-playbook)." >&2
exit 0
