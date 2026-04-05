# Agent hooks (Cursor + Claude Code)

Automated enforcement and security hooks for **Cursor** and **Claude Code**. Hooks run automatically to enforce policies, scan for issues, and audit AI actions.

## Overview

Hooks complement rules by **enforcing** behavior rather than just guiding it:
- **Rules** (`.mdc` files): Tell AI what to do
- **Hooks**: Control what AI **can** do and **did** do

### Directory layout (this submodule)

Hooks are grouped by role. **Claude Code and Cursor only care that `hooks.json` paths match files under the project’s** `.claude/hooks/` **or** `.cursor/hooks/` — **subfolders are fine** (not limited to a single flat directory).

| Folder | Role |
|--------|------|
| **`ecc/`** | Longform / ECC-aligned: memory lifecycle, `tool-observe`, strategic compact nudge, optional `stop-learning-nudge`, optional `precompact-verify-nudge` (Claude **PreCompact** only) |
| **`security/`** | `block-secrets`, `scan-secrets*`, `block-dangerous-commands` |
| **`quality/`** | `format-*.sh`, `validate-yaml.py` |
| **`observability/`** | `audit.sh` |
| **`ecc-hooks/`** | Vendored upstream ECC reference (git subtree); **excluded** from `sync-rules.sh` copy to consumer repos |

**At repo root of `hooks/`:** `hooks.json`, `hooks-cursor.json`, `run-hook.cmd`, extensionless **`session-start`** (invoked via `run-hook.cmd` on some setups), `cursor-adapter.js`, and this README.

### Claude vs Cursor (tool observation)

The shared `hooks/hooks.json` in this repo lists **both** harnesses. **`sync-rules.sh` strips keys per `--target`** (requires `jq`) so each install only ships events that product understands:

| Harness | Tool lifecycle hooks | Notes |
|--------|------------------------|--------|
| **Claude Code** | `PreToolUse`, `PostToolUse` (PascalCase) | Wired to `.claude/hooks/ecc/tool-observe.sh` **pre** / **post** — append-only logs for optional downstream learning pipelines. |
| **Claude Code** | `SessionStart`, `PreCompact`, `Stop` | `ecc/memory-lifecycle.sh` for session start, before compaction, and session end (ECC Longform pattern). |
| **Cursor** | `postToolUse` (camelCase) | No generic **pre-tool** hook in the [Agent Hooks](#hook-events) table; use **`postToolUse`** for observation (same script under **`ecc/`**, **post** only). Use **`beforeMCPExecution`** / **`afterMCPExecution`** if you need MCP-specific gating. |
| **Cursor** | `sessionStart`, `stop` | Same `ecc/memory-lifecycle.sh` (paths resolve to `.cursor/memory` when `.claude` is absent). **No** `PreCompact` in Cursor’s documented hook list — use manual `/compact` + strategic-compact skill. |

If `jq` is missing, filtering is skipped and a warning is printed — install `jq` for the split.

## Included Hooks

### Security Hooks

#### `security/block-secrets.sh` (beforeReadFile)
- **Purpose**: Prevents AI from reading sensitive files
- **Blocks**: `.env`, `.pem`, `.key`, `secrets`, `credentials`, etc.
- **Behavior**: Denies access with user message

#### `security/scan-secrets.sh` (afterFileEdit)
- **Purpose**: Scans edited files for hardcoded secrets
- **Detects**: Passwords, API keys, private keys, AWS credentials
- **Behavior**: Blocks commit if secrets detected

#### `quality/validate-yaml.py` (afterFileEdit)
- **Purpose**: Validates YAML frontmatter in .md/.mdc files
- **Detects**: Invalid YAML syntax, missing quotes
- **Behavior**: Validation failure only (non-blocking for now)

#### `security/block-dangerous-commands.sh` (beforeShellExecution)
- **Purpose**: Blocks dangerous git and infrastructure commands
- **Blocks**: `git push --force`, `rm -rf /`, `kubectl delete --all`, etc.
- **Requires approval**: `git push`, `kubectl apply`, `terraform apply`

### Code Quality Hooks

#### `quality/format-code.sh` (afterFileEdit)
- **Purpose**: Auto-formats code after edits
- **Supports**: Scala (scalafmt), Python (black/autopep8), JS/TS (prettier), Swift (swiftformat), Kotlin (ktlint), Go (gofmt)
- **Behavior**: Non-blocking (if formatter unavailable, allows edit)

### Observability Hooks

#### `observability/audit.sh` (postToolUse, sessionEnd)
- **Purpose**: Logs all AI actions for compliance
- **Logs to**: `.cursor/hooks/logs/audit-YYYY-MM-DD.log`
- **Behavior**: Non-blocking, fire-and-forget

#### `ecc/tool-observe.sh` (Claude PreToolUse + PostToolUse; Cursor postToolUse)
- **Purpose**: Lightweight **append-only** logging of tool payloads for observability / optional **continuous-learning** pipelines (see `/continuous-learning-v2`). Does **not** block tools.
- **Args**: `pre` or `post` (Claude runs both; Cursor runs **post** only).
- **Logs to**: `.claude/hooks/logs/tool-observe-YYYY-MM-DD.log` or `.cursor/hooks/logs/` (same filename pattern), depending on which tree exists under the repo root.
- **Behavior**: Non-blocking (`async: true` for Claude Code); truncates very large stdin payloads.

#### `ecc/memory-lifecycle.sh` (Claude SessionStart + PreCompact + Stop; Cursor sessionStart + stop)
- **Purpose**: Aligns with **Longform ECC** memory persistence: log session phases and snapshot `active_context.md` (from `/session-memory`) at **pre-compact** and **session end**.
- **Args**: `start` | `pre-compact` | `stop`
- **Writes**: `lifecycle.log` (append) plus timestamped `active_context-*.md` copies under **`.claude/sessions/`** or **`.cursor/sessions/`** (whichever tree exists for the project). On **`start`**, generates a **`session_id`**, writes it to **`.session_id`** in that same `sessions/` dir, and prefixes log lines with **`session_id=...`** for start / pre-compact / stop.
- **Behavior**: **Fail-open**; never blocks the agent. Inspect env + session file: **`scripts/ecc-env.sh`** or **`/ecc-env`**.

#### `ecc/strategic-compact-nudge.sh` (Claude PreToolUse only; second matcher block)
- **Purpose**: After **N** Edit/Write-class tool calls (default **50**), prints a **stderr** reminder to run `/compact` at a natural breakpoint (pairs with `/strategic-compact` skill).
- **Env**: `MCR_STRATEGIC_COMPACT_THRESHOLD` (default `50`; set to **`0`** to disable counting).
- **Behavior**: Parses stdin JSON with `jq` when available; **async: true**.

#### `ecc/stop-learning-nudge.sh` (Claude `Stop`; Cursor `stop`)
- **Purpose**: ECC-style **end-of-turn** reminder linking **verification** and **continuous learning** (see `/ecc-harness-playbook`).
- **Env**: **`MCR_ECC_STOP_NUDGE=1`** enables stderr output (default **`0`** — no noise unless you opt in).
- **Behavior**: Non-blocking; consumes Stop hook stdin; **async: true**.

#### `ecc/precompact-verify-nudge.sh` (Claude **PreCompact** only)
- **Purpose**: Before **context compaction**, optional stderr reminder to run **`/verification-before-completion`** (or tests) while full context still exists.
- **Env**: **`MCR_ECC_PRECOMPACT_NUDGE=1`** enables (default **`0`**). **Cursor** does not expose **PreCompact** — this hook is a no-op in Cursor installs (event not present).
- **Behavior**: Non-blocking; **async: true**. See **`/ecc-harness-playbook`** for all **`MCR_*`** toggles.

### Security (hooks as trust boundary)

Hooks and MCP config under `.claude/` / `.mcp.json` are **shared through git** in many workflows. Treat them like **supply-chain**: review changes, keep Claude Code **updated** (see vendor advisories on project trust hooks), and avoid copying opaque hook scripts from untrusted repos. See also the **Agentic Security** shorthand (OWASP MCP Top 10, prompt injection via attachments/PRs).

## Configuration

Hooks are configured in **`.cursor/hooks/hooks.json`** (Cursor) or **`.claude/hooks.json`** (Claude Code). The submodule ships **`hooks/hooks.json`**; `sync-rules.sh` merges with any repo-specific file and **filters keys per `--target`** (see [Claude vs Cursor](#claude-vs-cursor-tool-observation)).

Example (Cursor-shaped fragment — your merged file may differ):

```json
{
  "version": 1,
  "hooks": {
    "beforeReadFile": [
      { "command": ".cursor/hooks/block-secrets.sh", "timeout": 5 }
    ],
    "afterFileEdit": [
      { "command": ".cursor/hooks/scan-secrets.sh", "timeout": 10 },
      { "command": ".cursor/hooks/format-code.sh", "timeout": 30 }
    ],
    "beforeShellExecution": [
      {
        "command": ".cursor/hooks/block-dangerous-commands.sh",
        "timeout": 5,
        "matcher": { "tool_name": "Shell" }
      }
    ],
    "postToolUse": [
      { "command": ".cursor/hooks/observability/audit.sh", "timeout": 5 }
    ]
  }
}
```

## Setup

Hooks are automatically synced when you run `sync-rules.sh` or `install.sh`:

```bash
bash .cursor/rules/shared/sync-rules.sh
# Or use the full installer:
bash .cursor/rules/shared/install.sh
```

**What happens:**
1. Hook scripts are copied/updated to `.cursor/hooks/`
2. `hooks.json` is **merged** (shared hooks + repo-specific hooks)
3. Scripts are made executable

## Repo-Specific Hooks

To add repo-specific hooks, create `.cursor/hooks/hooks.json` in your repo:

```json
{
  "version": 1,
  "hooks": {
    "afterFileEdit": [
      {
        "command": ".cursor/hooks/my-custom-formatter.sh",
        "timeout": 30
      }
    ]
  }
}
```

**Merging behavior:**
- Shared hooks from `mobile-cursor-rules` are always included
- Repo-specific hooks are **added** to shared hooks (arrays are combined)
- If same hook event exists in both, both arrays are merged

**Example merge:**
- Shared: `afterFileEdit: [security/scan-secrets.sh, quality/format-code.sh]`
- Repo: `afterFileEdit: [my-formatter.sh]`
- Result: `afterFileEdit: [security/scan-secrets.sh, quality/format-code.sh, my-formatter.sh]`

## Hook Events

### Agent Hooks (Cmd+K / Agent Chat)

| Hook | When | Use Case |
|------|------|----------|
| `beforeReadFile` | Before reading file | Block sensitive files |
| `afterFileEdit` | After editing file | Format, scan secrets |
| `beforeShellExecution` | Before shell command | Block dangerous commands |
| `afterShellExecution` | After shell command | Audit, log |
| `beforeMCPExecution` | Before MCP tool | Validate MCP usage |
| `afterMCPExecution` | After MCP tool | Audit MCP calls |
| `postToolUse` | After any tool | General auditing |
| `sessionStart` | Session begins | Setup, inject context |
| `sessionEnd` | Session ends | Cleanup, analytics |
| `beforeSubmitPrompt` | Before sending prompt | Validate prompt |
| `stop` | Agent loop ends | Auto-retry, follow-up |

### Tab Hooks (Inline Completions)

| Hook | When | Use Case |
|------|------|----------|
| `beforeTabFileRead` | Tab reads file | Redact secrets |
| `afterTabFileEdit` | Tab edits file | Format Tab edits |

## Customization

### Disable a Hook

Remove from `hooks.json` or set `command` to empty:

```json
{
  "hooks": {
    "afterFileEdit": []  // Disable formatting
  }
}
```

### Modify Hook Behavior

1. Copy hook script to `.cursor/hooks/` (repo-specific)
2. Modify script
3. Update `hooks.json` to reference your script

**Example**: Custom formatter

```bash
# .cursor/hooks/my-formatter.sh
#!/bin/bash
# Your custom formatting logic
exit 0
```

```json
{
  "hooks": {
    "afterFileEdit": [
      { "command": ".cursor/hooks/my-formatter.sh" }
    ]
  }
}
```

### Add New Hook

1. Create script in `.cursor/hooks/`
2. Make executable: `chmod +x .cursor/hooks/my-hook.sh`
3. Add to `hooks.json`:

```json
{
  "hooks": {
    "beforeShellExecution": [
      { "command": ".cursor/hooks/my-hook.sh", "timeout": 10 }
    ]
  }
}
```

## Troubleshooting

### Hooks Not Running

1. **Check hooks are synced**: Run `sync-rules.sh` or `install.sh`
2. **Check permissions**: Scripts must be executable (`chmod +x`)
3. **Check paths**: Use `.cursor/hooks/script.sh` (relative to project root)
4. **Restart Cursor**: Hooks load on startup

### Hook Blocks Everything

- Check exit codes: `0` = allow, `2` = deny
- Review hook script logic
- Check timeout settings (hook may be timing out)

### Formatting Not Working

- Check formatter is installed: `which scalafmt`, `which black`, etc.
- Hook is non-blocking (fails gracefully if formatter missing)
- Check hook logs: `.cursor/hooks/logs/audit-*.log`

### Debugging

Enable debug logging in hook scripts:

```bash
# Add to hook script
echo "Debug: Hook executed" >> /tmp/hook-debug.log
```

Check Cursor Settings → Hooks tab for execution logs.

## Security Considerations

- **Fail-closed hooks**: `beforeReadFile`, `beforeMCPExecution` block if hook fails
- **Fail-open hooks**: `afterFileEdit`, `postToolUse` allow action if hook fails
- **Secrets**: Never log secrets in audit hooks
- **Permissions**: Hook scripts run with user permissions

## Industry Use Cases

### Common Patterns

1. **Security Scanning**: Scan for secrets, block sensitive files
2. **Code Formatting**: Auto-format after edits
3. **Infrastructure Safety**: Block dangerous kubectl/terraform commands
4. **Compliance Auditing**: Log all AI actions
5. **Policy Enforcement**: Require approval for risky operations

### Enterprise Examples

- **Semgrep**: Real-time vulnerability scanning
- **Corridor**: Code security feedback
- **1Password**: Secrets validation
- **Snyk**: Dependency security scanning
- **Oasis Security**: Least-privilege enforcement

## Optional: Longform-style session lifecycle (advanced)

Community guides (e.g. Longform “Everything Claude Code”) describe **PreCompact**, **SessionStart**, and **Stop** hooks to persist context across sessions. This repo **does not** enable that full stack by default—**opt-in only** (support and product differences).

### Claude Code

- **Claude** `hooks.json` uses events such as `SessionStart`, `PreCompact`, `Stop` (names depend on Anthropic docs). Example **illustrative** fragment (not merged into the default shared `hooks.json`):

```json
{
  "hooks": {
    "PreCompact": [
      {
        "matcher": "*",
        "hooks": [{ "type": "command", "command": "/path/to/pre-compact.sh" }]
      }
    ],
    "Stop": [
      {
        "matcher": "*",
        "hooks": [{ "type": "command", "command": "/path/to/session-end.sh" }]
      }
    ]
  }
}
```

- Consumer repos: shared hooks are **merged** with repo-specific hooks via `merge_hooks_json` in `sync-rules.sh` (see script comments).

**Why `hooks-cursor.json` but no `hooks-claude.json`?** The **only** shared source `sync-rules.sh` reads is [`hooks.json`](hooks.json). It lists **both** harnesses; after merge, the script writes **`.claude/hooks.json`** or **`.cursor/hooks.json`** (the normal on-disk names) and **filters** keys per target with `jq`. **[`hooks-cursor.json`](hooks-cursor.json)** is an extra **Cursor-only sample** so the camelCase / simpler schema is easy to see without reading the full union file. Claude’s entries (`SessionStart`, `PreToolUse`, `PreCompact`, …) already live in **`hooks.json`**, so a separate `hooks-claude.json` would mostly duplicate **`hooks.json`** and go stale.

### Cursor

- **Cursor** hooks use a **different** schema and event names—see [`hooks-cursor.json`](hooks-cursor.json) in this repo. Do **not** assume Claude `Stop` / `PreCompact` match 1:1.

### Expectations

- **Opt-in** and **documented** in your consumer repo; expect maintenance and product-specific behavior.

## References

- [Cursor Hooks Documentation](https://cursor.com/docs/agent/hooks)
- [Hooks Spec](https://cursor.com/docs/agent/hooks#reference)
- [Partner Integrations](https://cursor.com/docs/agent/hooks#partner-integrations)

## Contributing

To add new hooks to `mobile-cursor-rules`:

1. Add hook script to `hooks/`
2. Update `hooks/hooks.json` to include new hook
3. Document in this README
4. Test in consumer repos
