# `buf breaking` Against `main`

**This is the single most important rule in `rules/proto/`.** Every other rule in here is style or pattern guidance — a human reviewer can recover from a missed lint. `buf breaking` catches the changes that silently corrupt every persisted message, every Kafka topic, and every generated client in production: renumbered fields, reused field numbers, deleted enum values, swapped types. None of those are caught by code review. `buf breaking` catches all of them, in a few seconds, with one CI step.

In a shared-schema setup: `apis` is consumed by every Go backend in the org. A single accidental breaking change blast-radiuses across the whole product. Wire this rule into `apis`'s CI before anything else in this directory.

Sources: [Buf Breaking Change Rules](https://buf.build/docs/breaking/rules/), [Buf Docs](https://buf.build/docs/).

---

## The CI step

```yaml
# .github/workflows/proto.yml — minimum viable wiring
name: proto
on:
  pull_request:
    paths:
      - '**/*.proto'
      - 'buf.yaml'
      - 'buf.gen.yaml'
      - 'buf.lock'

jobs:
  buf-breaking:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
        with:
          fetch-depth: 0   # buf breaking needs the base ref
      - uses: bufbuild/buf-setup-action@v1
      - name: buf breaking against main
        run: |
          buf breaking --against "https://github.com/${{ github.repository }}.git#branch=main"
```

This is the whole rule. Don't gate it on a label, don't make it advisory — make it required-to-merge.

---

## Which tier?

`buf breaking` ships four tiers, ordered from strictest to loosest:

| Tier | Catches | Use for |
|---|---|---|
| `FILE` (default) | Anything that could break **source-code-level** compatibility (renames, file moves, package changes) plus everything below | Stable internal APIs (default; recommended start) |
| `PACKAGE` | Same as FILE but allowing file-level moves within a package | When you actively reorganise files but not packages |
| `WIRE_JSON` | Only changes that break wire-format or JSON-mapping compatibility | Public APIs where source-incompatible source refactors are acceptable |
| `WIRE` | Only wire-format breakage (rename a field → fine because the number is the same) | Public binary-only APIs |

**Start at `FILE`** for `apis`. It's the strictest, catches the most, and the few false positives (legitimate renames) are easier to handle case-by-case than the false negatives at lower tiers.

```yaml
# buf.yaml
version: v2
breaking:
  use:
    - FILE
```

---

## What `FILE` catches that `WIRE` doesn't

Suppose you rename a field:

```proto
// Before
message Ad {
  string ad_unit_id = 1;
}

// After
message Ad {
  string ad_unit = 1;   // renamed
}
```

- **WIRE**: passes. The number is unchanged; the wire bytes are unchanged.
- **FILE**: fails (`FIELD_SAME_NAME`). The generated Go field is now `AdUnit` not `AdUnitId` — every Go caller breaks at compile time on re-generation.

`WIRE`'s tolerance for source breaks is fine for a true binary-only API, but for `apis` (which every Go service regenerates from) it'd let you ship hours-long incidents.

---

## What every tier catches

These are the changes that are breaking at **every** tier — they will fail `buf breaking` no matter how loose you make the config. Memorise them; they are the AIP-180 forbidden list:

- Removing a field, message, or enum value.
- Reusing or renumbering a field number.
- Changing a field's type to an incompatible type.
- Changing a field from singular to repeated (or vice versa).
- Changing a field's oneof membership.
- Changing the package.

See `backward-compatibility-checklist.md` for the full review-time checklist.

---

## False positives: when a "break" is intentional

You will, occasionally, want to actually break compat (e.g. shipping `v2` of a package). The right workflow:

1. **Don't ignore the check.** Don't `--exclude` paths; don't carry a "breaking-changes-allowed" label.
2. **Bump the package version.** `example.ads.sdk.v1` → `example.ads.sdk.v2`. The old package stays, the new package is unconstrained.
3. **Delete the old package only after every consumer migrates.** `buf breaking` will start failing on deletion — that's correct, and the response is to coordinate consumer cutover, not to ignore the failure.

```yaml
# buf.yaml — ignore the v1 directory only after it's empty and ready to delete
version: v2
breaking:
  use:
    - FILE
  ignore:
    - example/ads/sdk/v1/   # being retired 2026-08; remove this entry when directory is deleted
```

Every ignore entry has an expiry date in the comment.

---

## Run it locally too, not just in CI

Add a pre-push hook or a `make` target so contributors find breakage before opening the PR:

```bash
# Local: against the local main
buf breaking --against ".git#branch=main"

# Local: against a specific commit
buf breaking --against ".git#ref=<sha>"
```

Buf supports `git://`, `https://`, and local filesystem `--against` targets — pick whichever matches your workflow.

---

## When the breaking check is too strict for a non-API repo

If a `.proto` file is private to one service (e.g. a serialisation format internal to one repo), you can leave `buf breaking` off — but that's a deliberate, documented exemption, not a default. Most "private" protos turn out to be shared with the data team's pipelines, the analytics warehouse, or a debug tool — at which point you wish you had the check.

Default position: **every** `.proto` file gets `buf breaking` in CI. Exempt only with a written justification.

---

## Failure-mode triage

When `buf breaking` fails, the message names the rule it violated. The top failures and what they mean:

| Rule | What changed | Fix |
|---|---|---|
| `FIELD_SAME_NUMBER` | A field's number changed | Restore the original number; pick a new free number for the renamed field |
| `FIELD_NO_DELETE` | A field was removed | Replace deletion with `reserved 5; reserved "field_name";` |
| `ENUM_VALUE_NO_DELETE` | An enum value was removed | Same — `reserved 4; reserved "OLD_VALUE";` |
| `RPC_NO_DELETE` | An RPC was removed | Mark it `deprecated = true`; remove only on package bump |
| `FILE_NO_DELETE` | A file was removed | Move contents back; deletion is a major-version concern |

---

## Related Rules

- [buf lint in CI](buf-lint-in-ci.md) — the style sibling; both should run on every PR
- [Backward Compatibility Checklist](backward-compatibility-checklist.md) — AIP-180 reference for reviewers
- [Enum Hygiene](../schema/enum-hygiene.md) — the most common cause of breaking-check failures

---

## References

- [Buf Breaking Change Rules](https://buf.build/docs/breaking/rules/)
- [Buf Docs](https://buf.build/docs/)
- [AIP-180 — Backwards Compatibility](https://google.aip.dev/180)

<!-- Cross-platform: see AGENTS.md in the repository root for Cursor, Claude Code, and Copilot paths. -->
