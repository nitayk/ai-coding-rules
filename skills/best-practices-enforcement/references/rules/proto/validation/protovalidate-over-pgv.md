# `protovalidate` Over `protoc-gen-validate`

`protovalidate` is the explicit successor to `protoc-gen-validate` (PGV). It moves validation from generated language-specific code to **CEL** ([Common Expression Language](https://github.com/google/cel-spec)) constraints embedded in the `.proto` itself, evaluated at runtime by a small per-language library. Buf is shipping it as the recommended path forward; PGV is on a migration trajectory and will not get new features.

New schemas MUST use protovalidate. Existing PGV-annotated schemas can stay on PGV during their normal lifecycle, but the migration is straightforward (Buf provides a converter).

Source: [protovalidate (GitHub)](https://github.com/bufbuild/protovalidate); v1.2.0 released 2026-04-15.

---

## What it looks like

Add the `buf.validate.field` option directly to the field. The constraints are CEL expressions for the complex cases and a small set of declarative shortcuts for common ones.

```proto
syntax = "proto3";

package unityads.ads.sdk.v1;

import "buf/validate/validate.proto";

message AdRequest {
  // Declarative: non-empty, length cap
  string ad_unit_id = 1 [
    (buf.validate.field).string.min_len = 1,
    (buf.validate.field).string.max_len = 128
  ];

  // Declarative: UUID
  string request_id = 2 [(buf.validate.field).string.uuid = true];

  // Declarative: numeric range
  int32 max_results = 3 [
    (buf.validate.field).int32 = { gte: 1, lte: 100 }
  ];

  // CEL: cross-field invariant — start_time must precede end_time
  google.protobuf.Timestamp start_time = 4 [(buf.validate.field).required = true];
  google.protobuf.Timestamp end_time = 5 [
    (buf.validate.field).required = true,
    (buf.validate.field).cel = {
      id:      "ad_request.time_range",
      message: "end_time must be after start_time",
      expression: "this > AdRequest.start_time"
    }
  ];
}
```

---

## Why CEL beats codegen-only validation

PGV generated language-specific validation code (`Validate()` methods in Go, `Validator` classes in Java, etc.). That worked, but:

1. **N codegens to maintain.** Every supported language needs its own generator. PGV's Go generator is the most polished; others lag.
2. **Cross-field constraints are awkward.** Pre-CEL, expressing "A required when B set" needed escape hatches.
3. **Runtime debugging is opaque.** When validation fails, the error came from generated code — slow to map back to the `.proto` line.
4. **No standard for new constraint types.** Every new constraint needs codegen support across N languages.

protovalidate uses one CEL evaluator per language (a small library, not generated code) and one source of truth (the `.proto` annotations). New constraint types are immediately available everywhere CEL runs. Cross-field rules are first-class expressions.

---

## Server-side: validate at the boundary

Run `protovalidate.Validate(msg)` as the first thing in every RPC handler. Failure → `INVALID_ARGUMENT` per `../grpc/status-codes-and-errors.md`.

```go
import (
    "buf.build/go/protovalidate"
    "google.golang.org/grpc/codes"
    "google.golang.org/grpc/status"
)

var validator *protovalidate.Validator

func init() {
    var err error
    validator, err = protovalidate.New()
    if err != nil {
        panic(err)
    }
}

func (s *Server) RequestAd(ctx context.Context, req *pb.AdRequest) (*pb.AdResponse, error) {
    if err := validator.Validate(req); err != nil {
        return nil, status.Errorf(codes.InvalidArgument, "validation: %v", err)
    }
    // ... real handler ...
}
```

Wrap validation in a server interceptor so you don't have to remember it in every handler:

```go
func ValidationInterceptor(validator *protovalidate.Validator) grpc.UnaryServerInterceptor {
    return func(ctx context.Context, req any, _ *grpc.UnaryServerInfo, handler grpc.UnaryHandler) (any, error) {
        if msg, ok := req.(proto.Message); ok {
            if err := validator.Validate(msg); err != nil {
                return nil, status.Errorf(codes.InvalidArgument, "validation: %v", err)
            }
        }
        return handler(ctx, req)
    }
}
```

One interceptor, every RPC, no per-handler boilerplate.

---

## Client-side: validate before sending

The same library validates messages on the client side too — catches the bug before the network round trip.

```go
if err := validator.Validate(req); err != nil {
    return nil, fmt.Errorf("invalid ad request: %w", err)
}
resp, err := client.RequestAd(ctx, req)
```

---

## The PGV → protovalidate migration

For existing PGV-annotated schemas, Buf provides a converter:

```bash
# Convert PGV annotations to protovalidate in place
buf-protovalidate-migrate path/to/schemas
```

The mechanical translation handles all the standard constraints (`min_len`, `max_len`, `gt`, `lt`, regex, etc.). Cross-field constraints expressed in PGV's escape hatches usually need a manual CEL translation — the migrator flags them.

Migration is **non-breaking at the wire level** (validation lives outside the message bytes) but **source-breaking** (the generated `Validate()` method goes away in favour of the library's `Validate(msg)`). Coordinate with consumers before deleting the PGV annotations.

---

## Common constraints (quick reference)

| Need | Constraint |
|---|---|
| Required scalar | `(buf.validate.field).required = true` (works with `optional` for presence) |
| Non-empty string | `(buf.validate.field).string.min_len = 1` |
| String length cap | `(buf.validate.field).string.max_len = N` |
| String pattern | `(buf.validate.field).string.pattern = "^[a-z]+$"` |
| UUID | `(buf.validate.field).string.uuid = true` |
| Email | `(buf.validate.field).string.email = true` |
| Numeric range | `(buf.validate.field).int32 = { gte: 1, lte: 100 }` |
| Enum: defined value only | `(buf.validate.field).enum.defined_only = true` |
| Repeated min/max items | `(buf.validate.field).repeated = { min_items: 1, max_items: 100 }` |
| Cross-field / custom | `(buf.validate.field).cel = { id: ..., message: ..., expression: "..." }` |

Full reference: [protovalidate docs](https://github.com/bufbuild/protovalidate).

---

## What validation does NOT replace

- **Authentication / authorisation.** That's a separate interceptor layer.
- **Business-rule validation that needs external state.** "Ad must reference an existing campaign" requires a database lookup — not validation, just regular handler logic.
- **Wire-format / schema validation.** That's `buf lint` / `buf breaking`.

Validation is the boundary check for "the request is structurally valid and the values are in range." Anything beyond that lives in the handler.

---

## Related Rules

- [Status Codes and Errors](../grpc/status-codes-and-errors.md) — `INVALID_ARGUMENT` is the failure code for validation errors
- [Backward Compatibility Checklist](../governance/backward-compatibility-checklist.md) — tightening validation rejects previously-valid messages; treat as a behaviour break
- [Codegen Toolchain](codegen-toolchain.md) — protovalidate needs its own buf.gen.yaml plugin entry

---

## References

- [protovalidate (GitHub)](https://github.com/bufbuild/protovalidate)
- [Common Expression Language (CEL)](https://github.com/google/cel-spec)
- [Buf Docs](https://buf.build/docs/)

<!-- Cross-platform: see AGENTS.md in the repository root for Cursor, Claude Code, and Copilot paths. -->
