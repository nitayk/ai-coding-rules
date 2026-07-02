# Avoid `google.protobuf.Empty` in RPCs

`google.protobuf.Empty` looks like the right answer when an RPC genuinely has no inputs or no outputs. It isn't. Once you publish `rpc Foo(Empty) returns (FooResponse)`, you can never add a request field without a wire-compatible-but-source-incompatible swap that breaks every generated client. Always use a concrete `FooRequest` / `FooResponse` from day one, even when they're empty messages.

Sources: [Buf Style Guide — Avoid `google.protobuf.Empty`](https://buf.build/docs/best-practices/style-guide/), [AIP-180 — Backwards Compatibility](https://google.aip.dev/180).

---

## The rule

Every RPC declares a dedicated request and a dedicated response message, named `<RpcName>Request` and `<RpcName>Response`. They can be empty messages; that is fine and idiomatic.

```proto
// ✅ Good: empty-but-named messages — extensible without a breaking change later
message PingRequest {}
message PingResponse {
  google.protobuf.Timestamp server_time = 1;
}

service HealthService {
  rpc Ping(PingRequest) returns (PingResponse);
}
```

```proto
// ❌ Bad: locks the RPC's request shape forever
import "google/protobuf/empty.proto";

service HealthService {
  rpc Ping(google.protobuf.Empty) returns (PingResponse);
}
```

`buf lint STANDARD` flags both `Empty` request and `Empty` response (`RPC_REQUEST_STANDARD_NAME`, `RPC_RESPONSE_STANDARD_NAME`, `RPC_REQUEST_RESPONSE_UNIQUE`).

---

## Why "I can just swap `Empty` for a real message later" is wrong

In wire-format terms, switching from `google.protobuf.Empty` to `PingRequest` is compatible: both are empty messages and decode interchangeably. In **source-format** terms it is not — every generated client and server has compiled the symbol `google.protobuf.Empty` into its method signatures. Swapping the type requires every consumer to:

1. Regenerate their stubs against the new schema.
2. Update call sites that reference the old type.
3. Re-deploy in lockstep.

For `apis` — consumed by every Go backend in the org — that's the same blast radius as a real breaking change. Starting with a concrete type costs nothing today and avoids the migration entirely.

---

## "But the request really is empty" — it isn't, for long

Almost every RPC accumulates request fields over time. A short non-exhaustive list of things you'll eventually want to add to a "no-args" call:

- A request id for tracing.
- A `FieldMask` of which response fields to populate.
- A pagination cursor.
- A tenant / project / org id.
- An idempotency key.

A concrete `PingRequest {}` lets you add any of those by appending a field with a new number — a fully backward-compatible change.

```proto
// Day 1
message PingRequest {}

// Day 90 — additive, no consumer break
message PingRequest {
  string request_id = 1;
  string tenant_id = 2;
}
```

---

## Response side: same rule, same reasoning

The response side is even more important — clients almost always want richer answers eventually. `rpc Foo(...) returns (google.protobuf.Empty)` says "this RPC will never return data," which is a promise you rarely want to make.

```proto
// ✅ Good
message DeleteAdRequest {
  string ad_id = 1;
}

message DeleteAdResponse {
  // can grow to include audit fields, cascaded-delete counts, etc.
}

service AdService {
  rpc DeleteAd(DeleteAdRequest) returns (DeleteAdResponse);
}
```

```proto
// ❌ Bad: future addition (e.g. a deleted_count) requires a source-incompatible swap
service AdService {
  rpc DeleteAd(DeleteAdRequest) returns (google.protobuf.Empty);
}
```

---

## When is `google.protobuf.Empty` actually OK?

In `Any`-payload fields and as a marker inside other messages — not as an RPC signature.

```proto
// ✅ Fine: Empty as a Status detail marker
import "google/protobuf/empty.proto";
import "google/rpc/status.proto";

message Operation {
  google.rpc.Status error = 1;
  google.protobuf.Any response = 2;  // could be an Empty for void-returning ops
}
```

Even then, prefer a concrete `EmptyResult` message that you own so you can attach fields later.

---

## Never share request/response messages across RPCs

`RPC_REQUEST_RESPONSE_UNIQUE` (Buf STANDARD) bans this for the same reason: once two RPCs share a request type, you can't evolve one without affecting the other.

```proto
// ❌ Bad: shared request message
message AdRequest {
  string ad_id = 1;
}

service AdService {
  rpc GetAd(AdRequest) returns (GetAdResponse);
  rpc DeleteAd(AdRequest) returns (DeleteAdResponse);  // shares the type
}
```

```proto
// ✅ Good: distinct types, even when fields overlap
message GetAdRequest { string ad_id = 1; }
message DeleteAdRequest { string ad_id = 1; }

service AdService {
  rpc GetAd(GetAdRequest) returns (GetAdResponse);
  rpc DeleteAd(DeleteAdRequest) returns (DeleteAdResponse);
}
```

---

## Related Rules

- [Naming and Layout](naming-and-layout.md) — `<RpcName>Request` / `<RpcName>Response` convention
- [Backward Compatibility Checklist](../governance/backward-compatibility-checklist.md) — what counts as a breaking change
- [buf lint in CI](../governance/buf-lint-in-ci.md) — STANDARD category enforcement

---

## References

- [Buf Style Guide](https://buf.build/docs/best-practices/style-guide/)
- [AIP-180 — Backwards Compatibility](https://google.aip.dev/180)

<!-- Cross-platform: see AGENTS.md in the repository root for deployment details. -->
