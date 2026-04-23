#!/bin/bash
# DEPRECATED: This script is superseded by install.sh
# Use: bash install.sh --target claude [--copy] [--dry-run]
echo "⚠ install-claude.sh is deprecated. Use install.sh instead:"
echo "  bash $(dirname "$0")/install.sh --target claude $*"
exec bash "$(dirname "$0")/install.sh" --target claude "$@"
