#!/bin/bash
# Hook: afterFileEdit
# Auto-formats code after edits based on file type
# Non-blocking: if formatting fails, allow edit anyway

# Read JSON input from stdin
input=$(cat)
file_path=$(echo "$input" | jq -r '.file_path // empty')

if [ -z "$file_path" ] || [ ! -f "$file_path" ]; then
  exit 0
fi

# Get file extension
extension="${file_path##*.}"
basename=$(basename "$file_path")

# Format based on file type
case "$extension" in
  scala)
    # Try scalafmt if available
    if command -v scalafmt &> /dev/null; then
      scalafmt "$file_path" 2>/dev/null || true
    fi
    ;;
  py)
    # Try black if available
    if command -v black &> /dev/null; then
      black --quiet "$file_path" 2>/dev/null || true
    elif command -v autopep8 &> /dev/null; then
      autopep8 --in-place "$file_path" 2>/dev/null || true
    fi
    ;;
  js|jsx|ts|tsx|json)
    # Try prettier if available
    if command -v prettier &> /dev/null; then
      prettier --write "$file_path" 2>/dev/null || true
    fi
    ;;
  swift)
    # Try swiftformat if available
    if command -v swiftformat &> /dev/null; then
      swiftformat "$file_path" 2>/dev/null || true
    fi
    ;;
  kt)
    # Try ktlint if available
    if command -v ktlint &> /dev/null; then
      ktlint -F "$file_path" 2>/dev/null || true
    fi
    ;;
  go)
    # Try gofmt if available
    if command -v gofmt &> /dev/null; then
      gofmt -w "$file_path" 2>/dev/null || true
    fi
    ;;
  sh|bash)
    # Try shfmt if available
    if command -v shfmt &> /dev/null; then
      shfmt -w "$file_path" 2>/dev/null || true
    fi
    ;;
esac

exit 0
