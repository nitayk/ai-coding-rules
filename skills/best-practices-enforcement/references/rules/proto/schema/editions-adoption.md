# Editions Adoption Policy

Protobuf **Editions** replace the proto2/proto3 split. Instead of two language variants with hard-coded behavior, an Edition file declares per-feature behaviors (field presence, enum openness, JSON format, repeated encoding, etc.) explicitly. Edition 2023 is the migration-friendly baseline; Edition 2024 is the latest.

Source: [Protobuf Editions Overview](https://protobuf.dev/editions/overview/).

---

## Policy

1. **New `.proto` packages**: start in **Edition 2024**.
2. **Existing proto3 packages**: stay on proto3 until there is a **concrete feature reason** to migrate (e.g. you need a behavior only available under Editions). Edition 2023's defaults are designed to match proto3 semantics, so the migration is mechanical via Prototiller — but it touches every file and every generated artifact, so don't do it speculatively.
3. **Existing proto2 packages**: plan a migration to Edition 2023. Proto2 is on a long sunset path; new tooling and lints increasingly assume Editions semantics.
4. **Never mix syntaxes inside a single package**. A package is either all-proto3 or all-Editions. Cross-package imports across syntaxes are supported.

---

## What an Editions file looks like

```proto
// ✅ Good: Edition 2024, presence default carried forward explicitly
edition = "2024";

package unityads.ads.valuation.v1;

option features.field_presence = EXPLICIT;

message Valuation {
  string ad_unit_id = 1;
  int32 ecpm_cents = 2;                  // EXPLICIT presence by default
}
```

```proto
// ❌ Bad: mixing syntaxes inside one package
// File a.proto
syntax = "proto3";
package unityads.ads.valuation.v1;
// File b.proto in the same dir
edition = "2024";
package unityads.ads.valuation.v1;
```

---

## Use Prototiller for migrations, not hand-edits

`buf migrate` (wrapping the upstream Prototiller) rewrites proto2/proto3 syntax into the equivalent Edition 2023 file with `features.*` options preserving original behavior. For most proto3 files the result is a **no-op semantic change** — only the header changes.

Run it in a dedicated commit, with a `buf format` immediately after, and verify with `buf breaking` against `main` (see `governance/buf-breaking-against-main.md`). The diff should be header-only for proto3 inputs; investigate any field-level changes before merging.

```bash
# ✅ Good: dedicated migration commit
buf migrate --to=2023
buf format -w
buf breaking --against '.git#branch=main'
```

---

## Feature flags worth knowing

Editions surface previously hard-coded behaviors as explicit features. The common ones:

| Feature | Proto3 default | Edition 2023 default | Edition 2024 default |
|---|---|---|---|
| `field_presence` | `IMPLICIT` for scalars | `EXPLICIT` | `EXPLICIT` |
| `enum_type` | `OPEN` (unknown values surfaced) | `OPEN` | `OPEN` |
| `repeated_field_encoding` | `PACKED` for scalars | `PACKED` | `PACKED` |
| `utf8_validation` | `VERIFY` | `VERIFY` | `VERIFY` |

The migration friction is almost entirely `field_presence`: Edition 2023 makes presence explicit by default, while proto3 made it implicit. If your proto3 schema already uses `optional` consistently (see `schema/field-presence-and-optional.md`), there is nothing to do; if it relies on implicit presence, decide per-field whether to add `optional` or set `features.field_presence = IMPLICIT` at file scope.

---

## Don't gate Editions adoption on consumer language support

`protoc` (v25+) and the major language runtimes (Go, Java, Python, C++, Ruby) all support Editions. The blocker is almost always **internal codegen scripts that pass `--proto3`-only flags**. Fix those before migrating.

If a consumer is on an old runtime version, pin its codegen toolchain (see `validation/codegen-toolchain.md`) rather than freezing the producer schema on proto3.

---

## References

- [Protobuf Editions Overview](https://protobuf.dev/editions/overview/)
- [Proto3 Language Guide](https://protobuf.dev/programming-guides/proto3/)

<!-- Cross-platform: see AGENTS.md in the repository root for Cursor, Claude Code, and Copilot paths. -->
