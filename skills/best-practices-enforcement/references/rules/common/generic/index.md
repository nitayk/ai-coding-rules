# Generic Development Rules Index

**📖 Navigation Guide**: Use this to discover generic rules. The actual rules load automatically when you work with code files.

Universal best practices that apply across **all languages and platforms** (backend, frontend, mobile).

**Load manually** with `references/rules/common/generic/index.md` to browse rules. Generic rules provide universal principles; language rules add implementation details.

**Graph Structure**: This is a Layer 2 node that routes directly to Layer 0 leaves (rule files) or Layer 1 nodes (communication subcategory) based on keywords. Hybrid: flattened for single-file categories, subcategory kept for communication (3 files).

---

## Building Blocks Principle

| Layer | Role | Example |
|-------|------|---------|
| **generic/** | Foundation — universal principles for all code | SOLID, fail fast, trust boundaries, guard clauses |
| **backend/** | Implementation — HOW to apply generic in Go, Python, Scala, Java, PHP | Option/Either/Try, sealed traits, type classes |
| **frontend/** | Implementation — HOW to apply generic in JS/TS | async/await, type narrowing, React patterns |
| **mobile/** | Implementation — HOW to apply generic in Kotlin, Swift, Obj-C | Coroutines, null safety, MVVM |
| **tools/** | CLI building blocks — commands used by technologies and skills | curl, jq, git, docker, kcat, kubectl, aws-cli, gcloud, ripgrep, yq, terraform, helm |
| **technologies/** | MCP/API building blocks — reference guides for platforms | Kafka, Trino, Grafana, ArgoCD, VictoriaMetrics, Druid, AWS, Gotenberg, Schema Registry |

**Avoid duplication**: Language-specific rules **reference** generic; they do **not** restate principles. Use `[Generic X](../../generic/...)` links. Technologies **reference** tools for CLI operations.

**Negative pattern**: Restating "fail fast" or "SOLID" in a Scala rule. **Positive pattern**: "See [Generic Error Handling](../../generic/error-handling/universal-patterns.md); this file adds Scala Option/Either/Try patterns."

---

## Keyword → File/Subcategory Routing

| Keywords/Intent | Load File or Subcategory Index |
|----------------|-------------------------------|
| **build**, **refactor**, **migrate**, **implement**, **create** | `smart-gates.md` (clarification gate) |
| **debug**, **fix**, **error**, **bug**, **broken** | `smart-gates.md` (debug protocol) |
| **continue**, **resume**, **remember**, **context** | `smart-gates.md` (session memory) |
| **communication**, business logic, tool communication, prompt engineering | `references/rules/common/generic/communication/index.md` |
| **code quality**, solid, dry, kiss, yagni, clean code | `code-quality/core-principles.md` |
| **architecture**, design patterns, separation of concerns | `architecture/core-principles.md` |
| **testing**, test patterns, unit testing, integration testing | `testing/core-principles.md` |
| **performance**, performance optimization, profiling | `performance/core-principles.md` |
| **security**, security best practices, input validation | `security/core-principles.md` |
| **debugging**, debug, troubleshooting, investigate bug | `debugging/strategies.md` |
| **defensive programming**, trust boundaries, API validation, external data | `defensive-programming/trust-boundaries.md` |
| **guard clauses**, early return, reduce nesting | `control-flow/guard-clauses.md` |
| **error handling**, error patterns, fail fast, explicit errors | `error-handling/universal-patterns.md` |
| **interface design**, small interfaces, ISP, composition | `architecture/interface-design.md` |
| **silent failure**, silent failure check | `error-handling/silent-failure-check.md` |
| **memory**, session memory, active context, continue resume | `memory-interface.md` |
| **token control**, long build, redirect output, verbose command | `agent-behavior/token-control.md` |
| **context window**, compaction drift, phase split, intermediate artifacts | `agent-behavior/context-management.md` |
| **helper tools**, small automation, narrowly scoped script | `agent-behavior/helper-tools-first.md` |
| **semantic analysis**, code analysis, modality detection | `analysis/semantic-code-analysis-patterns.md` |
| **git**, git staging, git workflow, commit best practices | `git/git-staging-guidelines.md` |
| **git workflow**, branching, PRs, merge, force push | `git/git-workflow-guidelines.md` |

---

## 📚 Available Rules

### Code Quality (`generic/code-quality/`)
- **[Core Principles](code-quality/core-principles.md)** - Boy Scout Rule, SOLID, DRY, KISS, YAGNI, correctness first, make illegal states unrepresentable, pure functions, meaningful comments

### Error Handling (`generic/error-handling/`)
- **[Universal Patterns](error-handling/universal-patterns.md)** - Fail fast, explicit errors, proper propagation

### Testing (`generic/testing/`)
- **[Core Principles](testing/core-principles.md)** - Test behavior not implementation, AAA pattern, isolation

### Performance (`generic/performance/`)
- **[Core Principles](performance/core-principles.md)** - Measure first, optimize bottlenecks, avoid premature optimization

### Security (`generic/security/`)
- **[Core Principles](security/core-principles.md)** - Input validation, least privilege, defense in depth

### Debugging (`generic/debugging/`)
- **[Strategies](debugging/strategies.md)** - Reproduce, isolate, hypothesis-driven investigation

### Architecture (`generic/architecture/`)
- **[Core Principles](architecture/core-principles.md)** - Interface-centric design, separation of concerns, dependency injection
- **[Interface Design](architecture/interface-design.md)** - Small interfaces, composition, accept-interface-return-concrete

### Defensive Programming (`generic/defensive-programming/`)
- **[Trust Boundaries](defensive-programming/trust-boundaries.md)** - Validate external data at boundaries, schema evolution, safe access

### Control Flow (`generic/control-flow/`)
- **[Guard Clauses](control-flow/guard-clauses.md)** - Early returns, reduce nesting, happy-path emphasis

### Communication (`generic/communication/`)
**Load**: `references/rules/common/generic/communication/index.md` ← Points to specific communication pattern files
- **[Business Communication Standards](communication/business-communication-standards.md)** - BLUF format for business logic explanations
- **[Tool Communication Pattern](communication/tool-communication-pattern.md)** - How to explain MCP tools to users
- **[Prompt Engineering Principles](communication/prompt-engineering-principles.md)** - LLM prompt optimization techniques, architecture awareness, task-specific strategies

### Analysis (`generic/analysis/`)
- **[Semantic Code Analysis Patterns](analysis/semantic-code-analysis-patterns.md)** - Modality detection, downstream deception

### Agent Behavior (`generic/agent-behavior/`)
- **[Critical Rules](agent-behavior/critical-rules.md)** - Always apply: verify before claiming, 100% means 100%, no temp files
- **[Anti-Hallucination](agent-behavior/anti-hallucination.md)** - Techniques to prevent and detect hallucinations
- **[Token Control](agent-behavior/token-control.md)** - Redirect long output to file; prefer git grep for large codebases
- **[Index](agent-behavior/index.md)** - Agent behavior guidelines

### Git (`generic/git/`)
- **[Git Staging Guidelines](git/git-staging-guidelines.md)** - Staging workflow, commit best practices
- **[Git Workflow Guidelines](git/git-workflow-guidelines.md)** - Branching, PRs, merge, force push

---


## 🔍 Quick Reference

| Need | Rule |
|------|------|
| Writing clean code | `code-quality/core-principles.md` |
| Designing architecture | `architecture/core-principles.md` |
| Handling errors | `error-handling/universal-patterns.md` |
| Writing tests | `testing/core-principles.md` |
| Optimizing performance | `performance/core-principles.md` |
| Security concerns | `security/core-principles.md` |
| Debugging issues | `debugging/strategies.md` |
| Handling API/external data | `defensive-programming/trust-boundaries.md` |
| Reducing nested conditionals | `control-flow/guard-clauses.md` |
| Designing interfaces | `architecture/interface-design.md` |
| Explaining business logic | `communication/business-communication-standards.md` |
| Optimizing LLM prompts | `communication/prompt-engineering-principles.md` |
| Git workflow | `git/git-staging-guidelines.md` or `git/git-workflow-guidelines.md` |

---

## 📝 Contributing

When adding new generic rules:
1. Place in appropriate subdirectory (`code-quality/`, `testing/`, etc.)
2. Follow format from `meta/cursor-rules-style-guide.md`
3. Ensure rule applies universally (not language-specific)
4. Update this index
5. Update `index.md` in root (complete catalog)

When adding language-specific rules (backend/, frontend/, mobile/):
1. **Reference generic** — Add `[Generic X](../../generic/...)` link; do not restate the principle
2. **Add implementation only** — Language-specific syntax, patterns, idioms
3. **Check for existing generic** — If it applies to all languages, it belongs in generic/

When adding tools or technologies:
1. **tools/** — CLI building blocks (curl, jq, kubectl). Add to `tools/index.md` and ROUTER.
2. **technologies/** — MCP/API reference guides (Kafka, Trino, Grafana). Reference tools for CLI ops. Add to `technologies/index.md` and ROUTER.

---

## 🔗 Related Resources

- **Language-specific rules**: See `backend/`, `frontend/`, `mobile/` directories
- **Tools** (`tools/`): CLI building blocks — curl, jq, git, docker, kcat, kubectl, aws-cli, gcloud, ripgrep, yq, terraform, helm
- **Technologies** (`technologies/`): MCP/API guides — Kafka, Trino, Grafana, ArgoCD, VictoriaTraces, VictoriaMetrics, Druid, AWS, Gotenberg, Schema Registry
- **Investigation**: combine tools + technologies for code-structure and service-breakdown analysis
- **Skills & Workflows**: See `skills/` directory for procedural workflows
- **Style guide**: See `meta/cursor-rules-style-guide.md`
- **Router**: See `ROUTER.md` for intent-based rule loading

<!-- Cross-platform: see AGENTS.md in the repository root for deployment details. -->
