# BSR vs Vendored Protos

UADS today distributes shared protos by vendoring `unityapis` (consumers import the generated Go from the repo, or run `buf generate` against a checked-out copy). The Buf Schema Registry (BSR) is the managed alternative: schemas are published, versioned, and pulled by hash, with generated code available as a pre-built artifact. Both work; the right answer depends on your governance, access-control, and toolchain needs — not on which is newer.

This rule documents the tradeoffs honestly so the team can pick deliberately. It does **not** recommend a migration today.

Source: [Buf Docs](https://buf.build/docs/).

---

## What "vendored protos" means here

```
unityapis (git repo)
├── proto/
│   ├── unityads/ads/sdk/v1/*.proto
│   └── ...
├── buf.yaml
└── gen/
    └── go/                   ← generated code, committed
        └── unityads/ads/sdk/v1/*.pb.go

ads-sdk-gateway (consumer)
└── go.mod                    ← depends on github.com/unity-ads/unityapis
```

Consumers either:

1. Import the generated Go directly (`go get github.com/unity-ads/unityapis/gen/go/...`), or
2. Vendor the raw `.proto` files into their own tree (rare; usually means downstream wants to add codegen options).

Schema distribution is "however git serves a repo."

---

## What BSR means

BSR is a managed schema registry:

- Push schemas with `buf push`. BSR computes a content-addressed digest and an optional semantic version tag.
- Pull dependencies with `buf dep update`, which resolves modules from `buf.build/<owner>/<module>`.
- Generate code from the registry on-demand, or pull pre-built code via Remote Plugins.
- Web UI for browsing schemas, dependencies, and breaking-change history.

```yaml
# Consumer's buf.yaml referencing a BSR module
version: v2
deps:
  - buf.build/unity-ads/unityapis:v1.42.0
```

---

## Tradeoffs

| Dimension | Vendored (`unityapis` today) | BSR |
|---|---|---|
| **Access control** | GitHub repo permissions | BSR org/team permissions; finer-grained per-module |
| **Versioning** | Git tags / SHAs | Content-addressed digests + optional semver tags |
| **Discovery** | Browse the repo on GitHub | Web UI with browsable schema graph |
| **Generated-code distribution** | Commit `.pb.go` (or have each consumer run `buf generate`) | Remote Plugins / Generated SDKs (pull pre-built) |
| **Breaking-change history** | Git log of `.proto` files + `buf breaking` CI | Built-in BSR breaking-change tracker |
| **Toolchain coupling** | None beyond `buf` (optional) | Strong — `buf push`/`pull` are mandatory |
| **Vendor lock-in** | None | Real — schemas live on Buf's hosted service (or self-hosted BSR) |
| **Cost** | Free | Paid plan past the free tier |
| **Offline / air-gapped** | Works | Requires the registry (self-hosted BSR or cached mirror) |

---

## When BSR pays off

Adopt BSR if **multiple** of the following are true:

- You have **many independent consumers** across orgs (10+) and centralised access control matters more than git-native workflows.
- You want **content-addressed dependency pinning** (digest-based) without committing generated code per consumer.
- You want **schema browsability** for non-engineering stakeholders (data team, partners).
- You're willing to take on **vendor lock-in** (or run self-hosted BSR).
- The team has bandwidth for a real migration (BSR isn't a flip-the-switch adoption).

---

## When vendored is the right choice (UADS today)

Stay vendored if:

- All consumers are inside the same GitHub org (UADS today).
- Git is already the source of truth for everything else.
- The current workflow isn't actually painful — the friction is acceptable.
- Engineering capacity for a registry migration would deliver more value elsewhere.

**As of 2026-05-27, UADS is squarely in the "stay vendored" column.** `unityapis` works; consumers are all in-org; the `buf breaking` + `buf lint` CI checks (see sibling rules) already give us the schema-discipline benefits BSR markets, without the migration cost.

Revisit when:

- The number of independent consumers crosses ~15.
- Non-engineering stakeholders need to browse schemas.
- Generated-code distribution becomes painful (e.g. per-consumer codegen drift).

---

## Hybrid: keep vendored, use BSR Remote Plugins selectively

You can use BSR's Remote Plugins (managed code generators) without publishing your schemas there. This is a low-commitment way to taste the ecosystem:

```yaml
# buf.gen.yaml
version: v2
plugins:
  - remote: buf.build/protocolbuffers/go
    out: gen/go
  - remote: buf.build/grpc/go
    out: gen/go
```

Remote Plugins shift the burden of pinning plugin versions off your machine and onto Buf. No schema migration required. Useful if local plugin management is the actual pain point.

---

## Migration sketch (if and when)

If a future decision picks BSR, the migration shape is:

1. Push `unityapis` to BSR as a new module (`buf push`).
2. Add `deps:` entries in consumer `buf.yaml`s alongside the existing import paths.
3. Switch consumers one-by-one to pull from BSR (codegen layout stays the same).
4. After every consumer is migrated, freeze the GitHub repo's `gen/` directory and treat BSR as the source of truth.

Expect this to take weeks per major consumer, not days. Plan accordingly.

---

## Related Rules

- [buf breaking against main](buf-breaking-against-main.md) — what BSR's hosted version of this looks like
- [buf lint in CI](buf-lint-in-ci.md) — same; BSR runs it server-side, vendored runs it in your CI

---

## References

- [Buf Docs](https://buf.build/docs/)
- [Buf Schema Registry](https://buf.build/) — landing page; pricing / hosted-vs-self-hosted

<!-- Cross-platform: see AGENTS.md in the repository root for Cursor, Claude Code, and Copilot paths. -->
