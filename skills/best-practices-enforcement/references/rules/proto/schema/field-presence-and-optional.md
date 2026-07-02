# Field Presence and `optional` in proto3

For years the proto3 default was *implicit presence*: a scalar field that equals its type's default (`""`, `0`, `false`) is indistinguishable from "not set". The Protobuf project now explicitly recommends marking scalar fields `optional` to get **explicit presence** — both for correctness and for forward compatibility with Editions.

Source: [Proto3 Language Guide — Field presence](https://protobuf.dev/programming-guides/proto3/).

---

## Why presence matters

Implicit presence breaks down whenever the zero value is a meaningful business value:

- `int32 bid_price_cents = 5;` — is `0` "the bidder bid zero" or "no bid"?
- `bool opted_in = 7;` — is `false` "opted out" or "no answer yet"?
- `string country_code = 9;` — is `""` "unknown" or "explicitly cleared"?

It also makes **partial-update RPCs ambiguous**: a client that wants to clear a field cannot, because sending the zero value is indistinguishable from leaving the field alone. This is why AIP-134 PATCH semantics rely on either `optional` scalars or a `FieldMask` (see `grpc/update-and-fieldmask.md`).

---

## Use `optional` for scalar presence

```proto
// ✅ Good: explicit presence; generated code exposes Has*() / nil pointer
message Bid {
  string bidder_id = 1;
  optional int32 bid_price_cents = 2;    // unset vs 0 are distinct
  optional bool is_house_bid = 3;        // unset vs false are distinct
}

// ❌ Bad: implicit presence; 0 / false / "" collide with "missing"
message Bid {
  string bidder_id = 1;
  int32 bid_price_cents = 2;             // can't tell unset from 0
  bool is_house_bid = 3;                 // can't tell unset from false
}
```

In generated Go this becomes a pointer (`*int32`) and a `GetBidPriceCents()` that returns the zero value when unset. In other languages it surfaces as `HasBidPriceCents()` / `bid_price_cents().has_value()`.

---

## Messages already have presence — don't mark them `optional`

Singular message fields are always presence-tracked (the field is either set or `nil`). Marking them `optional` is redundant and adds noise.

```proto
// ✅ Good
message AdRequest {
  GamerProfile gamer = 1;                // already presence-tracked
}

// ❌ Bad: redundant
message AdRequest {
  optional GamerProfile gamer = 1;
}
```

`repeated` and `map` fields also do not take `optional` — emptiness *is* the absence signal.

---

## When implicit presence is fine

Implicit presence is the right default when **the zero value is the semantic default** and there is no PATCH/clear use case:

- Counters where 0 means 0 (`int32 retry_count`).
- Booleans where `false` is the inert state and "unset" has no meaning (`bool debug_logging`).
- Strings where `""` is treated as missing throughout the system already.

If in doubt, default to `optional` for new scalar fields. The wire-format cost is a single tag byte when set and nothing when unset — it never serializes the zero value.

---

## Forward-compatibility with Editions

Edition 2023 makes the implicit/explicit choice an **explicit feature** (`features.field_presence = IMPLICIT | EXPLICIT | LEGACY_REQUIRED`). Schemas that already use `optional` consistently in proto3 migrate cleanly via Prototiller; schemas that rely on implicit presence may produce unexpected `EXPLICIT` defaults under Edition 2023. See `schema/editions-adoption.md`.

---

## Don't add `optional` to existing fields without thinking

Adding `optional` to an **existing implicit-presence scalar** is wire-compatible (the encoding does not change), but it *does* change generated source in every consumer — pointers appear, getters/setters change shape. Coordinate the rollout, or batch it into a planned `v2` cut.

```proto
// ⚠️ Wire-safe, source-breaking — coordinate before merging
message Bid {
-  int32 bid_price_cents = 2;
+  optional int32 bid_price_cents = 2;
}
```

---

## References

- [Proto3 Language Guide — Field presence](https://protobuf.dev/programming-guides/proto3/)
- [Protobuf Editions Overview](https://protobuf.dev/editions/overview/)

<!-- Cross-platform: see AGENTS.md in the repository root for deployment details. -->
