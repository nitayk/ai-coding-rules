# Communication Patterns Index

**Purpose**: Router for communication patterns - detects keywords and routes to specific pattern files.

**Chaining**: Router → Category Index → This Index (Router) → Files

**Graph Structure**: This is a Layer 1 node that routes to Layer 0 leaves (rule files) based on keywords.

---

## Keyword → File Routing

| Keywords/Intent | Load File |
|----------------|-----------|
| **business logic**, how is X calculated, business communication, BLUF | `business-communication-standards.md` |
| **communication standards**, BLUF, evidence-based, tool education | `communication-standards.md` |
| **explain tool**, how to use MCP, tool communication, MCP tools | `tool-communication-pattern.md` |
| **prompt engineering**, optimize prompts, llm techniques, prompt optimization | `prompt-engineering-principles.md` |
| **advanced prompting**, chain of thought, few-shot, reasoning | `advanced-prompting.md` |

---

## Communication Pattern Files (Leaves)

| File | Purpose | Keywords |
|------|---------|----------|
| [Business Communication Standards](business-communication-standards.md) | BLUF format for business logic explanations | business logic, how is X calculated, business communication |
| [Communication Standards](communication-standards.md) | BLUF, evidence-based answers, tool education | communication standards, BLUF, evidence-based |
| [Tool Communication Pattern](tool-communication-pattern.md) | How to explain MCP tools to users | explain tool, how to use MCP, tool communication |
| [Prompt Engineering Principles](prompt-engineering-principles.md) | LLM prompt optimization techniques | prompt engineering, optimize prompts, llm techniques |

---

## Quick Reference

| Need | Load |
|------|------|
| Business logic explanation | `business-communication-standards.md` |
| Tool explanation | `tool-communication-pattern.md` |
| Prompt optimization | `prompt-engineering-principles.md` |

---

## Related Resources

- **Generic Index**: See `../index.md` for all generic rules

<!-- Cross-platform: see AGENTS.md in the repository root for deployment details. -->
