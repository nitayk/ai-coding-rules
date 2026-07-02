# Update Methods and FieldMask

Update is the RPC where every schema-design mistake compounds. Without an explicit `update_mask`, a client that sends `name = ""` is ambiguous — did they mean "clear the name" or "I didn't touch the name field, please ignore"? AIP-134 settles this by mandating `google.protobuf.FieldMask` and a small set of accompanying conventions: presence semantics, full-resource request, etag for concurrency, and `allow_missing` for upsert.

Source: [AIP-134 — Update](https://google.aip.dev/134). (AIP-134 supersedes the [Netflix "Practical API Design" 2021 blog post](https://netflixtechblog.com/practical-api-design-at-netflix-part-1-using-protobuf-fieldmask-35cfdc606518) as the citable source.)

---

## The canonical shape

```proto
import "google/protobuf/field_mask.proto";

message UpdateAdRequest {
  // The full resource. The server replaces ONLY the paths named in update_mask.
  Ad ad = 1;

  // Required. The set of field paths the client wants the server to update.
  // Wildcard `*` is interpreted as full replacement (PUT semantics).
  google.protobuf.FieldMask update_mask = 2;

  // Optional. If true, the server MAY create the resource if it does not exist.
  bool allow_missing = 3;
}

service AdService {
  rpc UpdateAd(UpdateAdRequest) returns (Ad);
}
```

The HTTP mapping (when exposed via gRPC-gateway / Envoy gRPC-JSON transcoder) is `PATCH`, not `PUT` — a partial update.

---

## How `update_mask` resolves the "is empty meaningful?" problem

The mask is the **only** source of truth for which fields the client intends to change. The request payload is otherwise treated as "current desired state for these paths."

```go
// ✅ Good: mask-driven update
func (s *AdService) UpdateAd(ctx context.Context, req *pb.UpdateAdRequest) (*pb.Ad, error) {
    if req.GetUpdateMask() == nil {
        return nil, status.Error(codes.InvalidArgument, "update_mask is required")
    }
    existing, err := s.store.Get(ctx, req.GetAd().GetId())
    if err != nil { return nil, err }

    // Apply only the paths the client asked for. fieldmaskpb / fmutils handles nested paths.
    for _, path := range req.GetUpdateMask().GetPaths() {
        if err := fmutils.Filter(req.GetAd(), []string{path}); err != nil {
            return nil, status.Errorf(codes.InvalidArgument, "invalid path %q: %v", path, err)
        }
        applyPath(existing, req.GetAd(), path)
    }
    return s.store.Save(ctx, existing)
}
```

The contract this enforces:

| Client sends | Mask includes the field | Result |
|---|---|---|
| `name = "Foo"` | yes | name becomes "Foo" |
| `name = ""` | yes | name becomes "" (explicit clear) |
| `name = "Foo"` | no | name unchanged |
| `name = ""` | no | name unchanged |

---

## Always reject an empty `update_mask`

An empty mask is ambiguous: AIP-134 lets you treat it as "update all populated fields," but in practice that's a foot-gun for clients that built a request struct in-place and forgot a field. **Require the mask to be non-empty** and let the client opt into full replacement with `update_mask = {paths: ["*"]}`.

```go
// ✅ Good: reject empty mask, accept explicit "*"
if len(req.GetUpdateMask().GetPaths()) == 0 {
    return nil, status.Error(codes.InvalidArgument, "update_mask must list at least one path (or [\"*\"] for full replacement)")
}
```

---

## ETags for optimistic concurrency

If two clients can update the same resource concurrently, attach an `etag` to the resource and require it in the request. A mismatched etag → `ABORTED` (the client should re-read and retry).

```proto
message Ad {
  string id = 1;
  string name = 2;
  // ... other fields ...

  // Server-managed concurrency token. Returned on every read; required on write.
  string etag = 99;
}
```

```go
// ✅ Good: etag-checked write
existing, err := s.store.Get(ctx, req.GetAd().GetId())
if err != nil { return nil, err }
if req.GetAd().GetEtag() != existing.GetEtag() {
    return nil, status.Errorf(codes.Aborted,
        "ad %q was modified; re-read and retry", req.GetAd().GetId())
}
```

Without etags, a "last writer wins" update silently overwrites a concurrent edit — usually discovered weeks later as data corruption.

---

## `allow_missing` for upsert semantics

If the client legitimately doesn't know whether the resource exists (think configuration sync), let them opt into upsert. Without `allow_missing`, the server MUST return `NOT_FOUND` for an unknown resource.

```go
// ✅ Good
existing, err := s.store.Get(ctx, id)
if errors.Is(err, store.ErrNotFound) {
    if !req.GetAllowMissing() {
        return nil, status.Errorf(codes.NotFound, "ad %q not found", id)
    }
    return s.store.Create(ctx, req.GetAd())
}
```

---

## Full request anti-patterns

### Two parallel `Update` RPCs

```proto
// ❌ Bad: two RPCs for one concept
service AdService {
  rpc UpdateAdName(UpdateAdNameRequest) returns (Ad);
  rpc UpdateAdBudget(UpdateAdBudgetRequest) returns (Ad);
}
```

Each per-field RPC is its own contract you'll have to maintain, version, and break separately. One `UpdateAd(ad, mask)` covers all field combinations forever.

### `Update` returns `Empty`

```proto
// ❌ Bad
rpc UpdateAd(UpdateAdRequest) returns (google.protobuf.Empty);
```

Returning the updated `Ad` lets the client refresh its local copy (and read the new `etag`) without a follow-up `GetAd`. See `../schema/avoid-empty-rpc-messages.md`.

### Treating absent fields as "clear"

```go
// ❌ Bad: ignores the mask, treats empty string as "set to empty"
existing.Name = req.GetAd().GetName()
existing.Description = req.GetAd().GetDescription()
```

This is the exact ambiguity FieldMask is meant to solve. Honor the mask.

---

## When you genuinely want full replacement: model it explicitly

```proto
// ✅ Good: PUT semantics is a separate RPC; the contract is unambiguous
service AdService {
  rpc ReplaceAd(ReplaceAdRequest) returns (Ad);
}

message ReplaceAdRequest {
  Ad ad = 1;
  string etag = 2;
}
```

Or accept `update_mask = ["*"]` on `UpdateAd` and document the convention; either choice is fine. What matters is not silently flipping semantics based on whether the mask happened to be omitted.

---

## Related Rules

- [Status Codes and Errors](status-codes-and-errors.md) — `ABORTED` for etag mismatch, `NOT_FOUND` for unknown resource
- [Resource Naming](resource-naming-aip.md) — AIP-122 resource paths used in the resource `name`/`id`
- [Avoid Empty RPC Messages](../schema/avoid-empty-rpc-messages.md) — Update should return the resource, not Empty

---

## References

- [AIP-134 — Update](https://google.aip.dev/134)
- [AIP-154 — Resource freshness validation (etag)](https://google.aip.dev/154)
- [AIP-180 — Backwards Compatibility](https://google.aip.dev/180)

<!-- Cross-platform: see AGENTS.md in the repository root for deployment details. -->
