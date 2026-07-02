# Resource Naming (AIP-122)

Every resource has a unique, hierarchical, server-assigned `name` string. The convention is `collection/{id}/sub_collection/{id}/...`. Once adopted, every standard method (Get, List, Create, Update, Delete) follows from the name shape — and tooling (AIP-linter, gRPC-gateway, OpenAPI generators) can derive URL paths automatically.

Source: [AIP-122 — Resource Names](https://google.aip.dev/122).

---

## The pattern

```proto
message Ad {
  // Format: ads/{ad}
  // Example: ads/abc-123
  string name = 1;
  // ... other fields ...
}

message Creative {
  // Format: ads/{ad}/creatives/{creative}
  // Example: ads/abc-123/creatives/banner-v2
  string name = 1;
  // ... other fields ...
}
```

The `name` is **the** identifier. Don't add a separate `id` field; the trailing segment of the name is the id, and tooling extracts it for you when needed.

---

## Collection IDs

| Element | Convention | Example |
|---|---|---|
| Collection ID | `lowerCamelCase`, **plural** | `ads`, `creatives`, `gamerProfiles` |
| Resource ID | URL-safe (`[A-Za-z0-9._~-]+`), server- or client-supplied per the resource policy | `abc-123`, `banner-v2` |
| Singleton sub-resource | Singular, no `{id}` | `users/me/settings` (not `users/me/settings/{settings}`) |

```proto
// ✅ Good
message GamerProfile {
  // Format: gamerProfiles/{gamerProfile}
  string name = 1;
}

// ❌ Bad: snake_case collection, singular form
message GamerProfile {
  // Format: gamer_profile/{id}
  string name = 1;
}
```

`buf lint` does not enforce the collection-ID casing on its own — the AIP linter (`api-linter`) does. Run both in CI on `apis`.

---

## Standard methods take the `name` directly

Every standard method has a predictable request shape. The naming carries the routing.

```proto
service AdService {
  rpc GetAd(GetAdRequest) returns (Ad);
  rpc ListAds(ListAdsRequest) returns (ListAdsResponse);
  rpc CreateAd(CreateAdRequest) returns (Ad);
  rpc UpdateAd(UpdateAdRequest) returns (Ad);
  rpc DeleteAd(DeleteAdRequest) returns (google.protobuf.Empty);  // ← see note below
}

message GetAdRequest {
  // Required. Format: ads/{ad}
  string name = 1;
}

message ListAdsRequest {
  // For top-level collections this is empty; for nested it's the parent.
  // Format: (top-level) or "parents/{parent}"
  string parent = 1;
  int32 page_size = 2;
  string page_token = 3;
}

message CreateAdRequest {
  string parent = 1;        // empty for top-level
  string ad_id = 2;         // optional client-suggested ID
  Ad ad = 3;
}

message DeleteAdRequest {
  // Required. Format: ads/{ad}
  string name = 1;
}
```

(Per `../schema/avoid-empty-rpc-messages.md`, prefer a concrete `DeleteAdResponse {}` over `google.protobuf.Empty`. AIP-135 allows Empty for Delete but accepting a concrete type costs nothing and is forward-compatible.)

---

## Parent paths and nested collections

Nested resources include the parent path in `name`. The `parent` field on List/Create requests is the parent's name.

```proto
// Creative lives under an Ad
message Creative {
  // Format: ads/{ad}/creatives/{creative}
  string name = 1;
}

message ListCreativesRequest {
  // Format: ads/{ad}
  string parent = 1;
  int32 page_size = 2;
  string page_token = 3;
}

message CreateCreativeRequest {
  // Format: ads/{ad}
  string parent = 1;
  string creative_id = 2;
  Creative creative = 3;
}
```

Listing all creatives across all ads is allowed via `parent = "ads/-"` (the wildcard segment — AIP-159).

---

## Resource-name validation

A server that accepts a malformed `name` returns `INVALID_ARGUMENT`. Validate on entry; never let a bogus name reach your store.

```go
// ✅ Good: validate format, return INVALID_ARGUMENT
var adNameRe = regexp.MustCompile(`^ads/[A-Za-z0-9._~-]+$`)

func parseAdName(name string) (string, error) {
    if !adNameRe.MatchString(name) {
        return "", status.Errorf(codes.InvalidArgument,
            "name %q does not match format ads/{ad}", name)
    }
    return strings.TrimPrefix(name, "ads/"), nil
}
```

---

## Don't expose the storage primary key as the resource ID without thinking

The resource ID is a **public** part of your API. If you use a database autoincrement integer, you're publishing your row count. If you use a UUID, you're committing to that UUID forever. Pick a deliberate ID strategy:

- **UUID v4 / ULID**: opaque, stable, sortable (ULID), no information leak. Safe default.
- **Slug**: human-readable, client-chosen (with uniqueness check). Good for user-facing entities.
- **Hash of canonical fields**: deterministic, good for content-addressed resources.

`buf breaking` cannot help here — changing your ID scheme is a hard break for every existing reference.

---

## Resource-name aliases (AIP-122 "the special `-` id")

Some collections support `-` as a wildcard segment for "across all" semantics: `ads/-/creatives` lists all creatives under any ad. Document explicitly which collections support it; treat it as a feature, not a default.

---

## Related Rules

- [Pagination](pagination-aip.md) — AIP-158 page_token / page_size for List
- [Update and FieldMask](update-and-fieldmask.md) — AIP-134 partial updates by resource name
- [Long-Running Operations](long-running-operations.md) — AIP-151 LRO names

---

## References

- [AIP-122 — Resource Names](https://google.aip.dev/122)
- [AIP-135 — Delete](https://google.aip.dev/135)
- [AIP-159 — Reading across collections](https://google.aip.dev/159)
- [Google API Improvement Proposals](https://google.aip.dev/)

<!-- Cross-platform: see AGENTS.md in the repository root for deployment details. -->
