# Pagination (AIP-158)

Any RPC that returns a collection MUST paginate from day one. Retrofitting pagination is a breaking change — older clients fetched everything and assumed completeness; newer clients fetch a page and assume there's more. AIP-158 standardises on **cursor-based pagination** via `page_token` / `page_size` because cursors survive concurrent writes that would break offset pagination.

Source: [AIP-158 — Pagination](https://google.aip.dev/158).

---

## The canonical shape

```proto
message ListAdsRequest {
  // Optional parent (for nested collections); empty for top-level.
  string parent = 1;

  // The maximum number of results to return.
  // If unspecified, the server picks a default (typically 50).
  // If larger than the maximum allowed (typically 1000), the server caps it.
  int32 page_size = 2;

  // The page token returned from a previous call. Empty for the first page.
  string page_token = 3;
}

message ListAdsResponse {
  repeated Ad ads = 1;

  // Token for the next page. Empty when there are no more results.
  string next_page_token = 2;

  // Optional. Total count of results (only if cheap to compute; many backends omit).
  int32 total_size = 3;
}

service AdService {
  rpc ListAds(ListAdsRequest) returns (ListAdsResponse);
}
```

---

## Why cursor and not offset

Offset pagination (`?page=3&size=50`) breaks the moment another writer inserts or deletes a row between requests. Cursor pagination encodes the position into an opaque server-managed token, so:

- New rows inserted after the cursor are visible on the next page.
- Deleted rows are simply skipped.
- The client never sees duplicates or misses items in steady-state.

```proto
// ❌ Bad: offset pagination — duplicates and missed rows under concurrent writes
message ListAdsRequest {
  int32 page = 1;
  int32 page_size = 2;
}
```

```proto
// ✅ Good: cursor pagination — stable under writes
message ListAdsRequest {
  string page_token = 1;
  int32 page_size = 2;
}
```

---

## Server-side defaults and caps

Pick sensible defaults and **document them**:

| Setting | Common value | Why |
|---|---|---|
| Default `page_size` | 50 | Sized for typical UI list views |
| Maximum `page_size` | 1000 | Caps memory / latency per call |
| Behaviour on `page_size = 0` | use default | Treat 0 as "unspecified" |
| Behaviour on `page_size > max` | clamp silently to max | Don't error; just cap (AIP-158) |

```go
// ✅ Good: clamp, never error
func resolvePageSize(req *pb.ListAdsRequest) int32 {
    const defaultSize, maxSize int32 = 50, 1000
    n := req.GetPageSize()
    if n <= 0 { return defaultSize }
    if n > maxSize { return maxSize }
    return n
}
```

---

## The `next_page_token` is opaque to the client

The client treats it as a black-box string. The server is free to encode anything (last-row primary key, base64'd cursor struct, encrypted offset). Two rules:

1. **Sign or encrypt** the token if it embeds sensitive data (e.g. internal row IDs).
2. **Be stable across deploys** — a token issued by version N must still parse in version N+1. Versioning the token (`v1:...`) is cheap insurance.

```go
// ✅ Good: versioned, base64-encoded cursor
type cursor struct {
    Version  string    `json:"v"`
    LastID   string    `json:"id"`
    LastSeen time.Time `json:"ts"`
}

func encodeCursor(c cursor) string {
    b, _ := json.Marshal(c)
    return "v1:" + base64.URLEncoding.EncodeToString(b)
}
```

```go
// ❌ Bad: raw integer offset — leaks internals, can't evolve schema
func encodeCursor(offset int64) string {
    return strconv.FormatInt(offset, 10)
}
```

---

## Empty `next_page_token` means "no more pages"

The client's termination condition is `next_page_token == ""`. Never return a token that, when followed, returns zero results — that wastes a round trip and confuses naive clients.

```go
// ✅ Good
results, hasMore := s.store.Page(ctx, req.PageToken, pageSize)
resp := &pb.ListAdsResponse{Ads: results}
if hasMore && len(results) > 0 {
    resp.NextPageToken = encodeCursor(...)
}
return resp, nil
```

---

## `total_size` is optional and often expensive

Including a total count requires a separate count query that doesn't benefit from the cursor optimisation. AIP-158 leaves it optional. Default to omitting it; add it only if the backend can compute it cheaply (e.g. a maintained counter, or a small enough dataset).

If you do include it, document that the count is a **snapshot at query time** and can drift if rows are added/removed between pages.

---

## Page size in the request, not in the URL path

Anti-pattern from old REST conventions:

```
// ❌ Bad: page size baked into a path component
/v1/ads/page/3
```

Pagination parameters belong in the request message (or URL query string for gRPC-gateway). Path components belong to the resource hierarchy.

---

## When the resource collection is small enough to never page

Still implement `page_token` / `page_size` — and just return everything in one page (no `next_page_token`). The day the collection grows, you don't have to break the contract. Clients should handle a single page transparently.

---

## Stable ordering is part of the contract

Cursor pagination requires the underlying ordering to be stable for the duration of a paged scan. If the natural sort key is non-unique (e.g. by `created_at` only), use a compound key (`created_at` + `id`) so the cursor can resume unambiguously.

---

## Related Rules

- [Resource Naming](resource-naming-aip.md) — `parent` field shape on ListRequest
- [Deadlines and Timeouts](deadlines-and-timeouts.md) — per-page deadlines on long scans
- [Status Codes and Errors](status-codes-and-errors.md) — `INVALID_ARGUMENT` for malformed page_token

---

## References

- [AIP-158 — Pagination](https://google.aip.dev/158)
- [AIP-132 — Standard methods: List](https://google.aip.dev/132)

<!-- Cross-platform: see AGENTS.md in the repository root for deployment details. -->
