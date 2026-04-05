#!/usr/bin/env bash
# beforeReadFile hook: block reading files likely to contain secrets.
# Exit 0 = allow, exit 2 = block.

set -eo pipefail

INPUT=$(cat)
FILE=$(echo "$INPUT" | grep -o '"file"[[:space:]]*:[[:space:]]*"[^"]*"' | head -1 | sed 's/.*"file"[[:space:]]*:[[:space:]]*"//;s/"$//')

[ -z "$FILE" ] && exit 0

BASENAME=$(basename "$FILE")
LOWER_BASENAME=$(echo "$BASENAME" | tr '[:upper:]' '[:lower:]')

block() {
  echo "{\"decision\":\"block\",\"reason\":\"$1\"}"
  exit 2
}

# --- Exact filename matches ---
case "$LOWER_BASENAME" in
  .env|.env.local|.env.production|.env.staging|.env.development)
    block "Blocked: environment file likely contains secrets" ;;
  .env.*)
    block "Blocked: dotenv variant likely contains secrets" ;;
  credentials.json|service-account.json|service_account.json)
    block "Blocked: credential file" ;;
  id_rsa|id_ed25519|id_ecdsa|id_dsa)
    block "Blocked: SSH private key" ;;
  *.pem|*.key|*.p12|*.pfx|*.jks)
    block "Blocked: certificate/key file" ;;
  .npmrc|.pypirc|.docker/config.json)
    block "Blocked: package registry credentials" ;;
  .netrc|.pgpass|.my.cnf)
    block "Blocked: service credential file" ;;
  secrets.yaml|secrets.yml|secrets.json|vault.json)
    block "Blocked: secrets configuration file" ;;
  *secret*|*credential*|*password*)
    block "Blocked: filename suggests sensitive content" ;;
esac

# --- Path pattern matches ---
echo "$FILE" | grep -qE '\.aws/credentials' && block "Blocked: AWS credentials file"
echo "$FILE" | grep -qE '\.ssh/.*key' && block "Blocked: SSH key file"
echo "$FILE" | grep -qE '\.gnupg/' && block "Blocked: GPG directory"
echo "$FILE" | grep -qE '\.kube/config' && block "Blocked: Kubernetes config (may contain tokens)"

echo '{"decision":"approve"}'
exit 0
