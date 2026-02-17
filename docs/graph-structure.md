# Rules Graph Structure

## Graph Model

The rules system is structured as a **directed graph** where:
- **Leaves (Layer 0)**: Actual rule files, skills, subagents, commands, hooks
- **Router Nodes (Layer 1+)**: Index files that detect keywords and route to child nodes or leaves

---

## Graph Layers - Hybrid Structure

**Hybrid Approach**: Large categories use subcategories (3 hops), small categories route directly to files (2 hops).

### Layer 3: Root Router
- **Node**: `ROUTER.mdc`
- **Function**: Detects top-level keywords → routes to Layer 2 category indexes
- **Routes to**: `backend/index.mdc`, `frontend/index.mdc`, `mobile/index.mdc`, `generic/index.mdc`, `tools/index.mdc`

### Layer 2: Category & Language Indexes
- **Category Nodes**: `backend/index.mdc`, `frontend/index.mdc`, `mobile/index.mdc`, `generic/index.mdc`, etc.
- **Language Nodes**: `backend/scala/index.mdc`, `backend/go/index.mdc`, `mobile/kotlin/index.mdc`, etc.
- **Function**: 
  - **Large languages** (Scala, Python, JS/TS): Routes to Layer 1 subcategory indexes
  - **Small languages** (Go, Java, PHP, Kotlin, Swift, Obj-C): Routes directly to Layer 0 files
- **Example (Large)**: `backend/scala/index.mdc` detects "language" → routes to `backend/scala/language/index.mdc`
- **Example (Small)**: `backend/go/index.mdc` detects "error handling" → routes directly to `language/error-handling-patterns.mdc`

### Layer 1: Subcategory Indexes (Only for Large Categories)
- **Nodes**: Subcategory indexes (`backend/scala/language/index.mdc`, `backend/scala/architecture/index.mdc`, etc.)
- **Function**: Detects specific pattern keywords → routes to Layer 0 rule files
- **Example**: `backend/scala/language/index.mdc` detects "error handling" → routes to `error-handling-patterns.mdc`
- **Note**: Only exists for large categories (Scala, Python, JS/TS). Small categories skip this layer.

### Layer 0: Leaves (Rule Files)
- **Nodes**: Actual `.mdc` rule files, `SKILL.md` files, subagent `.md` files, command `.md` files, hooks
- **Function**: Contains actual content (rules, skills, commands, etc.)
- **Examples**: `error-handling-patterns.mdc`, `service-breakdown/SKILL.md`, `test-runner.md`, `create-pr.md`

---

## Keyword Routing Pattern

Each router node (index) follows this pattern:

```markdown
## Keyword → Child Routing

| Keywords/Intent | Load Child Node/Leaf |
|----------------|---------------------|
| **keyword1**, keyword2, keyword3 | `child-node/index.mdc` or `file.mdc` |
```

**Routing Logic**:
1. Index detects keywords in user prompt
2. Matches keywords to routing table
3. Loads appropriate child index or file
4. Child index repeats process until reaching leaf

---

## Example Flows

### Large Category Flow (3 hops)
**User says: "scala error handling"**

```
Layer 3: ROUTER.mdc
  ↓ detects "scala"
Layer 2: backend/index.mdc
  ↓ detects "scala" 
Layer 2: backend/scala/index.mdc
  ↓ detects "error handling" or "language"
Layer 1: backend/scala/language/index.mdc
  ↓ detects "error handling"
Layer 0: error-handling-patterns.mdc (LEAF - actual content)
```

### Small Category Flow (2 hops)
**User says: "go error handling"**

```
Layer 3: ROUTER.mdc
  ↓ detects "go"
Layer 2: backend/index.mdc
  ↓ detects "go"
Layer 2: backend/go/index.mdc
  ↓ detects "error handling"
Layer 0: language/error-handling-patterns.mdc (LEAF - actual content)
```

**Benefits**: Faster routing for small categories, organized structure for large categories.

---

## Graph Properties

- **Directed**: Routes flow from root to leaves
- **Acyclic**: No circular dependencies
- **Hierarchical**: Clear parent-child relationships
- **Keyword-driven**: Each node routes based on keyword detection
- **Progressive disclosure**: Only loads what's needed based on keywords

---

## Node Types

### Router Nodes (Indexes)
- Have `Keyword → Child Routing` section
- Detect keywords and route to children
- Can route to other indexes (Layer N → Layer N-1) or directly to files (Layer N → Layer 0)

### Leaf Nodes (Files)
- Contain actual content
- No routing - they are endpoints
- Types: `.mdc` rules, `SKILL.md`, subagent `.md`, command `.md`, hooks

---

## Benefits

1. **Scalable**: Easy to add new nodes at any layer
2. **Discoverable**: Keywords make it easy to find relevant rules
3. **Efficient**: Only loads what's needed based on keywords
4. **Hybrid Optimization**: Fast routing (2 hops) for small categories, organized structure (3 hops) for large categories
5. **Maintainable**: Clear hierarchy makes it easy to understand and update
6. **Flexible**: Can flatten or add subcategories as categories grow/shrink

## Category Classification

**Large Categories** (use subcategories - 3 hops):
- Scala (30+ rules)
- Python (moderate, multiple subcategories)
- JavaScript/TypeScript (frameworks, language, testing)

**Small Categories** (flattened - 2 hops):
- Go (8 rules)
- Java (2 rules)
- PHP (1 rule)
- Kotlin (4 rules)
- Swift (4 rules)
- Objective-C (3 rules)
- Generic (mostly single-file categories, communication has 3 files)
