# `moved` Blocks for Refactoring

Before Terraform 1.1, renaming a resource (or moving it into a module) meant either `terraform state mv` shell commands run manually (untracked, error-prone) or destroy-recreate (destructive). The `moved {}` block makes refactors **declarative, code-reviewable, and reversible**.

Source: [Terraform — `moved` block reference](https://developer.hashicorp.com/terraform/language/modules/develop/refactoring).

---

## The Pattern

A `moved` block tells Terraform "the resource that used to be addressed at `from` is now at `to` — don't plan to destroy and recreate, just update state to the new address."

```hcl
# ✅ Good: rename via moved block
resource "google_storage_bucket" "data_lake" {  # was "data"
  name = "${var.project_id}-data-lake"
}

moved {
  from = google_storage_bucket.data
  to   = google_storage_bucket.data_lake
}
```

`terraform plan` after this change must show **0 to add, 0 to change, 0 to destroy**, plus the moved entry. If it shows any destructive action, the `moved` block is wrong — abort and fix it.

---

## Common Refactor Patterns

### 1. Rename a resource

```hcl
# Before: resource "google_sql_database_instance" "db" { ... }
# After:
resource "google_sql_database_instance" "primary" {
  # ...
}

moved {
  from = google_sql_database_instance.db
  to   = google_sql_database_instance.primary
}
```

### 2. Extract resources into a child module

```hcl
# Before (in root main.tf):
# resource "google_compute_network" "vpc" { ... }
# resource "google_compute_subnetwork" "subnet" { ... }
#
# After: those resources moved into ./modules/network/main.tf
module "network" {
  source = "./modules/network"
  # ...
}

moved {
  from = google_compute_network.vpc
  to   = module.network.google_compute_network.vpc
}

moved {
  from = google_compute_subnetwork.subnet
  to   = module.network.google_compute_subnetwork.subnet
}
```

### 3. `count` → `for_each` migration

```hcl
# Before:
# resource "google_compute_instance" "web" {
#   count = length(var.servers)
#   name  = var.servers[count.index]
# }
#
# After:
resource "google_compute_instance" "web" {
  for_each = toset(var.servers)
  name     = each.key
}

moved {
  from = google_compute_instance.web[0]
  to   = google_compute_instance.web["web-a"]
}

moved {
  from = google_compute_instance.web[1]
  to   = google_compute_instance.web["web-b"]
}
```

### 4. Move a resource between modules

```hcl
moved {
  from = module.old_network.google_compute_network.vpc
  to   = module.new_network.google_compute_network.vpc
}
```

---

## Workflow

1. Make the structural change to the HCL (rename / extract / restructure).
2. Add `moved {}` blocks for every changed address.
3. Run `terraform plan` — confirm **no destructive actions** plus the move entries.
4. Commit the change with the `moved` blocks in place.
5. Run `terraform apply` (or merge the PR — see `testing/plan-as-pr-artifact.md`).
6. In a **follow-up PR**, delete the `moved` blocks once every workspace consuming the module has applied the move.

Step 6 matters for shared modules: a downstream consumer that has not yet applied the move will see a destructive plan if the `moved` block is deleted prematurely.

---

## What `moved` Cannot Do

`moved` works only within a single state file. It does not:

- Move resources **between** state files / workspaces — use `terraform state mv` with a remote state import, or a one-shot script. Document the operation in the PR.
- Move resources across providers (e.g. `aws_*` → `google_*`) — that is a different resource type; you must destroy and recreate.
- Change a resource's type within the same provider (e.g. `google_compute_instance` → `google_compute_instance_template`) — also destroy and recreate.

---

## Anti-patterns

```hcl
# ❌ Bad: rename without a moved block — Terraform will destroy + recreate
resource "google_sql_database_instance" "primary" {  # was "db"
  # ...
}
# (no moved block)
```

```bash
# ❌ Bad: do the move via manual shell commands, no audit trail
terraform state mv \
  google_sql_database_instance.db \
  google_sql_database_instance.primary
```

The state-mv form works, but the change is invisible in `git log` and unreviewable in a PR. `moved` blocks are the auditable equivalent.

---

## Compatibility Note

`moved` requires Terraform **1.1+** / OpenTofu **1.6+**. If your `versions.tf` pins below that, upgrade first — there is no acceptable workaround that preserves the state without manual `state mv`.

---

## References

- [Terraform — Refactoring with `moved` blocks](https://developer.hashicorp.com/terraform/language/modules/develop/refactoring)
- [Terraform Pilot — `moved` block explained](https://www.terraformpilot.com/articles/terraform-moved-block-explained/)

<!-- Cross-platform: see AGENTS.md in the repository root for Cursor, Claude Code, and Copilot paths. -->
