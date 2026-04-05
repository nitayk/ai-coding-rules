#!/bin/bash
# Hook: postToolUse, sessionEnd
# Audits AI actions for compliance and analytics
# Non-blocking: logs to file

# Read JSON input from stdin
json_input=$(cat)

# Create timestamp
timestamp=$(date '+%Y-%m-%d %H:%M:%S')

# Determine log file location
# Try project root first, fallback to temp
if [ -n "$CURSOR_PROJECT_DIR" ]; then
  ROOT="$CURSOR_PROJECT_DIR"
else
  # Use git top level if possible, else PWD
  ROOT=$(git rev-parse --show-toplevel 2>/dev/null || echo "$PWD")
fi

if [[ -d "$ROOT/.claude" ]]; then
  LOG_DIR="$ROOT/.claude/hooks/logs"
elif [[ -d "$ROOT/.cursor" ]]; then
  LOG_DIR="$ROOT/.cursor/hooks/logs"
else
  LOG_DIR="/tmp/ai-hooks-logs"
fi

mkdir -p "$LOG_DIR"

# Log file: one per day
log_file="$LOG_DIR/audit-$(date '+%Y-%m-%d').log"

# Extract hook event name
hook_event=$(echo "$json_input" | jq -r '.hook_event_name // "unknown"')

# Write log entry
echo "[$timestamp] [$hook_event] $json_input" >> "$log_file"

# Optional: Also log to syslog (uncomment if needed)
# logger -t cursor-hooks "[$hook_event] $json_input"

exit 0
