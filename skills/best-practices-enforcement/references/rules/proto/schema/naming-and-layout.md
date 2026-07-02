# Proto Naming and File Layout

Names in `.proto` files travel further than in most languages: they end up in generated Go/Java/Python identifiers, in JSON tag names, in the wire-format JSON mapping, and in BSR module paths. Buf is stricter than Google's advisory style guide on purpose — its rules are mechanically enforceable in CI. Adopt Buf as the source of truth and treat the Google guide as background reading.

Sources: [Protocol Buffers Style Guide](https://protobuf.dev/programming-guides/style/), [Buf Style Guide](https://buf.build/docs/best-practices/style-guide/).

---

## Files

- **`lower_snake_case.proto`**, one dominant message per file, file basename matches the dominant message in snake_case.
- Files live under directories that mirror the package: `example/ads/sdk/v1/gateway.proto` declares `package example.ads.sdk.v1;`.

```proto
// ✅ Good: file example/ads/sdk/v1/ad_request.proto
syntax = "proto3";

package example.ads.sdk.v1;

option go_package = "github.com/example-org/apis/gen/go/example/ads/sdk/v1;sdkv1";

message AdRequest {
  // ...
}
```

```proto
// ❌ Bad: CamelCase filename, package-path mismatch, no go_package
// File: AdRequest.proto, located at protos/AdRequest.proto
syntax = "proto3";
package AdsSDK;       // wrong casing, no version suffix
message adRequest {}  // wrong message casing
```

---

## Packages

- Dot-delimited, all lowercase, no underscores. `example.ads.sdk.v1` — never `example.adsSDK.v1` or `example_ads.ads.sdk.v1`.
- **Always end with a version suffix** (`v1`, `v1beta1`, `v2`). Buf's STANDARD lint enforces this. The version suffix is what lets you ship `v2` alongside `v1` without renaming the package.
- A breaking change to a stable package (`v1`) requires a new package (`v2`) — never silently break `v1`. See `governance/backward-compatibility-checklist.md`.

```proto
// ✅ Good
package example.ads.valuation.v1;

// ❌ Bad: no version suffix — Buf will refuse this in STANDARD lint
package example.ads.valuation;
```

---

## Messages and Fields

| Element | Convention | Example |
|---|---|---|
| Message | `TitleCase` | `AdRequest`, `GamerProfile` |
| Field | `snake_case` | `ad_unit_id`, `gamer_id` |
| Repeated field | `snake_case`, **plural** noun | `repeated string device_ids = 5;` |
| Nested message | `TitleCase`, nested only when scoped to parent | `AdRequest.Targeting` |
| Oneof | `snake_case` | `oneof identity { ... }` |

```proto
// ✅ Good
message AdRequest {
  string ad_unit_id = 1;
  repeated string device_ids = 2;        // plural for repeated
  GamerProfile gamer = 3;

  message Targeting {                    // nested: only used by AdRequest
    repeated string segment_ids = 1;
  }
}

// ❌ Bad
message ad_request {                     // wrong: messages are TitleCase
  string AdUnitId = 1;                   // wrong: fields are snake_case
  repeated string device_id = 2;         // wrong: plural for repeated
}
```

---

## Enums

- `TitleCase` for the enum type.
- `UPPER_SNAKE_CASE` for values. **Prefix each value with the enum name** so values don't collide across enums in the same proto package. See `schema/enum-hygiene.md` for the zero-value and lifecycle rules.

```proto
// ✅ Good
enum AdFormat {
  AD_FORMAT_UNSPECIFIED = 0;
  AD_FORMAT_REWARDED = 1;
  AD_FORMAT_INTERSTITIAL = 2;
}

// ❌ Bad
enum AdFormat {
  UNSPECIFIED = 0;                       // collides with other enums
  REWARDED = 1;
  Interstitial = 2;                      // wrong casing
}
```

---

## Services and RPCs

- Service names are `TitleCase` and **end in `Service`** (Buf STANDARD enforces this).
- RPC names are `TitleCase` verbs: `GetAd`, `ListCampaigns`, `UpdateGamerProfile`.
- Request/response types are `<Rpc>Request` / `<Rpc>Response`. Never reuse them across RPCs — see `schema/avoid-empty-rpc-messages.md` and `grpc/update-and-fieldmask.md`.

```proto
// ✅ Good
service AdValuationService {
  rpc GetValuation(GetValuationRequest) returns (GetValuationResponse);
  rpc ListValuations(ListValuationsRequest) returns (ListValuationsResponse);
}

// ❌ Bad
service AdValuation {                    // missing Service suffix
  rpc get_valuation(Request) returns (Response);   // wrong casing, shared types
}
```

---

## `go_package` is mandatory

Every `.proto` file that will be consumed by Go code must declare `option go_package = "...";` with the **import path** and a **short package alias** (after the `;`). Without the alias, generated Go uses the last path segment, which is almost always wrong for versioned packages (`v1` is not a useful Go package name).

```proto
// ✅ Good
option go_package = "github.com/example-org/apis/gen/go/example/ads/sdk/v1;sdkv1";

// ❌ Bad: generated Go package is named `v1`
option go_package = "github.com/example-org/apis/gen/go/example/ads/sdk/v1";
```

---

## References

- [Protocol Buffers Style Guide](https://protobuf.dev/programming-guides/style/)
- [Buf Style Guide](https://buf.build/docs/best-practices/style-guide/)

<!-- Cross-platform: see AGENTS.md in the repository root for deployment details. -->
