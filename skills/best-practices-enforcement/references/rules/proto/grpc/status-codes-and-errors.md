# gRPC Status Codes and Errors

gRPC defines exactly 17 status codes. They cover every situation a server needs to express. Domain-specific error semantics belong in the response message or in `google.rpc.Status` details — never in a custom integer code. Picking the right code matters: clients (and Envoy / gRPC retry policies / observability tooling) use the code to decide whether to retry, alert, or surface to the user.

Source: [gRPC Status Codes — canonical list](https://grpc.github.io/grpc/core/md_doc_statuscodes.html).

---

## The 17 codes

| Code | Numeric | When to use | Retriable? |
|---|---|---|---|
| `OK` | 0 | Success | n/a |
| `CANCELLED` | 1 | The operation was cancelled, typically by the caller | No |
| `UNKNOWN` | 2 | Unexpected error; last-resort fallback only | No |
| `INVALID_ARGUMENT` | 3 | Client specified an invalid argument (problem with the request itself) | No |
| `DEADLINE_EXCEEDED` | 4 | Deadline elapsed before the operation completed | Maybe (with backoff) |
| `NOT_FOUND` | 5 | The requested entity does not exist | No |
| `ALREADY_EXISTS` | 6 | Entity the client attempted to create already exists | No |
| `PERMISSION_DENIED` | 7 | Caller lacks permission to execute the operation (not "no token" — that's UNAUTHENTICATED) | No |
| `RESOURCE_EXHAUSTED` | 8 | Resource quota exhausted or rate limit hit | Yes (with backoff) |
| `FAILED_PRECONDITION` | 9 | System is not in a state required for the operation; caller should NOT retry without fixing state | No |
| `ABORTED` | 10 | Operation was aborted (transaction conflict); caller MAY retry | Yes |
| `OUT_OF_RANGE` | 11 | Operation attempted past the valid range (e.g. seeking past EOF) | Sometimes (state may grow) |
| `UNIMPLEMENTED` | 12 | Operation is not implemented or supported | No |
| `INTERNAL` | 13 | Internal server invariant broken; serious bug | No |
| `UNAVAILABLE` | 14 | Service is currently unavailable; most likely transient | Yes (with backoff) |
| `DATA_LOSS` | 15 | Unrecoverable data loss or corruption | No |
| `UNAUTHENTICATED` | 16 | Caller does not have valid auth credentials | No (until creds change) |

---

## The three codes people confuse

### `NOT_FOUND` vs `FAILED_PRECONDITION` vs `ABORTED`

These three are picked by **what a thoughtful client should do next**:

- `NOT_FOUND`: the entity does not exist. The client should not retry — there is nothing to retry against.
- `FAILED_PRECONDITION`: the entity exists but is not in a state where the operation can succeed (e.g. "cannot delete non-empty bucket"). The client must change system state before retrying.
- `ABORTED`: the operation was aborted due to a concurrency conflict (e.g. ETag mismatch, transaction conflict). The client can retry, typically after re-reading state.

```go
// ✅ Good: distinguishes "no such ad" from "ad exists but is currently locked"
func (s *AdService) DeleteAd(ctx context.Context, req *pb.DeleteAdRequest) (*pb.DeleteAdResponse, error) {
    ad, err := s.store.Get(ctx, req.AdId)
    if errors.Is(err, store.ErrNotFound) {
        return nil, status.Errorf(codes.NotFound, "ad %q not found", req.AdId)
    }
    if ad.Status == AdStatus_SERVING {
        return nil, status.Errorf(codes.FailedPrecondition, "ad %q is currently serving; pause it first", req.AdId)
    }
    if err := s.store.Delete(ctx, req.AdId, req.Etag); errors.Is(err, store.ErrEtagMismatch) {
        return nil, status.Errorf(codes.Aborted, "ad %q was modified; re-read and retry", req.AdId)
    }
    return &pb.DeleteAdResponse{}, nil
}
```

### `PERMISSION_DENIED` vs `UNAUTHENTICATED`

- `UNAUTHENTICATED`: missing or invalid credentials. "I don't know who you are."
- `PERMISSION_DENIED`: credentials are valid, but the caller is not allowed to do this. "I know who you are; you can't."

```go
// ✅ Good
if token == "" {
    return nil, status.Error(codes.Unauthenticated, "missing bearer token")
}
if !authz.CanDelete(claims, req.AdId) {
    return nil, status.Errorf(codes.PermissionDenied, "caller cannot delete ad %q", req.AdId)
}
```

### `INVALID_ARGUMENT` vs `OUT_OF_RANGE`

- `INVALID_ARGUMENT`: the request itself is malformed — it would be wrong at any point in time.
- `OUT_OF_RANGE`: the request shape is valid, but it asks for something past the current valid range (e.g. seeking past the end of a Kafka topic).

`OUT_OF_RANGE` is retriable in the sense that the valid range may grow; `INVALID_ARGUMENT` is not.

---

## Never invent app-level codes

```proto
// ❌ Bad: app-specific code field
message ErrorResponse {
  int32 app_error_code = 1;  // 1001 = "ad not found", 1002 = "ad locked", ...
  string message = 2;
}

service AdService {
  rpc DeleteAd(DeleteAdRequest) returns (ErrorResponse);  // returns OK, embeds error
}
```

Clients now have to parse two different error schemas (gRPC status code AND your app code). Envoy / load-balancer / retry-budget logic only understands the gRPC code, so app codes are invisible to your platform. Use the canonical code, then attach structured detail via `google.rpc.Status` if needed:

```go
// ✅ Good: canonical code + structured detail
import (
    "google.golang.org/genproto/googleapis/rpc/errdetails"
    "google.golang.org/grpc/status"
)

st := status.New(codes.FailedPrecondition, "ad is serving; pause it first")
detail := &errdetails.PreconditionFailure{
    Violations: []*errdetails.PreconditionFailure_Violation{{
        Type:        "AD_STATE",
        Subject:     "ads/" + req.AdId,
        Description: "ad must be PAUSED before delete",
    }},
}
st, _ = st.WithDetails(detail)
return nil, st.Err()
```

---

## Map upstream errors, don't pass them through raw

When your handler calls a downstream HTTP / SQL / Kafka system, translate its errors into a gRPC code your callers can act on. A SQL `unique_violation` should become `ALREADY_EXISTS`, not `INTERNAL`.

```go
// ✅ Good
_, err := s.db.ExecContext(ctx, insertAdQuery, ad)
if errors.Is(err, pgsql.ErrUniqueViolation) {
    return nil, status.Errorf(codes.AlreadyExists, "ad %q already exists", ad.Id)
}
if err != nil {
    return nil, status.Errorf(codes.Internal, "insert ad: %v", err)
}
```

```go
// ❌ Bad: opaque INTERNAL hides retry semantics from the caller
if err != nil {
    return nil, status.Errorf(codes.Internal, "%v", err)
}
```

---

## Retry-budget rule of thumb

Document for every server which codes it can return, and which of those are retriable. The default gRPC retry policy retries `UNAVAILABLE` only. If your server returns `ABORTED` on transaction conflicts and you want auto-retry, you must configure that in the service config.

---

## Related Rules

- [Deadlines and Timeouts](deadlines-and-timeouts.md) — `DEADLINE_EXCEEDED` propagation
- [Update and FieldMask](update-and-fieldmask.md) — ETag mismatch → `ABORTED`
- [Backward Compatibility Checklist](../governance/backward-compatibility-checklist.md) — error model is part of the contract

---

## References

- [gRPC Status Codes](https://grpc.github.io/grpc/core/md_doc_statuscodes.html)
- [gRPC Official Documentation](https://grpc.io/docs/)
- [AIP-193 — Errors](https://google.aip.dev/193)

<!-- Cross-platform: see AGENTS.md in the repository root for deployment details. -->
