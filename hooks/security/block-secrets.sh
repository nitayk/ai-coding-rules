#!/bin/bash
# Hook: beforeReadFile
# Blocks reading sensitive files (secrets, configs, credentials)
# Exit code 2 = deny, 0 = allow

# Read JSON input from stdin
input=$(cat)
file_path=$(echo "$input" | jq -r '.file_path // empty')

if [ -z "$file_path" ]; then
  # No file path, allow
  echo '{"permission": "allow"}'
  exit 0
fi

# List of sensitive patterns (case-insensitive)
SENSITIVE_PATTERNS=(
  "\.env$"
  "\.env\."
  "secrets"
  "credentials"
  "\.pem$"
  "\.key$"
  "\.p12$"
  "\.pfx$"
  "\.jks$"
  "\.keystore$"
  "id_rsa"
  "id_dsa"
  "\.secret"
  "\.private"
  "config/secrets"
  "\.credentials"
)

# Check if file path matches any sensitive pattern
for pattern in "${SENSITIVE_PATTERNS[@]}"; do
  if echo "$file_path" | grep -qiE "$pattern"; then
    echo "{\"permission\": \"deny\", \"user_message\": \"Access to sensitive file blocked: $(basename "$file_path")\"}"
    exit 2
  fi
done

# Allow access
echo '{"permission": "allow"}'
exit 0
