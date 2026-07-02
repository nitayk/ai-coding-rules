# Prefer `terraform-google-modules` (CFT)

The [terraform-google-modules](https://github.com/terraform-google-modules) GitHub org — also called the **Cloud Foundation Toolkit (CFT)** — is Google's opinionated, actively-maintained set of Terraform modules for GCP. For the primitives it covers, it is almost always the right starting point over a hand-rolled equivalent.

Source: [terraform-google-modules org](https://github.com/terraform-google-modules), [GCP Terraform — Reusable Modules](https://docs.cloud.google.com/docs/terraform/best-practices/reusable-modules).

---

## What CFT Covers (Don't Reinvent)

The flagship modules — each its own repo, each tagged with SemVer releases:

| Module | What it provisions |
|---|---|
| `terraform-google-kubernetes-engine` | GKE clusters (public, private, beta, autopilot variants) |
| `terraform-google-project-factory` | Projects with billing, APIs, default IAM, shared VPC attachment |
| `terraform-google-network` | VPCs, subnets, routes, firewall rules |
| `terraform-google-iam` | IAM bindings, custom roles, service accounts |
| `terraform-google-cloud-storage` | GCS buckets with the right defaults (uniform access, versioning, lifecycle) |
| `terraform-google-sql-db` | Cloud SQL instances (Postgres, MySQL, SQL Server) |
| `terraform-google-pubsub` | Pub/Sub topics + subscriptions + IAM |
| `terraform-google-vault` | Vault on GKE (auto-init, auto-unseal via KMS) |
| `terraform-example-foundation` | Full landing-zone reference (multi-project, hub-and-spoke VPC, org policies) |

When you need any of these — start with the CFT module. The maintainers test against the current Google provider, ship security defaults, and bake in Google's own opinions about quotas, retries, and IAM minimum sets.

---

## ✅ Good: Consume a CFT Module by Pinned Tag

```hcl
# ✅ Good: GKE via CFT, pinned to a released tag
module "gke" {
  source  = "terraform-google-modules/kubernetes-engine/google//modules/private-cluster"
  version = "~> 32.0"  # registry pessimistic constraint

  project_id   = var.project_id
  name         = "my-cluster"
  region       = var.region
  network      = module.network.network_name
  subnetwork   = module.network.subnets_names[0]
  ip_range_pods     = "pods"
  ip_range_services = "services"

  release_channel = "REGULAR"

  node_pools = [
    {
      name         = "default"
      machine_type = "e2-standard-4"
      min_count    = 1
      max_count    = 5
    },
  ]
}
```

The registry source (`terraform-google-modules/kubernetes-engine/google`) supports `version = "~> X.Y"`, giving you patch + minor updates while pinning the major.

Git-source form is also fine:

```hcl
module "gke" {
  source = "git::https://github.com/terraform-google-modules/terraform-google-kubernetes-engine.git//modules/private-cluster?ref=v32.0.1"
  # ...
}
```

---

## ❌ Bad: Hand-Roll What CFT Already Does

```hcl
# ❌ Bad: 400 lines of bespoke GKE config that re-derives what CFT ships
resource "google_container_cluster" "this" {
  name     = "my-cluster"
  location = var.region
  # ... 50+ attributes, easy to miss security defaults
  private_cluster_config { ... }
  workload_identity_config { ... }
  release_channel { ... }
  master_authorized_networks_config { ... }
  # ... etc
}

resource "google_container_node_pool" "default" {
  # ... another 80 lines
}
```

Even if your config "works", you've signed up to track every breaking change in the `google_container_cluster` resource yourself, audit every default against CIS / org policy, and re-derive the right autoscaler / shielded-nodes / release-channel knobs each time a new feature lands.

CFT does this work for you. Use it.

---

## When Hand-Rolling Is Defensible

CFT modules are opinionated. If your need genuinely lies outside those opinions, hand-rolling is fine — but document why:

- A resource type CFT does not cover.
- An attribute combination CFT explicitly does not support (and an issue + workaround in the CFT repo confirms it).
- A bug in the CFT module that blocks you, where a custom version is faster than waiting for the upstream fix. **Plan to migrate to upstream once the fix ships.**

"It's simpler" or "the CFT module has too many inputs" usually isn't true once you've replicated the security defaults.

---

## Pinning Discipline

CFT modules follow SemVer. A typical pinning policy:

| Stack | Pin form |
|---|---|
| Long-lived production root | `version = "~> 32.0"` (patches + minors auto) |
| Compliance-critical / regulated | `version = "32.0.4"` (exact, bump by PR) |
| Greenfield / dev | `version = "~> 32"` (entire major) |

Read the CHANGELOG before any major bump (`32.x` → `33.x`). CFT's major bumps are typically tied to a Google provider major bump or a CIS-policy realignment, and they almost always require config changes.

---

## CFT + Workload Identity Federation

The CFT `kubernetes-engine` module supports Workload Identity natively:

```hcl
module "gke" {
  source  = "terraform-google-modules/kubernetes-engine/google//modules/private-cluster"
  version = "~> 32.0"

  workload_identity_config = {
    workload_pool = "${var.project_id}.svc.id.goog"
  }
}
```

This is the pattern to standardise on for in-cluster GCP API access. See `gcp/workload-identity-federation.md` for the broader CI ↔ GCP federation pattern.

---

## Discovery

For a primitive you're about to build:

1. Search the [terraform-google-modules org](https://github.com/terraform-google-modules) for `terraform-google-<thing>`.
2. Check the Terraform Registry: `https://registry.terraform.io/modules/terraform-google-modules`.
3. If a module exists, read its README's "Inputs" table — if 80%+ of what you need is covered, use it.
4. If not, file an issue or PR upstream before forking. CFT accepts contributions.

---

## Related Rules

- [Workload Identity Federation](workload-identity-federation.md) — CI ↔ GCP auth, the CFT-recommended pattern.
- [GKE Cluster Conventions](gke-cluster-conventions.md) — opinions on top of the CFT GKE module.
- [Module Structure](../modules/module-structure.md) — your hand-rolled modules should follow the same shape CFT does.

---

## References

- [terraform-google-modules (GitHub org)](https://github.com/terraform-google-modules)
- [CFT GKE module](https://github.com/terraform-google-modules/terraform-google-kubernetes-engine)
- [terraform-example-foundation](https://github.com/terraform-google-modules/terraform-example-foundation)
- [GCP Terraform — Reusable Modules](https://docs.cloud.google.com/docs/terraform/best-practices/reusable-modules)

<!-- Cross-platform: see AGENTS.md in the repository root for Cursor, Claude Code, and Copilot paths. -->
