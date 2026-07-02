# `buf lint` in CI

`buf lint` is the enforceable counterpart to the Buf Style Guide. Anything the style guide says is enforced by exactly one of the categories — `MINIMAL`, `BASIC`, `STANDARD` (the default), or `DEFAULT` (alias for STANDARD). Run STANDARD on every PR. The cost is a few hundred milliseconds; the value is that every schema in the repo conforms to the same conventions without human review.

Source: [Buf Docs — Lint](https://buf.build/docs/), [Buf Style Guide](https://buf.build/docs/best-practices/style-guide/).

---

## The CI step

```yaml
# .github/workflows/proto.yml
jobs:
  buf-lint:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
      - uses: bufbuild/buf-setup-action@v1
      - run: buf lint
```

That's it. The category and the file scope live in `buf.yaml`.

---

## `buf.yaml`

```yaml
# buf.yaml
version: v2
modules:
  - path: proto
lint:
  use:
    - STANDARD
  # except: optional list of rule IDs to disable (rare; document why)
breaking:
  use:
    - FILE
```

`STANDARD` is a superset of `BASIC` is a superset of `MINIMAL`. They all enforce the file/message/field/enum naming rules; STANDARD adds the API-design rules (RPC request/response uniqueness, version suffix on packages, `Service` suffix on services, no `google.protobuf.Empty` in RPCs).

---

## Which category?

| Category | Rules count (approximate) | When |
|---|---|---|
| `MINIMAL` | ~15 | Legacy repos being incrementally adopted |
| `BASIC` | ~25 | Naming/layout only; no API-design enforcement |
| `STANDARD` (default) | ~40 | **Recommended baseline for all new schemas** |
| `COMMENTS` | comment-enforcement add-on | Public APIs where doc comments must exist on every type |

For `apis`: STANDARD. For a brand-new repo, also add `COMMENTS` if the schema is intended for external consumers and you want every public message documented.

```yaml
# buf.yaml — STANDARD + comment enforcement
lint:
  use:
    - STANDARD
    - COMMENTS
```

---

## A representative slice of what STANDARD catches

| Rule ID | What it catches |
|---|---|
| `PACKAGE_VERSION_SUFFIX` | Package without a `v1` / `v1beta1` / `v2` suffix |
| `RPC_REQUEST_STANDARD_NAME` | RPC request not named `<Rpc>Request` |
| `RPC_RESPONSE_STANDARD_NAME` | RPC response not named `<Rpc>Response` |
| `RPC_REQUEST_RESPONSE_UNIQUE` | Two RPCs sharing a request/response type |
| `SERVICE_SUFFIX` | Service name doesn't end in `Service` |
| `ENUM_VALUE_PREFIX` | Enum value not prefixed with the enum name |
| `ENUM_ZERO_VALUE_SUFFIX` | Enum zero value not named `*_UNSPECIFIED` |
| `FIELD_LOWER_SNAKE_CASE` | Field name not snake_case |
| `MESSAGE_PASCAL_CASE` | Message name not PascalCase |
| `FILE_LOWER_SNAKE_CASE` | File name not snake_case |
| `PACKAGE_LOWER_SNAKE_CASE` | Package not all-lowercase |
| `IMPORT_NO_PUBLIC` | `public` imports (deprecated) |

Every entry is mechanically checked; you cannot ship a STANDARD-passing schema with the wrong file casing.

---

## Exemptions: per-rule and per-path

Sometimes you have a legitimately-grandfathered file that can't move to a new package. Disable the specific rule for that path; never disable the whole category.

```yaml
lint:
  use:
    - STANDARD
  except:
    - PACKAGE_VERSION_SUFFIX
  ignore_only:
    PACKAGE_VERSION_SUFFIX:
      - legacy/no_version_package.proto   # grandfathered 2024-Q2; do not add new files
```

Every exemption has:

1. A path (not a wildcard wider than you need).
2. A comment explaining why and when it's expected to go away.

A wide-open `except: [STANDARD]` is the same as not running `buf lint`. Reject it in code review.

---

## Local runs

```bash
buf lint                  # all modules
buf lint proto/v1/        # one directory
buf lint --error-format=json | jq    # machine-readable for editors
```

Buf integrates with most editors (VS Code, GoLand) via LSP — set that up so contributors get the same feedback before pushing.

---

## What `buf lint` does NOT catch

`buf lint` is style and design enforcement; it does not catch:

- **Wire-compat breaks** — that's `buf breaking`'s job. See `buf-breaking-against-main.md`.
- **Validation correctness** — that's `protovalidate`'s job. See `../validation/protovalidate-over-pgv.md`.
- **Higher-level AIP design issues** (resource naming hierarchy, pagination conventions) — use [api-linter](https://linter.aip.dev) alongside Buf for AIP enforcement.

Run all three. They are complementary, not overlapping.

---

## Pre-commit hook

Catch failures before they reach CI:

```yaml
# .pre-commit-config.yaml
repos:
  - repo: https://github.com/bufbuild/buf
    rev: v1.50.0   # pin a real version
    hooks:
      - id: buf-lint
      - id: buf-format
```

---

## Related Rules

- [buf breaking against main](buf-breaking-against-main.md) — the wire-compat sibling
- [buf format pre-commit](buf-format-precommit.md) — the formatter
- [Naming and Layout](../schema/naming-and-layout.md) — the rules `buf lint` is enforcing

---

## References

- [Buf Docs](https://buf.build/docs/)
- [Buf Style Guide](https://buf.build/docs/best-practices/style-guide/)

<!-- Cross-platform: see AGENTS.md in the repository root for Cursor, Claude Code, and Copilot paths. -->
