#!/bin/bash
# DEPRECATED: Global install is not supported by the new install.sh.
# Skills must live in per-project directories.
echo "⚠ install-global.sh is deprecated and not supported by the new installer."
echo "  Per-project: bash $(dirname "$0")/install.sh --target cursor"
echo "  See: bash $(dirname "$0")/install.sh --help"
exit 1
