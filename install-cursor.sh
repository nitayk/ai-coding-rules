#!/bin/bash
# DEPRECATED: This script is superseded by install.sh
# Use: bash install.sh --target cursor [--copy] [--dry-run]
echo "⚠ install-cursor.sh is deprecated. Use install.sh instead:"
echo "  bash $(dirname "$0")/install.sh --target cursor $*"
exec bash "$(dirname "$0")/install.sh" --target cursor "$@"
