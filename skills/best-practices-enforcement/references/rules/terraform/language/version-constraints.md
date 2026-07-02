# Version Constraints

Terraform configurations have two version surfaces that must both be pinned: the **Terraform CLI** (`required_version`) and **each provider** (`required_providers`). Sloppy constraints (`>= 4.0` with no upper bound) cause silent upgrades on the next `terraform init`, which surface as confusing plan diffs or apply-time errors weeks later.

Source: [Terraform — Version Constraints](https://developer.hashicorp.com/terraform/language/expressions/version-constraints), [HashiCorp Style Guide — versions.tf](https://developer.hashicorp.com/terraform/language/style#versions-tf).

---

## The Two-Surface Rule

Both the CLI and every provider should be pinned in a dedicated `versions.tf` file at the module root:

```hcl
# ✅ Good: versions.tf with both surfaces pinned
terraform {
  required_version = "~> 1.9.0"  # CLI: any 1.9.x, no 1.10+

  required_providers {
    google = {
      source  = "hashicorp/google"
      version = "~> 5.40"  # any 5.40+, but no 6.x
    }
    kubernetes = {
      source  = "hashicorp/kubernetes"
      version = "~> 2.32"
    }
    helm = {
      source  = "hashicorp/helm"
      version = "~> 2.14"
    }
  }
}
```

Keep this block in its own file (`versions.tf`) so upgrades show up cleanly in PR diffs and are easy for review automation to flag.

---

## Constraint Operators — What Each Means

| Operator | Example | Allows | Use case |
|---|---|---|---|
| `=` | `version = "5.40.0"` | exactly 5.40.0 | rare — only for reproducing a broken upgrade |
| `~>` (pessimistic) | `"~> 5.40"` | `>= 5.40, < 6.0` | **default for providers** |
| `~>` (patch-only) | `"~> 5.40.0"` | `>= 5.40.0, < 5.41.0` | high-stakes modules that can't take minor changes |
| `>=` / `<` (range) | `">= 5.40, < 5.50"` | bounded window | when you need a feature from 5.40 but a regression hit in 5.50 |
| `>=` (unbounded) | `">= 5.40"` | any 5.40+ forever | **never use in production root modules** |

The pessimistic operator `~> X.Y` means "allow patch and minor, disallow major" — which matches provider SemVer guarantees and gives you bugfixes without breaking changes.

---

## ❌ Bad: Unbounded Constraints

```hcl
# ❌ Bad: any future major version is silently allowed
terraform {
  required_providers {
    google = {
      source  = "hashicorp/google"
      version = ">= 4.0"  # 5.x and 6.x both match — surprise upgrade
    }
  }
}
```

The hazard: a new contributor runs `terraform init` six months later, pulls `google 6.0`, and the next plan shows a forced replacement on every IAM binding because v6 changed the binding semantics. The PR diff looks innocent — no `.tf` files changed — but the provider did.

The lock file (`.terraform.lock.hcl`) is your second line of defence, but it only helps if it is **committed** (see below). The version constraint is the first line.

---

## The Lock File (`.terraform.lock.hcl`)

`terraform init` writes `.terraform.lock.hcl` recording the exact resolved version + hash of every provider. **Commit this file to git** for every root module (not for shared/child modules).

```text
# ✅ Good: lock file lives next to versions.tf
my-root-module/
├── versions.tf            # version constraints
├── .terraform.lock.hcl    # resolved versions + hashes (COMMITTED)
└── main.tf
```

Bump providers explicitly:

```bash
terraform init -upgrade        # resolves to latest within constraints, rewrites the lock
git diff .terraform.lock.hcl   # the PR-visible upgrade
terraform plan                 # verify no unintended diffs
```

For shared **child modules** (modules consumed by others), do **not** commit a lock file — the consumer's lock file is authoritative.

---

## Root Modules vs Shared Modules

| Concern | Root module | Shared/child module |
|---|---|---|
| `required_version` for CLI | Pin precisely (`~> 1.9.0`) | Specify a floor (`>= 1.5`) |
| `required_providers` versions | Pin precisely (`~> 5.40`) | Specify a floor (`>= 5.0`) |
| Commit `.terraform.lock.hcl`? | **Yes** | **No** |
| `provider {}` configuration blocks? | Yes | **No** — see `modules/module-structure.md` |

Shared modules want **loose** floors so consumers can adopt them across a range of stacks. Root modules want **tight** ceilings so production stays reproducible.

---

## Upgrade Discipline

A provider bump (especially major) is a **dedicated PR**, never bundled with a feature change. Process:

1. Bump the constraint in `versions.tf` (e.g. `~> 5.40` → `~> 6.0`).
2. `terraform init -upgrade`.
3. `terraform plan` against every environment workspace.
4. Read the provider's CHANGELOG end-to-end for any `BREAKING` notes.
5. Resolve diffs (often via `moved` blocks for renamed resources — see `language/moved-blocks-for-refactoring.md`).
6. Apply to a low-stakes environment first; bake at least 24h before promoting.

---

## CI Guard

Catch unbounded constraints at PR time. With `tflint`:

```hcl
# .tflint.hcl
plugin "terraform" {
  enabled = true
  preset  = "recommended"
}

# terraform_required_version + terraform_required_providers are in the recommended preset
```

The `terraform_required_version` and `terraform_required_providers` rules fail on missing or empty constraints.

---

## References

- [Terraform — Version Constraints](https://developer.hashicorp.com/terraform/language/expressions/version-constraints)
- [Terraform — Dependency Lock File](https://developer.hashicorp.com/terraform/language/files/dependency-lock)
- [HashiCorp Style Guide — versions.tf](https://developer.hashicorp.com/terraform/language/style#versions-tf)

<!-- Cross-platform: see AGENTS.md in the repository root for deployment details. -->
