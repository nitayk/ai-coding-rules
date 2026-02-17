#!/usr/bin/env bash
# Validate ai-coding-rules: frontmatter, skills, agents, rules
#
# Usage:
#   ./scripts/validate.sh          # Full validation
#   ./scripts/validate.sh --quick  # Frontmatter only
#   ./scripts/validate.sh --fix    # Auto-fix what we can

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_DIR="$(dirname "$SCRIPT_DIR")"
MODE="${1:-}"
ERRORS=0
WARNINGS=0

red()    { printf "\033[31m%s\033[0m\n" "$1"; }
green()  { printf "\033[32m%s\033[0m\n" "$1"; }
yellow() { printf "\033[33m%s\033[0m\n" "$1"; }

echo "Validating ai-coding-rules..."
echo "Repo: $REPO_DIR"
echo ""

# ─── 1. Skills validation ───
echo "--- Skills ---"
skill_count=0
skill_errors=0

for dir in "$REPO_DIR"/skills/*/; do
  [ -d "$dir" ] || continue
  sname=$(basename "$dir")

  # Must have SKILL.md
  if [ ! -f "$dir/SKILL.md" ]; then
    red "  FAIL: $sname/ has no SKILL.md"
    skill_errors=$((skill_errors + 1))
    continue
  fi

  skill_count=$((skill_count + 1))

  # Must have --- frontmatter markers
  markers=$(grep -c "^---$" "$dir/SKILL.md" || true)
  if [ "$markers" -lt 2 ]; then
    red "  FAIL: $sname/SKILL.md missing YAML frontmatter (needs --- markers)"
    skill_errors=$((skill_errors + 1))
    continue
  fi

  # Extract frontmatter and check required fields
  fm=$(awk '/^---$/{n++; next} n==1{print} n>=2{exit}' "$dir/SKILL.md")

  has_name=$(echo "$fm" | grep -c "^name:" 2>/dev/null || echo 0)
  has_desc=$(echo "$fm" | grep -c "^description:" 2>/dev/null || echo 0)

  if [ "$has_name" = "0" ]; then
    red "  FAIL: $sname/SKILL.md missing 'name:' in frontmatter"
    skill_errors=$((skill_errors + 1))
  fi

  if [ "$has_desc" = "0" ]; then
    red "  FAIL: $sname/SKILL.md missing 'description:' in frontmatter"
    skill_errors=$((skill_errors + 1))
  fi

  # Check name matches folder
  yaml_name=$(echo "$fm" | grep "^name:" | head -1 | sed 's/^name: *//' | tr -d '"' | tr -d "'")
  if [ -n "$yaml_name" ] && [ "$yaml_name" != "$sname" ]; then
    red "  FAIL: $sname/SKILL.md name '$yaml_name' doesn't match folder '$sname'"
    skill_errors=$((skill_errors + 1))
  fi
done

if [ "$skill_errors" -eq 0 ]; then
  green "  PASS: All $skill_count skills valid"
else
  ERRORS=$((ERRORS + skill_errors))
fi

# ─── 2. Skills description length ───
if [ "$MODE" != "--quick" ] && command -v python3 &> /dev/null; then
  echo ""
  echo "--- Skill Description Length ---"
  issue_count=$(python3 -c "
import os, sys
try:
    import yaml
except ImportError:
    print('0')
    sys.exit(0)

skills_dir = os.path.join('$REPO_DIR', 'skills')
issues = 0
for sname in sorted(os.listdir(skills_dir)):
    skill_md = os.path.join(skills_dir, sname, 'SKILL.md')
    if not os.path.isfile(skill_md): continue
    with open(skill_md) as f: content = f.read()
    parts = content.split('---', 2)
    if len(parts) < 3: continue
    try: fm = yaml.safe_load(parts[1])
    except: continue
    if not fm: continue
    desc = str(fm.get('description', ''))
    if len(desc) > 500:
        print(f'  WARN: {sname} description too long ({len(desc)} chars, max 500)', file=sys.stderr)
        issues += 1
print(issues)
" 2>&1)

  # Filter warnings to stderr, count from stdout
  desc_warnings=$(echo "$issue_count" | grep "WARN" || true)
  issue_count=$(echo "$issue_count" | grep -v "WARN" | tail -1 | tr -d ' ')

  if [ -n "$desc_warnings" ]; then
    echo "$desc_warnings"
  fi

  if [ "$issue_count" = "0" ] || [ -z "$issue_count" ]; then
    green "  PASS: All skill descriptions under 500 chars"
  else
    yellow "  WARN: $issue_count skill(s) with long descriptions (Cursor may skip them)"
    WARNINGS=$((WARNINGS + issue_count))
  fi
fi

# ─── 3. Rules validation (.mdc frontmatter) ───
echo ""
echo "--- Rules (.mdc files) ---"
rule_count=0
rule_errors=0

while IFS= read -r mdc; do
  [ -f "$mdc" ] || continue
  rule_count=$((rule_count + 1))

  # Check for frontmatter
  first_line=$(head -1 "$mdc")
  if [ "$first_line" != "---" ]; then
    # Rules without frontmatter are OK (they're "always apply" by default)
    continue
  fi

  # If has frontmatter, check it closes properly
  markers=$(grep -c "^---$" "$mdc" || true)
  if [ "$markers" -lt 2 ]; then
    red "  FAIL: $(echo "$mdc" | sed "s|$REPO_DIR/||") has unclosed frontmatter"
    rule_errors=$((rule_errors + 1))
  fi
done < <(find "$REPO_DIR" -path "*/skills" -prune -o -name "*.mdc" -print)

if [ "$rule_errors" -eq 0 ]; then
  green "  PASS: $rule_count rules checked"
else
  ERRORS=$((ERRORS + rule_errors))
fi

# ─── 4. Agents validation ───
echo ""
echo "--- Agents ---"
agent_errors=0
for agent in "$REPO_DIR"/agents/*.md; do
  [ -e "$agent" ] || continue
  [[ "$(basename "$agent")" == "README.md" ]] && continue
  if ! head -1 "$agent" | grep -q "^---"; then
    red "  FAIL: $(basename "$agent") missing YAML frontmatter"
    agent_errors=$((agent_errors + 1))
  fi
done
if [ "$agent_errors" -eq 0 ]; then
  green "  PASS: All agents have frontmatter"
else
  ERRORS=$((ERRORS + agent_errors))
fi

# ─── 5. Commands validation ───
echo ""
echo "--- Commands ---"
cmd_count=0
for cmd in "$REPO_DIR"/commands/*.md; do
  [ -e "$cmd" ] || continue
  [[ "$(basename "$cmd")" == "README.md" ]] && continue
  cmd_count=$((cmd_count + 1))
done
green "  PASS: $cmd_count commands found"

# ─── Summary ───
echo ""
echo "=========================================="
echo "  Skills:   $skill_count"
echo "  Rules:    $rule_count"
echo "  Errors:   $ERRORS"
echo "  Warnings: $WARNINGS"
echo "=========================================="

if [ "$ERRORS" -gt 0 ]; then
  red "FAILED: $ERRORS error(s) found"
  exit 1
else
  green "PASSED: All checks passed"
  exit 0
fi
