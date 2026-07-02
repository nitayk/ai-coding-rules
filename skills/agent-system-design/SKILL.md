---
name: agent-system-design
description: "Use when designing a new agentic system or evaluating whether to add agents to an existing system. Covers the full lifecycle: what to agentify, agent decomposition, tool boundaries, orchestration approach, human checkpoints, observability, and evaluation. Do NOT use for routine task execution within an already-running agentic system."
last-reviewed: 2026-05-20
---

# Agent System Design

End-to-end workflow for principled agentic system design — from scope decision through deployment readiness.

## When to Use This Skill

**APPLY WHEN:**
- Designing a new agent or multi-agent workflow from scratch
- Evaluating whether to add agents to an existing system
- Reviewing an existing agentic architecture for gaps
- Debugging non-deterministic or hard-to-explain agent behavior

**SKIP WHEN:**
- Executing tasks within an already-designed, working agentic system
- One-off automation that is fully deterministic (use scripts/cron instead)

---

## Phase 1: Decide What to Agentify

Before writing any agent code, answer these questions:

### 1.1 — Qualify the Process

Run through this checklist:

```
[ ] Does the process involve decisions with variable paths? (If no → use automation)
[ ] Does it require multi-step reasoning across heterogeneous data? (If no → use RAG/search)
[ ] Does it involve human handoffs that are high-friction today? (If no → evaluate ROI)
[ ] Is the process currently deterministic and predictable? (If yes → use automation, not agents)
```

**Rule**: Agents are for decisions. Deterministic steps belong in plain automation (cron, pipelines, scripts).

### 1.2 — Define the Business Goal

Write down:
- What concrete outcome does the agent produce?
- How will you measure success? (task completion rate, error rate, latency, human override rate)
- What does failure look like and how will you detect it?

Do not proceed without measurable success criteria.

---

## Phase 2: Decompose into Specialized Agents

### 2.1 — Identify Agent Roles

Decompose the workflow into specialized roles. Common patterns:

| Role | Responsibility |
|------|---------------|
| Orchestrator | Receives user intent, routes to sub-agents, aggregates results |
| Retrieval agent | Fetches context from knowledge bases, APIs, or graph DBs |
| Reasoning agent | Plans steps, evaluates options, makes decisions |
| Action agent | Executes tool calls against external systems |
| Validation agent | Verifies outputs before they are returned or committed |

**Do not** build one generalist agent that does all of these. Narrow specialization produces better results.

### 2.2 — Set Tool Boundaries

For each agent, enumerate its tools:

```
[ ] List all tools this agent needs
[ ] Count them — keep to ≤ 20 tools per agent
[ ] For each tool: is this the lowest-level abstraction possible?
[ ] Remove scenario-specific tools; replace with composable low-level tools
```

If tool count exceeds 20, split the agent into two specialists.

### 2.3 — Map Agent Interactions

Draw (or describe) the interaction graph:

```
User Intent
    ↓
Orchestrator
    ├── Retrieval Agent  →  Knowledge Base / Graph DB
    ├── Reasoning Agent  →  (uses retrieval results)
    └── Action Agent     →  External System
            ↓
    Validation Agent
            ↓
    Human Checkpoint (if required)
            ↓
    Output
```

---

## Phase 3: Orchestration Approach

### 3.1 — Choose Coordination Model

| Model | When to use |
|-------|------------|
| Sequential pipeline | Steps must happen in order; each step's output feeds next |
| Parallel dispatch | Independent sub-tasks; results aggregated after |
| Hierarchical (orchestrator + sub-agents) | Complex tasks with dynamic routing |
| Single agent + low-level tools | Simpler workflows; start here before adding multi-agent complexity |

**Default**: Start with a single agent + low-level tools. Add multi-agent complexity only when you've outgrown that model.

### 3.2 — Context Strategy

- Deliver context **just-in-time** alongside tool results, not all upfront in the system prompt.
- Curate — quality of context > volume of context.
- Include semantic nuances specific to your domain (e.g., terminology, known edge cases).
- Keep system prompts small; quality degrades noticeably past a few thousand tokens.

### 3.3 — Framework Selection

Use an orchestration framework rather than hand-rolling state machines (representative options as of April 2026):
- **Your LLM provider's agent SDK** — first-class model integration; tool use, memory, and multi-agent patterns built in (e.g., Anthropic Agent SDK, OpenAI Agents SDK)
- **LangGraph** — stateful, graph-based workflows; good for complex routing
- **CrewAI** — role-based multi-agent teams
- **Bedrock Agents** — if locked to AWS ecosystem

---

## Phase 4: Human Checkpoints

Define explicit human review gates before implementation.

### 4.1 — Required Checkpoints

Always require human approval for:
- Actions touching **production systems**
- **Financial transactions** or billing changes
- **Irreversible** deletions or deployments
- Publishing **external content**

### 4.2 — Checkpoint Implementation Pattern

```
agent proposes action
    → emit checkpoint event (action type, proposed params, reasoning)
    → human reviews in UI or Slack
    → human approves/rejects/modifies
    → agent executes approved action (or discards)
```

Track **human override rate** — a high rate signals the agent needs tuning, not that humans need to approve faster.

---

## Phase 5: Security and Authorization

### 5.1 — Security Checklist

```
[ ] Guardrails are in IAM policies, NOT only in prompts
[ ] Each agent has minimum required permissions (least privilege)
[ ] No agent can grant itself new permissions (no privilege escalation)
[ ] All tool calls are logged with: caller, arguments, timestamp, result
[ ] Arguments and results are sanitized before logging — strip PII, API keys, OAuth tokens, and domain-classified sensitive fields
[ ] Sensitive data is not passed through agent context unless required
[ ] Agents have been threat-modeled (what happens if the prompt is overridden?)
```

### 5.2 — Just-in-Time Authorization

Agents decide tool calls at runtime, so permissions must be evaluated per-call:
- Scope permissions to the specific task, not the agent identity
- Revoke permissions when the task completes
- Conduct offensive security exercises before production deployment

---

## Phase 6: Observability

Build instrumentation before the agent handles real traffic.

### 6.1 — What to Capture Per Turn

```
[ ] Full prompt (system + user + context injected)
[ ] Every tool call: name, arguments, result, latency
[ ] Intermediate reasoning steps
[ ] Final output
[ ] Errors, retries, fallbacks
[ ] Human checkpoint decisions (approved / rejected / modified)
```

### 6.2 — Metrics to Track

| Metric | Target | Signal when off |
|--------|--------|-----------------|
| Task completion rate | Define per use case | Agent is failing or bailing out |
| Human override rate | Define per use case | Agent decisions need tuning |
| Tool error rate | Define per use case | Tool or context issue |
| P95 latency | Define per use case | Model or tool performance |
| Context size at decision | < 50% of model max | Context bloat |

---

## Phase 7: Evaluation Before Deployment

### 7.1 — Sandbox Testing

- Test in a sandbox that mirrors production data and system behavior.
- Run a representative sample of real user intents (not just happy paths).
- Include adversarial inputs and edge cases.

### 7.2 — Evaluation Strategy

```
[ ] Define test set with known correct outputs
[ ] Human-evaluate a sample to establish ground truth
[ ] Build LLM-based judge calibrated against human evaluators
[ ] Run judge at scale — gate deployment on eval score threshold
[ ] Re-evaluate after every significant prompt or tool change
```

### 7.3 — Deployment Gate

Do not deploy until:
- Eval score meets defined threshold
- Human override rate in sandbox is acceptable
- Observability pipeline is live and tested
- Incident response runbook exists

---

## Anti-Patterns Reference

| Anti-pattern | Symptom | Fix |
|--------------|---------|-----|
| Mega-agent with all tools | Slow, inconsistent, hard to debug | Split into specialists |
| Guardrails only in prompts | Agent bypassed by adversarial input | Move to IAM policies |
| Scenario-specific tools | Brittle, doesn't generalize | Build low-level abstractions |
| No observability | Cannot explain failures | Add tracing before launch |
| Skip human checkpoints | Agent causes production incident | Add approval gates |
| Deploy without eval | Unknown failure rate | Eval first, deploy second |

---

## Related

- `/dispatching-parallel-agents` — Coordinating concurrent agents
- `/session-memory` — Persistent context across agent sessions
- `/multi-agent-branching` — Branch isolation for concurrent agents
- `/writing-plans` — Phase-ready planning before implementation

<!-- Cross-platform: see AGENTS.md in the repository root for deployment details. -->
