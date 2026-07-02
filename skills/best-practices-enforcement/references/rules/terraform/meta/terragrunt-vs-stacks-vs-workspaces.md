# Terragrunt vs Stacks vs Workspaces

Three different problems, three different tools. Confusion between them is the most common Terraform-architecture mistake.

| Tool | Problem it solves | Where it runs |
|---|---|---|
| **Workspaces** | Multiple parallel state files from one config | OSS CLI (both TF and OpenTofu) |
| **Terragrunt** | DRY across many root modules / environments | OSS CLI (wraps `terraform`/`tofu`) |
| **Stacks** | Dependency-ordered multi-root deployments | HCP Terraform / Terraform Enterprise only |

Source: [Spacelift — Terragrunt vs Terraform](https://spacelift.io/blog/terragrunt-vs-terraform), [Terraform — Workspaces](https://developer.hashicorp.com/terraform/language/state/workspaces), [Terraform Stacks](https://developer.hashicorp.com/terraform/language/stacks).

---

## Workspaces — Cheap Ephemeral Parallels

A workspace is just a named state file under one config. Switching workspaces switches which state Terraform reads/writes; the HCL is identical.

```bash
terraform workspace new pr-1234
terraform workspace select pr-1234
terraform apply -var="env=pr-1234"
# ... PR closes ...
terraform workspace select default
terraform workspace delete pr-1234
```

**Use workspaces for:**

- **PR preview environments** — one workspace per PR, torn down on merge/close.
- **Ephemeral test environments** in CI.
- **Per-region duplicates** of an otherwise identical stack (one workspace per region).

**Do NOT use workspaces for:**

- ❌ Persistent environments (dev/stg/prd). They'll all share `versions.tf`, `provider {}` config, and worst — they'll all silently get the same change when someone runs `apply` from the wrong workspace.

The HashiCorp guidance is explicit: "we do not recommend using workspaces to model permanent, structurally-identical environments." Use the `environments/<env>/` directory layout instead — see `modules/root-module-blast-radius.md`.

```hcl
# ✅ Good: workspace for an ephemeral PR preview
resource "google_sql_database_instance" "preview" {
  count = terraform.workspace == "default" ? 0 : 1
  name  = "pr-${terraform.workspace}"
  # ...
}

# ❌ Bad: workspace gates the entire prd vs dev distinction
resource "google_container_cluster" "this" {
  name = terraform.workspace == "prd" ? "prod-cluster" : "dev-cluster"
  # ... fragile, one wrong workspace away from production
}
```

---

## Terragrunt — DRY for OSS Multi-Env

Terragrunt is a thin wrapper around `terraform` / `tofu` that solves the "every `environments/<env>/main.tf` looks the same with three values swapped" problem. It generates the `provider {}`, `backend {}`, and `module {}` blocks from a single source.

```hcl
# ✅ Good: terragrunt.hcl factors out backend + provider config
# environments/prd/00-network/terragrunt.hcl
include "root" {
  path = find_in_parent_folders()
}

inputs = {
  vpc_cidr     = "10.0.0.0/16"
  project_id   = "my-prd-project"
}

terraform {
  source = "git::https://github.com/example/terraform-modules.git//network?ref=v1.4.0"
}
```

```hcl
# environments/terragrunt.hcl — the parent that sets backend + provider
remote_state {
  backend = "gcs"
  generate = {
    path      = "backend.tf"
    if_exists = "overwrite"
  }
  config = {
    bucket = "tf-state-${path_relative_to_include()}"
    prefix = path_relative_to_include()
  }
}
```

**Use Terragrunt when:**

- You have **many** root modules (≥ 5) and the boilerplate is unmaintainable.
- You're on **OSS Terraform or OpenTofu** (no HCP).
- You want explicit dependency wiring via `dependency {}` blocks.
- The team is willing to invest in learning Terragrunt's HCL dialect.

**Do NOT reach for Terragrunt when:**

- You have 1-3 root modules — the boilerplate is fine, Terragrunt adds complexity for no gain.
- You're on HCP — Stacks is the HCP-native alternative.
- Your team is already overwhelmed by Terraform itself. Terragrunt is a second tool to learn.

---

## Stacks — HCP-Only Dependency Graphs

Stacks (GA 2025, HCP/Enterprise only) bundle multiple Terraform configurations ("components") into a single deployment unit with explicit dependencies and shared inputs.

```hcl
# components.tfstack.hcl (HCP only)
component "network" {
  source = "./network"
  inputs = { project_id = var.project_id }
}

component "cluster" {
  source = "./cluster"
  inputs = {
    project_id = var.project_id
    vpc_id     = component.network.vpc_id  # dependency
  }
}

component "workloads" {
  source = "./workloads"
  inputs = {
    cluster_endpoint = component.cluster.endpoint
  }
}
```

**Use Stacks when:**

- You're already on HCP Terraform or Terraform Enterprise.
- You have a real dependency graph between roots (network → cluster → workloads) that's currently glued together by `terraform_remote_state` data sources.
- You want HCP's deployment-orchestration UI for multi-root rollouts.

**Do NOT use Stacks if:**

- You're not on HCP. There is no OSS equivalent.
- You're on OpenTofu. No equivalent there either.
- You have ≤ 3 roots — the value is in coordinating many.

---

## Decision Matrix

| Situation | Tool |
|---|---|
| Ephemeral PR-preview infra | Workspaces |
| Per-region duplicates of one stack | Workspaces (one per region) |
| dev / stg / prd, ≤ 3 roots per env, OSS | Plain `environments/<env>/` directories |
| dev / stg / prd, many roots per env, OSS | Terragrunt |
| HCP user, multi-root deployment with cross-root dependencies | Stacks |
| HCP user, ≤ 3 roots, no real dependencies | Plain config; Stacks is overkill |
| OSS, want dependency-ordered apply across roots | Terragrunt `dependencies {}` block OR CI pipeline ordering |

---

## Don't Stack These Tools Together

Each tool has its own idioms. Combining them produces unmaintainable hybrids:

```text
# ❌ Bad: Terragrunt + workspaces for environments
environments/
└── terragrunt.hcl   # uses workspaces for env distinction (terragrunt.workspace == "prd")
```

```text
# ❌ Bad: Stacks + Terragrunt
# Stacks already provides multi-component orchestration; layering Terragrunt
# on top means two competing definitions of "which root runs in what order".
```

Pick one strategy per estate. Document the choice.

---

## What About `terraform_remote_state`?

A `data "terraform_remote_state"` block is the **plain-Terraform** way to read outputs from another root. It scales to a few cross-root references but breaks down when:

- Many components reference many other components (you write the dependency graph by hand in every consumer).
- The producer renames an output — every consumer breaks at next plan.
- You want CI to apply roots in dependency order (you have to encode the order in the pipeline yourself).

When `terraform_remote_state` becomes painful, that's the signal you've outgrown plain Terraform for that estate — at which point Terragrunt (OSS) or Stacks (HCP) becomes worth the complexity.

---

## Anti-patterns

```bash
# ❌ Bad: workspaces for production environment separation
terraform workspace select prd
# (one typo in CI and you're applying dev's plan to prd's state)
```

```hcl
# ❌ Bad: Terragrunt with 100+ environments hand-rolled
# environments/customer-a-prd/, customer-a-stg/, customer-b-prd/, ...
# (this is a tenant-provisioning problem; build a project-factory module instead)
```

---

## Related Rules

- [Root Module Blast Radius](../modules/root-module-blast-radius.md) — the `environments/<env>/` layout you'd use without Terragrunt or Stacks.
- [OpenTofu vs Terraform Compatibility](opentofu-vs-terraform-compatibility.md) — Stacks is Terraform-only; affects this choice.
- [Plan as PR Artifact](../testing/plan-as-pr-artifact.md) — works the same regardless of which orchestration tool you pick.

---

## References

- [Spacelift — Terragrunt vs Terraform](https://spacelift.io/blog/terragrunt-vs-terraform)
- [Terraform — Workspaces](https://developer.hashicorp.com/terraform/language/state/workspaces)
- [Terraform — Stacks](https://developer.hashicorp.com/terraform/language/stacks)
- [Terragrunt — Docs](https://terragrunt.gruntwork.io/docs/)
