# Scala Architecture Patterns Index

**Purpose**: Router for Scala architecture patterns - detects keywords and routes to specific pattern files.

**Chaining**: Router → Category Index → Language Index → This Index (Router) → Files

**Graph Structure**: This is a Layer 1 node that routes to Layer 0 leaves (rule files) based on keywords.

---

## Keyword → File Routing

| Keywords/Intent | Load File |
|----------------|-----------|
| **architecture**, structural guidelines, clean architecture, core structure | `core-structural-guidelines.md` |
| **trait composition**, mixins, traits, trait patterns | `trait-composition-patterns.md` |
| **facade**, functional integration, facade patterns | `functional-integration-in-facade.md` |
| **shared library**, library development, shared libraries | `shared-library-development-patterns.md` |
| **builder pattern**, functional construction, builder preferences | `builder-pattern-preferences.md` |

---

## Architecture Pattern Files (Leaves)

| File | Purpose | Keywords |
|------|---------|----------|
| [Core Structural Guidelines](core-structural-guidelines.md) | Foundation guidelines for clean, maintainable architecture | architecture, structural guidelines, clean architecture |
| [Trait Composition Patterns](trait-composition-patterns.md) | Trait composition and mixin strategies | trait composition, mixins, traits |
| [Functional Integration in Facade](functional-integration-in-facade.md) | Functional integration patterns in facade design | facade, functional integration |
| [Shared Library Development Patterns](shared-library-development-patterns.md) | Best practices for developing shared libraries | shared libraries, library development |
| [Builder Pattern Preferences](builder-pattern-preferences.md) | Prefer functional construction over traditional builders | builder pattern, functional construction |

---

## Quick Reference

| Need | Load |
|------|------|
| Architecture guidelines | `core-structural-guidelines.md` |
| Trait composition | `trait-composition-patterns.md` |
| Facade patterns | `functional-integration-in-facade.md` |
| Shared libraries | `shared-library-development-patterns.md` |
| Construction patterns | `builder-pattern-preferences.md` |

---

## Related Resources

- **Language**: See `../language/index.md` for language patterns
- **Data**: See `../data/index.md` for data handling patterns
- **Testing**: See `../testing/index.md` for testing patterns

<!-- Cross-platform: see AGENTS.md in the repository root for deployment details. -->
