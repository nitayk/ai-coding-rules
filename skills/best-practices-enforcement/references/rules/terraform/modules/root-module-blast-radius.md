# Root Module Blast Radius

Every root module is one state file. One state file is one `apply` target. Any human or pipeline that can `apply` that root can break **every resource it manages**. The blast-radius rule: keep root modules small enough that a worst-case `apply` is recoverable.

Source: [GCP Terraform — Root Modules](https://docs.cloud.google.com/docs/terraform/best-practices/root-modules).

---

## The Rule of Thumb

| Root size (resources) | Status |
|---|---|
| < 30 | Comfortable |
| 30-100 | Acceptable for a single team |
| 100-300 | Warning zone — plan latency hurts, blast radius too wide |
| > 300 | **Split it.** Recovery from a bad apply will exceed any team's tolerance. |

GCP's own guidance puts the soft ceiling at **~100 resources per state**. Other variables that push you toward "split":

- The root spans more than one cloud project / AWS account / Azure subscription.
- The root mixes resources with very different lifecycles (e.g. long-lived VPC + churn-y GKE workloads).
- More than one team has write access.
- Plan times exceed ~5 minutes.

---

## The Split: `modules/` + `environments/<env>/`

The canonical layout — child modules factor repetition, environments factor lifecycle:

```text
# ✅ Good: child modules + per-environment roots
my-product-infra/
├── modules/
│   ├── network/          # child module — VPC, subnets, firewall
│   ├── data-platform/    # child module — Cloud SQL, Pub/Sub, GCS
│   └── workload/         # child module — GKE, services
└── environments/
    ├── dev/
    │   ├── main.tf       # composes modules with dev inputs
    │   ├── backend.tf    # gcs bucket: tf-state-dev/
    │   └── versions.tf
    ├── stg/
    │   ├── main.tf
    │   ├── backend.tf    # gcs bucket: tf-state-stg/
    │   └── versions.tf
    └── prd/
        ├── main.tf
        ├── backend.tf    # gcs bucket: tf-state-prd/
        └── versions.tf
```

Each environment has its own **backend** (separate state file), its own **service account** for applies, and its own pipeline. A bad apply in `dev/` cannot touch `prd/`.

---

## Splitting by Lifecycle, Not Just Environment

Inside a single environment, split further when lifecycles diverge:

```text
# ✅ Good: prd/ split by lifecycle
environments/prd/
├── 00-network/        # rare changes, week-long change windows
├── 10-data-platform/  # monthly changes
├── 20-workload/       # daily changes
└── 30-observability/  # weekly changes
```

Each subdirectory is its own root module with its own state. The numeric prefix encodes apply order for humans (`00-network` first); Terraform does not enforce order between roots — your pipeline does.

Cross-root data flow goes through `data "terraform_remote_state"`:

```hcl
# ✅ Good: workload root reads network outputs from network root
# (in environments/prd/20-workload/main.tf)
data "terraform_remote_state" "network" {
  backend = "gcs"
  config = {
    bucket = "tf-state-prd"
    prefix = "00-network"
  }
}

module "gke" {
  source     = "../../../modules/workload"
  vpc_id     = data.terraform_remote_state.network.outputs.vpc_id
  subnet_ids = data.terraform_remote_state.network.outputs.subnet_ids
}
```

---

## The Anti-pattern: Monorepo Mega-State

```text
# ❌ Bad: one giant root that manages "everything"
infra/
└── main.tf          # 800 resources across 3 GCP projects, 4 environments
```

Symptoms:

- `terraform plan` takes 12+ minutes.
- Every PR shows 200 unrelated lines of plan output.
- A `taint` on the wrong resource brings down production.
- Onboarding a new engineer takes a week because they can't safely run `plan` locally without IAM that lets them break production.

Recovery: extract environment-by-environment using `terraform state mv` (or, for resources moving into a new child module, `moved {}` blocks). Schedule each extraction as its own PR; never bundle.

---

## What to Keep in a Single Root

A single root is the right scope when **all of these** are true:

- One cloud project / account / subscription.
- One team owns every resource.
- All resources have a similar lifecycle (e.g. all part of one application stack).
- Total resource count fits in the "< 100" comfort band.
- All consumers of the outputs are downstream pipelines (not other Terraform roots).

If even one of these breaks, plan the split before the state grows further. Splitting a 50-resource state is straightforward; splitting a 500-resource state is a multi-month project.

---

## State Backend Discipline

Each root gets its own backend prefix. Concrete GCS example:

```hcl
# environments/prd/00-network/backend.tf
terraform {
  backend "gcs" {
    bucket = "tf-state-my-product-prd"
    prefix = "00-network"
  }
}
```

Buckets — one per environment (`tf-state-...-dev`, `-stg`, `-prd`). Bucket-level IAM gates who can `apply` to that environment. Object versioning **on**, retention policy **on**, customer-managed encryption key if your org requires it.

---

## Related Rules

- [Module Structure](module-structure.md) — child module conventions for the `modules/` tree above.
- [Secrets and State](../security/secrets-and-state.md) — what the state file actually contains and why bucket IAM matters.
- [Plan as PR Artifact](../testing/plan-as-pr-artifact.md) — surfacing plan output per-root in CI.

---

## References

- [GCP Terraform — Root Modules](https://docs.cloud.google.com/docs/terraform/best-practices/root-modules)
- [GCP Terraform — Operations](https://docs.cloud.google.com/docs/terraform/best-practices/operations)

<!-- Cross-platform: see AGENTS.md in the repository root for deployment details. -->
