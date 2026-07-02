# `import` Blocks (Declarative)

Before Terraform 1.5, adopting an existing resource required running `terraform import <address> <id>` from the shell — untracked in git, easy to mistype, impossible to review. The `import {}` block makes import **a code change**: it appears in the diff, runs in CI, and supports `for_each` for bulk operations.

Source: [Terraform — `import` block reference](https://developer.hashicorp.com/terraform/language/import), [Scalr — import block learning center](https://scalr.com/learning-center/terraform-import-block/).

---

## The Pattern

Pair an `import {}` block with the `resource {}` it targets. Terraform reads existing state from the cloud, brings it under management, and writes the resource into state — no destroy, no recreate.

```hcl
# ✅ Good: declarative import — visible in the PR diff
import {
  to = google_storage_bucket.legacy_data
  id = "my-existing-bucket-name"
}

resource "google_storage_bucket" "legacy_data" {
  name     = "my-existing-bucket-name"
  location = "US"
  # ...other attributes matching the live resource
}
```

Workflow:

1. Run `terraform plan -generate-config-out=generated.tf` (TF 1.5+) to scaffold the matching `resource {}` block from the live state.
2. Hand-tune the generated config (defaults vs explicit, naming, variables).
3. Run `terraform plan` again — expect **0 to add, 0 to change, 0 to destroy, 1 to import**.
4. Merge / apply.
5. **Delete the `import {}` block** in a follow-up PR once apply succeeds (keeping it is harmless but noisy).

---

## Bulk Import with `for_each`

The biggest win over the CLI: import many resources of the same shape in one PR.

```hcl
# ✅ Good: import every existing service account in one go
locals {
  service_accounts = {
    "ci-runner"     = "ci-runner@my-project.iam.gserviceaccount.com"
    "data-pipeline" = "data-pipeline@my-project.iam.gserviceaccount.com"
    "monitoring"    = "monitoring@my-project.iam.gserviceaccount.com"
  }
}

import {
  for_each = local.service_accounts
  to       = google_service_account.managed[each.key]
  id       = "projects/my-project/serviceAccounts/${each.value}"
}

resource "google_service_account" "managed" {
  for_each     = local.service_accounts
  account_id   = each.key
  display_name = "Managed: ${each.key}"
}
```

The CLI equivalent — `terraform import 'google_service_account.managed["ci-runner"]' projects/...` repeated three times — is unreviewable, error-prone, and out of git history.

---

## ❌ Bad: the imperative CLI form

```bash
# ❌ Bad: import via CLI — no audit trail, no review, easy to typo the address
terraform import google_storage_bucket.legacy_data my-existing-bucket-name
```

Problems:

- Not visible in `git log` or PR diff.
- Operator must have local credentials matching what CI uses — drift between environments.
- Easy to import to the wrong workspace or wrong state.
- No `for_each` — every resource is a separate manual command.

The CLI form remains a valid escape hatch for emergencies (e.g. state file lost, need to re-adopt a resource before the next plan). Default to `import {}` blocks.

---

## Verifying the Import Was Clean

After `terraform apply` succeeds, run a plan with no further changes:

```bash
terraform plan
# expect: No changes. Your infrastructure matches the configuration.
```

If the plan shows any diff, the `resource {}` block does not yet match the live resource. Walk the diff field-by-field; common causes:

- Default values not specified in HCL but explicitly set in the cloud (e.g. `versioning { enabled = false }`).
- Attributes the provider treats as `Computed` only after creation (usually harmless — re-run plan after one apply).
- Labels / tags the cloud injected automatically (e.g. GCP `goog-managed-by`).

---

## Compatibility

`import {}` blocks require **Terraform 1.5+** or **OpenTofu 1.6+**. The `-generate-config-out` flag landed in the same release.

For older versions you are stuck with the CLI form — document each import in the PR description and commit the resulting state separately if practical.

---

## Anti-patterns

```hcl
# ❌ Bad: import block without a matching resource — plan errors out
import {
  to = google_storage_bucket.orphan
  id = "some-bucket"
}
# (no resource block defined)
```

```hcl
# ❌ Bad: import block left in place forever
import {
  to = google_storage_bucket.legacy_data
  id = "my-existing-bucket-name"
}
# (still here six months later — confuses reviewers)
```

Treat `import {}` as a one-shot migration tool: add it, apply it, remove it in the next PR.

---

## Related Rules

- [`moved` Blocks for Refactoring](moved-blocks-for-refactoring.md) — sibling pattern for renaming managed resources without destroy.
- [File Layout and Naming](file-layout-and-naming.md) — where the generated `resource {}` block lands.

---

## References

- [Terraform — `import` block](https://developer.hashicorp.com/terraform/language/import)
- [Scalr — Terraform import block learning center](https://scalr.com/learning-center/terraform-import-block/)

<!-- Cross-platform: see AGENTS.md in the repository root for Cursor, Claude Code, and Copilot paths. -->
