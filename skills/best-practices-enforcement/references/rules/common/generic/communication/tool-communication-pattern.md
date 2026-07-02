# Tool Communication Pattern

## 🎯 Core Principle

**When using MCP tools, always explain them to users first!**

This helps users understand the ecosystem, set up their own tools, and know what's available.

## 📋 Pattern to Follow

```
To [task], I'll use the [Tool Name] MCP tool (`mcp_tool_name`).
According to [guide-file.md], this tool [brief explanation].

[Then proceed with using the tool]
```

## ✅ Good Examples

### Example 1: A code-graph MCP (Code Analysis)
```
To understand this service structure, I'll use a **code-graph MCP** (`mcp_<tool>_run_query`)
FIRST, before reading individual code files — it shows relationships, call chains, and helps
identify dead code.

This is a HEAVY task that may require dozens of queries across several phases:
- Phase 1: Broad discovery
- Phase 2: Deep recursive analysis
- Phase 3: Targeted deep dives
- Phase 4: Verification

Let me start Phase 1 - finding all classes in this service:

[Run query]
MATCH (c:Class)
WHERE c.qualified_name CONTAINS 'my-service'
RETURN c.name, c.path, c.qualified_name

[Continue with remaining Phase 1 queries...]
```

**🚨 CRITICAL**:
- For structural analysis, a code-graph tool (if available) is a strong Step 0
- Expect many queries for a real service, not just a handful
- Use DEEP RECURSIVE queries where the graph supports them

### Example 2: A data-validation MCP (Data Validation)
```
To validate data in the `device_installs` table, I'll use a **data-validation MCP**
(`mcp_<tool>_execute_query`), which lets us query Iceberg/Hive tables directly
for data validation.

Let me run some validation queries...
```

### Example 3: A metrics MCP (Monitoring)
```
To check if metrics are being recorded correctly, I'll use a **metrics MCP**,
which provides access to dashboards and PromQL queries for monitoring validation.

Let me search for the relevant dashboard...
```

## ❌ Bad Examples (Don't Do This)

### Example 1: Silent Tool Usage
```
❌ [Just runs code-graph queries without mentioning the tool]
❌ [Provides SQL results without explaining the data-validation tool]
```

**Why bad?** User doesn't learn about available tools.

### Example 2: Over-explaining Every Call
```
❌ "Using the code-graph tool again..." (for 10th query in same conversation)
```

**Why bad?** Repetitive and annoying after the first explanation.

## 🎯 When to Explain

- ✅ **First time using a tool** in a conversation
- ✅ **When user seems unfamiliar** with the tool
- ✅ **When switching to a different tool**
- ❌ **Not for every single query** in the same conversation

## 🔗 Available Tools & Guides

| Tool | MCP Name | Purpose |
|------|----------|---------|
| Code-graph MCP | `mcp_<tool>_run_query` | Code structure analysis |
| Topology MCP | `mcp_<tool>_*` | Runtime topology (Kafka, Aerospike, service deps) |
| Data-validation MCP | `mcp_<tool>_execute_query` | Query Iceberg/Hive tables |
| Metrics MCP | `mcp_<tool>_*` | Monitoring & dashboards |
| Context7 | `mcp_context7_*` | Library/API documentation |

## Context7 Tool Usage

**When to use Context7** (`mcp_context7_*`):
- User requests code examples, setup, or configuration steps
- User asks for library/API documentation
- Suggesting environment variables, CLI flags, or configuration options for external tools/libraries

**Always verify** configuration options exist before suggesting them (see `ROUTER.md` quality standards).

**Tool call patterns**:
```
[[calls]]
match = "when the user requests code examples, setup or configuration steps, or library/API documentation"
tool  = "context7"

[[calls]]
match = "when suggesting environment variables, CLI flags, or configuration options for external tools/libraries"
tool  = "context7"
```

## 💡 Why This Matters

1. **Users learn the ecosystem** - They discover what tools are available
2. **Users can set up tools** - They know what to configure in `.cursor/mcp.json`
3. **Better collaboration** - Teams share understanding of tooling
4. **Self-service** - Users can use tools independently after learning

## 🚀 Setup Reference

Point users to:
- **MCP Setup Guide**: `mcp/complete-guide.md`
- **Example Configuration**: `mcp/example-config.json`
- **Smart Router**: `ROUTER.md` (auto-loads, detects intent and loads guides)

## Related Rules

- [Prompt Engineering Principles](prompt-engineering-principles.md) - Techniques for optimizing LLM prompts and understanding architecture limitations
- [Business Communication Standards](business-communication-standards.md) - BLUF format for business explanations

---

**Remember: Be an educational guide, not a silent worker!**

<!-- Cross-platform: see AGENTS.md in this repository for Cursor, Claude Code, and Copilot paths. -->
