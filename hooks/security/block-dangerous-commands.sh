#!/bin/bash
# Hook: beforeShellExecution
# Blocks dangerous git and infrastructure commands
# Exit code 2 = deny, 0 = allow

# Read JSON input from stdin
input=$(cat)
command=$(echo "$input" | jq -r '.command // empty')
cwd=$(echo "$input" | jq -r '.cwd // empty')

if [ -z "$command" ]; then
  echo '{"permission": "allow"}'
  exit 0
fi

# Dangerous patterns that should be blocked
DANGEROUS_PATTERNS=(
  "git\s+push\s+.*\s+(main|master|develop)"
  "git\s+push\s+.*\s+--force"
  "git\s+push\s+.*\s+-f"
  "rm\s+-rf\s+/"
  "rm\s+-rf\s+.*\.\./"
  "kubectl\s+delete\s+.*\s+--all"
  "kubectl\s+delete\s+namespace\s+(prod|production)"
  "terraform\s+destroy\s+.*\s+-auto-approve"
  "aws\s+s3\s+rb\s+s3://.*\s+--force"
  "mysql\s+-e\s+.*DROP\s+DATABASE"
  "psql\s+-c\s+.*DROP\s+DATABASE"
)

# Check command against dangerous patterns
for pattern in "${DANGEROUS_PATTERNS[@]}"; do
  if echo "$command" | grep -qiE "$pattern"; then
    echo "{\"permission\": \"deny\", \"user_message\": \"Dangerous command blocked: $command\", \"agent_message\": \"This command is blocked by security policy. Please review and use safer alternatives.\"}"
    exit 2
  fi
done

# Commands that require approval
APPROVAL_PATTERNS=(
  "git\s+push"
  "kubectl\s+apply"
  "kubectl\s+delete"
  "terraform\s+apply"
  "terraform\s+destroy"
  "docker\s+rm\s+-f"
)

for pattern in "${APPROVAL_PATTERNS[@]}"; do
  if echo "$command" | grep -qiE "$pattern"; then
    echo "{\"permission\": \"ask\", \"user_message\": \"This command requires approval: $command\"}"
    exit 0
  fi
done

# Allow other commands
echo '{"permission": "allow"}'
exit 0
