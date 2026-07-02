# Backward-Compatibility Checklist (AIP-180)

`buf breaking` will catch most of these mechanically, but a human reviewer still needs to understand the underlying rules — both to confirm the tool is right, and to spot semantic breaks the tool can't see (a field type that's wire-compatible but semantically wrong, an enum value whose meaning was redefined, a behaviour change with no schema diff).

This is the checklist version of [AIP-180](https://google.aip.dev/180), the canonical source for what counts as breaking in a proto API.

---

## Three kinds of compatibility

AIP-180 defines three flavours; a "breaking change" usually means breaking at least one:

| Type | What it means | Who notices |
|---|---|---|
| **Wire** | Old binaries can decode new messages and vice versa | Any consumer holding old `.pb.bin` data |
| **Source** | Generated code still compiles after re-generation against new schema | Any consumer regenerating from the schema |
| **Semantic** | The meaning of existing fields/methods is unchanged | Any consumer reading the data correctly |

`buf breaking` at the `FILE` tier catches Wire + Source. Semantic breaks are invisible to the tool — a field renamed from `score` to `confidence` is wire-fine, source-fine, semantically fine. The same field repurposed from `score_basis_points` to `score_percent` is **not** fine, and only a human notices.

---

## ✅ Safe changes (additive)

These are always backward-compatible at the wire and source level:

- **Add a new field with a never-used number.** Old readers skip it (unknown field).
- **Add a new RPC.** Old clients don't call it.
- **Add a new message type, enum type, or service.** Pure addition.
- **Add a new enum value at the end with the next free number** — but caveat: old readers map it to the zero value (open enum) or fail to decode (closed enum). Stage rollout carefully. See `../schema/enum-hygiene.md`.
- **Mark a field, RPC, message, or enum value as `deprecated = true`.** No wire effect; clients see a doc/lint warning.
- **Reserve a removed field number / name.** Belongs in every removal PR.
- **Add a new optional dependency / import.**
- **Tighten validation that was already documented** (with operational care — see `../validation/protovalidate-over-pgv.md`).

---

## ❌ Forbidden — wire-breaking

These change the bytes on the wire. They will fail `buf breaking` at every tier. Never do them without a package version bump.

- **Change a field number.** Old data persisted with the old number now decodes as garbage or unknown.
- **Reuse a previously-removed field number.** Old in-flight or persisted messages with the old occupant decode as the new type — usually as a corrupt instance.
- **Change a field's type to an incompatible type.** Most type changes are incompatible; the compatible exceptions are narrow (`int32` ↔ `int64` ↔ `uint32` ↔ `uint64` ↔ `bool`; `sint32` ↔ `sint64`; some bytes ↔ string cases — verify with AIP-180 before relying on any of these).
- **Change `singular` to `repeated`, or vice versa.**
- **Change a `map<K,V>` field's key or value type.**
- **Add / remove a field from an existing `oneof`.** Moving a field in or out of a oneof changes wire semantics.
- **Remove an enum value's number / rename a number's value.** Persisted data referencing that number is now misinterpreted.
- **Change a `proto3` field's default behaviour** by adding `optional` after the fact in a way that changes wire semantics.

---

## ❌ Forbidden — source-breaking (FILE tier)

These don't change wire bytes but break every consumer that regenerates code. `buf breaking` at FILE catches them; at WIRE it doesn't. For `unityapis` (consumed by every Go backend that regenerates) treat these as fully forbidden.

- **Rename a field, message, enum value, RPC, service, or package.** Wire is fine; every generated symbol changes.
- **Move a message between files or packages.** Import paths change.
- **Delete an RPC** (even an unused-looking one). Generated client stubs disappear.
- **Change a service's name.**
- **Reorder oneof variants** in a way that changes generated case enums.

---

## ❌ Forbidden — semantic (invisible to the tool)

`buf breaking` cannot catch these. Reviewer responsibility.

- **Repurpose an existing field.** Old data still parses, but its meaning is now wrong.
- **Change the unit of a numeric field.** `latency_ms` → `latency_us` is a silent factor-of-1000 disaster.
- **Change an enum value's domain meaning.** Renaming `AD_STATE_PAUSED` to `AD_STATE_HOLD` is a Field name change (FILE catches it). But silently redefining `AD_STATE_PAUSED` from "manually paused" to "auto-paused by fraud detection" is a semantic-only break and only docs / review catch it.
- **Change validation rules** in a way that rejects previously-valid messages. Server now `INVALID_ARGUMENT`s requests that worked yesterday.
- **Change the set of error codes** a server returns for a given input. Clients' error handling breaks.
- **Change response-population behaviour** — e.g. an optional field that used to always be populated is now sometimes empty.

---

## Reviewer flow

For every `.proto` PR:

1. **Run `buf breaking` against `main` locally.** If it passes, you've cleared the wire + source layers. If it fails, the message names the rule; fix or coordinate a deliberate break per `buf-breaking-against-main.md`.
2. **Read the diff for semantic changes.** Specifically look at: renamed fields (was the old name in production?), reused field numbers (are they actually new, or recycled?), changed validation constraints, changed enum value comments.
3. **For any changed RPC**: check that the change doesn't alter the set of plausible error codes or the population semantics of response fields.
4. **Confirm `reserved`** for every removal. A missing `reserved` is a footgun for the next contributor.

---

## When you genuinely need to break: bump the package version

A package version bump is the only safe way to make breaking changes:

```proto
// Old, frozen
package unityads.ads.sdk.v1;

message AdRequest {
  string ad_unit_id = 1;
}

// New, free to redesign
package unityads.ads.sdk.v2;

message AdRequest {
  string placement_id = 1;   // renamed concept
  Targeting targeting = 2;   // restructured
}
```

Both packages live side-by-side; consumers migrate at their own pace; the old package is deleted only after every consumer is on v2.

---

## Related Rules

- [buf breaking against main](buf-breaking-against-main.md) — automated enforcement of the wire + source layers
- [buf lint in CI](buf-lint-in-ci.md) — automated enforcement of style rules
- [Enum Hygiene](../schema/enum-hygiene.md) — the most-broken rule in practice
- [Avoid Empty RPC Messages](../schema/avoid-empty-rpc-messages.md) — preempts a future source-incompat swap

---

## References

- [AIP-180 — Backwards Compatibility](https://google.aip.dev/180)
- [Buf Breaking Change Rules](https://buf.build/docs/breaking/rules/)
- [Protobuf Language Guide — Updating a Message Type](https://protobuf.dev/programming-guides/proto3/#updating)

<!-- Cross-platform: see AGENTS.md in the repository root for Cursor, Claude Code, and Copilot paths. -->
