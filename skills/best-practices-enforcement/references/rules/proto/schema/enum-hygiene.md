# Enum Hygiene

Enums are the trickiest part of a long-lived schema: their values are persisted in messages, replayed from Kafka, stored in databases, and compared across heterogeneous client versions. A renumber or a delete is a silent wire-compat break — readers that don't recognise a value will fall back to the zero value (proto3) or fail to decode (proto2/edition with closed enums). Treat enum changes the same way you'd treat changing a primary key.

Sources: [Buf Style Guide — Enums](https://buf.build/docs/best-practices/style-guide/), [Proto3 Language Guide — Enumerations](https://protobuf.dev/programming-guides/proto3/).

---

## Every enum starts with `UNSPECIFIED = 0`

Proto3 (and editions with open-enum semantics) defaults the zero value when the field is absent. If you make `0` mean a real domain value, readers can no longer distinguish "unset" from "the first value" — and you've baked an inherently lossy default into every downstream system.

```proto
// ✅ Good: explicit unspecified sentinel, prefixed with the enum name
enum AdFormat {
  AD_FORMAT_UNSPECIFIED = 0;
  AD_FORMAT_REWARDED = 1;
  AD_FORMAT_INTERSTITIAL = 2;
  AD_FORMAT_BANNER = 3;
}
```

```proto
// ❌ Bad: zero value is a real domain value
enum AdFormat {
  REWARDED = 0;        // any new AdRequest with no format set silently means REWARDED
  INTERSTITIAL = 1;
  BANNER = 2;
}
```

Buf's STANDARD lint requires both the `UNSPECIFIED` zero-value and the enum-name prefix. The prefix matters because enum values share a namespace with their package — without it, two enums in the same `.proto` collide.

---

## Never renumber an existing value

Numbers, not names, are what travel on the wire. Renumbering breaks every persisted message and every in-flight RPC.

```proto
// Original
enum AdState {
  AD_STATE_UNSPECIFIED = 0;
  AD_STATE_PENDING = 1;
  AD_STATE_SERVED = 2;
  AD_STATE_CLICKED = 3;
}

// ❌ Bad: renumbering — a persisted Kafka message with AD_STATE_SERVED=2 will now decode as AD_STATE_FAILED
enum AdState {
  AD_STATE_UNSPECIFIED = 0;
  AD_STATE_PENDING = 1;
  AD_STATE_FAILED = 2;   // moved into slot 2!
  AD_STATE_SERVED = 3;
  AD_STATE_CLICKED = 4;
}
```

`buf breaking` (`ENUM_VALUE_SAME_NAME` in WIRE/WIRE_JSON tiers) catches this — wire it into CI per `governance/buf-breaking-against-main.md`.

---

## Never remove a value — deprecate instead

Removing a value also re-uses the slot in the future (or worse, leaves consumers parsing a value the schema no longer defines). Mark it deprecated and keep it forever.

```proto
// ✅ Good: deprecate, don't delete
enum AdState {
  AD_STATE_UNSPECIFIED = 0;
  AD_STATE_PENDING = 1;
  AD_STATE_SERVED = 2;
  AD_STATE_CLICKED = 3;
  AD_STATE_LEGACY_RETIRED = 4 [deprecated = true];   // do not remove
}
```

```proto
// ❌ Bad: deletion
enum AdState {
  AD_STATE_UNSPECIFIED = 0;
  AD_STATE_PENDING = 1;
  AD_STATE_SERVED = 2;
  AD_STATE_CLICKED = 3;
  // AD_STATE_LEGACY_RETIRED = 4 silently removed — slot 4 is now "unknown" to new readers,
  // and a future addition AD_STATE_NEW_THING = 4 would silently mean RETIRED to old readers.
}
```

If you absolutely must retire a value's behaviour, leave it in the schema, reject it at the application layer, and document the deprecation date.

---

## Add new values at the end, with the next free number

Append-only growth is the only safe extension model. New values get the next unused number and a name that respects the `<ENUM_NAME>_` prefix.

```proto
// ✅ Good: append, prefix, no gap reuse
enum AdState {
  AD_STATE_UNSPECIFIED = 0;
  AD_STATE_PENDING = 1;
  AD_STATE_SERVED = 2;
  AD_STATE_CLICKED = 3;
  AD_STATE_LEGACY_RETIRED = 4 [deprecated = true];
  AD_STATE_FRAUD_BLOCKED = 5;  // new, takes slot 5
}
```

Old clients will receive value `5` and either map it to `UNSPECIFIED` (open-enum, the proto3 default) or fail to decode (closed-enum, e.g. Java/proto2). Plan your rollout: writers should not emit a new enum value until you're confident readers have been upgraded or can gracefully handle unknown values.

---

## Closed vs open enums (Editions)

Editions makes enum semantics explicit via the `enum_type` feature:

| Setting | Behaviour | When |
|---|---|---|
| `OPEN` (proto3 default) | Unknown values pass through; reader sees the raw int | Public APIs, long-lived event streams |
| `CLOSED` (proto2 default) | Unknown values are dropped into the unknown-fields set | Tightly controlled internal contracts |

```proto
edition = "2024";
package unityads.ads.sdk.v1;

option features.enum_type = OPEN;  // explicit — don't rely on language default
```

For UADS schemas in `unityapis`, prefer `OPEN` — Kafka replay and SDK heterogeneity make closed semantics a foot-gun.

---

## Reserve numbers and names you've removed

If you ever do need to drop a value (e.g. one accidentally landed in main but was never used in production), `reserved` it so nobody can reuse the slot.

```proto
enum AdState {
  AD_STATE_UNSPECIFIED = 0;
  AD_STATE_PENDING = 1;
  AD_STATE_SERVED = 2;
  AD_STATE_CLICKED = 3;
  reserved 4;
  reserved "AD_STATE_LEGACY_RETIRED";
}
```

The compiler will refuse to let the next contributor accidentally re-add either the number or the name.

---

## Related Rules

- [Naming and Layout](naming-and-layout.md) — enum naming and value prefix conventions
- [Editions Adoption](editions-adoption.md) — `enum_type` feature in Edition 2024
- [Backward Compatibility Checklist](../governance/backward-compatibility-checklist.md) — AIP-180 forbidden changes
- [buf breaking against main](../governance/buf-breaking-against-main.md) — CI gate that catches renumbers

---

## References

- [Buf Style Guide — Enums](https://buf.build/docs/best-practices/style-guide/)
- [Proto3 Language Guide — Enumerations](https://protobuf.dev/programming-guides/proto3/)
- [Protobuf Editions Overview](https://protobuf.dev/editions/overview/)

<!-- Cross-platform: see AGENTS.md in the repository root for Cursor, Claude Code, and Copilot paths. -->
