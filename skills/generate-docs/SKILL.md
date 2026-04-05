---
name: generate-docs
description: "Use when generating or updating documentation for code changes. Creates JSDoc, README, API docs. Make sure to use when user says: generate docs, /docs, document my changes, add documentation, or update README."
disable-model-invocation: true
---
# Generate Documentation

Generate or update documentation for recent changes.

## When to Use This Skill

**APPLY WHEN:**
- User wants documentation for recent changes
- User says "generate docs", "/docs", "document my changes"
- Before creating PR (document new APIs, README updates)

**SKIP WHEN:**
- No code changes to document
- User wants to write docs manually

## Core Directive

**Analyze changes → Identify what needs docs → Generate following project conventions (JSDoc, README, API).**

## Usage

```
/docs [path-or-pattern]
```

## Process

1. Analyzes recent changes (git diff or specified files)
2. Identifies what needs documentation:
   - New functions/classes
   - API changes
   - Configuration updates
   - Breaking changes
3. Generates documentation following project conventions:
   - JSDoc/TSDoc for code
   - README updates
   - API documentation
   - Migration guides for breaking changes
4. Updates existing docs or creates new files as needed

## Examples

```
/docs
```

Document all recent changes.

```
/docs src/api/
```

Document changes in the API directory.

```
/docs README.md
```

Update README based on recent changes.

## Documentation Types

- **Code Comments**: JSDoc, TSDoc, docstrings
- **README**: Usage examples, installation, getting started
- **API Docs**: Endpoints, parameters, responses
- **Migration Guides**: Breaking changes, upgrade paths
- **Architecture Docs**: High-level design decisions

## Best Practices

- Run after implementing features
- Use before creating PRs
- Follow existing documentation style
- Include examples for public APIs
