#!/bin/bash
# Hook: afterFileEdit
# Scans edited files for potential secrets/credentials
# Exit code 2 = deny (block commit), 0 = allow

# Read JSON input from stdin
input=$(cat)
file_path=$(echo "$input" | jq -r '.file_path // empty')

if [ -z "$file_path" ] || [ ! -f "$file_path" ]; then
  exit 0
fi

# Patterns that indicate potential secrets (case-insensitive)
SECRET_PATTERNS=(
  "password\s*=\s*['\"][^'\"]+['\"]"
  "api[_-]?key\s*=\s*['\"][^'\"]+['\"]"
  "secret[_-]?key\s*=\s*['\"][^'\"]+['\"]"
  "access[_-]?token\s*=\s*['\"][^'\"]+['\"]"
  "aws[_-]?access[_-]?key"
  "aws[_-]?secret[_-]?access[_-]?key"
  "private[_-]?key\s*=\s*['\"][^'\"]+['\"]"
  "-----BEGIN\s+(RSA\s+)?PRIVATE\s+KEY-----"
  "-----BEGIN\s+EC\s+PRIVATE\s+KEY-----"
  "-----BEGIN\s+DSA\s+PRIVATE\s+KEY-----"
)

# Check file content for secret patterns
found_secrets=()
for pattern in "${SECRET_PATTERNS[@]}"; do
  if grep -qiE "$pattern" "$file_path" 2>/dev/null; then
    found_secrets+=("$pattern")
  fi
done

if [ ${#found_secrets[@]} -gt 0 ]; then
  echo "{\"permission\": \"deny\", \"user_message\": \"Potential secret detected in $(basename "$file_path"). Please use environment variables or secrets manager instead.\"}"
  exit 2
fi

exit 0
