# Agent Composition Patterns

**Purpose**: Guide principled design of agentic systems — from deciding what to agentify through orchestration, observability, and human oversight.

## Triggers

**APPLY WHEN:** Designing a new agent, multi-agent workflow, or reviewing an existing agentic architecture.
**SKIP WHEN:** Routine task execution within an already-designed agentic system.

---

## 1. Decide What to Agentify

Not every process benefits from an agent. Agentify only when the process has one of these properties:

| Property | Example | Agent value |
|----------|---------|-------------|
| High friction & repetitive human handoffs | Incident triage, onboarding | High |
| Requires multi-step reasoning with variable paths | Root-cause analysis | High |
| Deterministic, predictable steps | Scheduled ETL, cron jobs | Low — use automation, not agents |
| Stateless Q&A without tool use | FAQ lookup | Low — use RAG or search, not agents |

**Rule**: MCP and agents are overkill for repetitive, deterministic automation. Codify deterministic steps as plain automation; reserve agents for decisions.

---

## 2. Specialize, Don't Generalize

Agents work best as specialists, not generalists.

- **Do**: Compose narrow agents (reasoning, retrieval, action, validation) with clear responsibilities.
- **Don't**: Build one mega-agent that handles everything.
- **Tool boundary**: Keep tools per agent to **≤ 20 tools**. 20–50 becomes unwieldy; > 50 degrades decision quality.
- **Do**: Prefer a sub-agent architecture with low-level tools and an orchestrator that translates natural language to that abstraction level.
- **Don't**: Build tools scenario-by-scenario. Build low-level abstractions first, then teach agents to use them.

---

## 3. Context: Quality Over Volume

> "Quality of output is directly tied to quality of context."

- **Minimal, relevant data**: Curate context rather than dumping everything. Overloaded system prompts degrade performance.
- **Progressive disclosure**: Deliver context just-in-time alongside tool results, not all upfront.
- **Semantic nuances**: Ensure agents understand domain-specific terminology (e.g., "impression" vs. "view" in ad systems).
- **Don't**: Overload system prompts with excessive context hoping the model will filter.

See also: `context-management.md` for session-level context limits.

---

## 4. Human Checkpoints by Design

Default to **human-in-the-loop**, not the other way around.

**Require human approval before:**
- Actions touching production systems
- Financial transactions or billing changes
- Irreversible deletions or deployments
- Publishing content externally

**Implementation pattern:**
```
agent proposes action → human reviews → human approves → agent executes
```

Autonomous escalation (skipping the review) must be explicitly opt-in and time-bounded.

---

## 5. Security Is Infrastructure, Not Prompt

- Guardrails belong in **identity/access management policies**, not just in prompts. A prompt can be overridden; an IAM policy cannot.
- Apply **just-in-time authorization** — agents decide tool calls at runtime, so permissions must be scoped to what is needed for each specific task.
- Prevent **privilege escalation**: agents should not be able to grant themselves new permissions.
- Maintain **audit logs** of every tool call, intermediate decision, and final output.
- Conduct **offensive security exercises** before deploying agents that touch production systems.

---

## 6. Observability from Day One

Build observability in before agents go to production — retrofitting is expensive.

**What to capture for every agent turn:**
- The prompt sent (with context)
- Every tool call made and its arguments
- Intermediate reasoning steps
- Final output
- Any errors, retries, or fallbacks

**Why agents fail** should be answerable from logs alone. If you cannot explain a failure from logs, your observability is insufficient.

**Metrics to track:**
- Tool call success/failure rates per agent
- Context size at decision points
- Human override rate (high rate = agent needs tuning)
- Task completion rate vs. human-escalation rate

---

## 7. Evaluation Before Deployment

- Test agents in a **sandbox** that mirrors production behavior.
- Use **LLM-based judges** calibrated against human evaluators — once judges reliably match humans, trust them at scale.
- Define **success criteria** upfront (task completion rate, error rate, latency).
- **Treat agents like regulated systems**: do not deploy without documented eval results.

---

## Anti-Patterns

| Anti-pattern | Why it fails |
|--------------|-------------|
| Stateless chatbot design | Agents need memory to complete multi-step tasks |
| Guardrails only in prompts | Prompts can be overridden; IAM policies cannot |
| One agent, all tools | Decision quality degrades with tool count |
| Build tools per scenario | Creates fragile, narrow abstractions |
| Observability as afterthought | Cannot debug or improve without traces |
| Replace humans overnight | Trust is built incrementally; start with human checkpoints |

---

## Related

- `context-management.md` — Context window limits and phase splitting
- `critical-rules.md` — Verification and quality standards
- `/dispatching-parallel-agents` skill — Coordinating concurrent agents
- `/agent-system-design` skill — Full lifecycle workflow for designing agentic systems

<!-- Cross-platform: see AGENTS.md in the repository root for deployment details. -->
