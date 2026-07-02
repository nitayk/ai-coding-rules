# OpenTofu vs Terraform Compatibility

Since the August 2023 license change from MPL2 to BSL, Terraform (HashiCorp/IBM) and **OpenTofu** (Linux Foundation fork) are two products. They share a substantial language core but diverge on real features. Pick one tool per estate and document the choice — mixing CLIs against the same state file is a recipe for state corruption.

Source: [env0 — OpenTofu vs Terraform](https://www.env0.com/blog/opentofu-vs-terraform-a-practical-guide-for-enterprise-infrastructure-teams), [OpenTofu docs](https://opentofu.org/docs/).

---

## The High-Level Split

| Dimension | Terraform | OpenTofu |
|---|---|---|
| License | BSL 1.1 (source-available, restricts hosted competitors) | MPL 2.0 (true OSS) |
| Steward | HashiCorp (IBM, 2024) | Linux Foundation |
| CLI | `terraform` | `tofu` |
| Provider registry | registry.terraform.io | registry.opentofu.org (also reads HashiCorp registry) |
| HCP integration | Native (Stacks, run tasks, etc.) | None |
| Adoption (2026 enterprise) | Majority | Growing (~12%, env0 survey) |

For most basic HCL, an identical `.tf` file works in both. The divergence is in newer features.

---

## Diverging Features (Pick a Side)

### OpenTofu-only

| Feature | Available since | Why it matters |
|---|---|---|
| **Native state encryption** | OpenTofu 1.7 | Encrypts state file content at file-level, not just at backend rest. See `security/secrets-and-state.md`. |
| **Early variable evaluation** | OpenTofu 1.8 | Variables and locals usable in `module {}` `source` and `version` — enables dynamic module selection. |
| **`-exclude` flag** | OpenTofu 1.9 | Plan/apply skipping specific resources without touching state. |
| **Provider-defined functions** | OpenTofu 1.7 | Functions contributed by providers (e.g. `provider::time::rfc3339_parse`). |

### Terraform-only

| Feature | Available since | Why it matters |
|---|---|---|
| **Stacks** | GA 2025 (HCP/Enterprise) | Bundle multiple workspaces into dependency-aware deployments. HCP-only — not in OSS CLI either. |
| **HCP run tasks / policy-as-code (Sentinel)** | Always | HCP-specific governance layer. |
| **HCP private module registry** | Always | Private registry with built-in versioning. |

`for_each` on `import {}` blocks, `moved {}` blocks, and `import {}` blocks themselves are in both tools and behave identically.

---

## ✅ Good: One Tool Per Estate, Documented

```text
# ✅ Good: estate docs declare the tool choice
docs/
└── infrastructure.md
    # First section:
    # "## Toolchain
    #  We use **OpenTofu 1.9.x** for all root modules and shared modules.
    #  CI runs `tofu` (never `terraform`). State backends are GCS with native
    #  OpenTofu encryption enabled. See ADR-007 for the decision rationale."
```

Decide once, communicate clearly. The choice affects:

- Which CLI runners install (`tofu` vs `terraform`).
- Which features new modules can use.
- Which registry shared modules are pulled from.
- Whether the team can adopt Stacks (Terraform-only) or native state encryption (OpenTofu-only).

---

## ❌ Bad: Mix CLIs Against the Same State

```bash
# ❌ Bad: alternate between tofu and terraform against the same backend
tofu apply
# ... later, on a different runner ...
terraform apply
```

The two CLIs **may** keep state-file compat for now, but:

- Lock files (`.terraform.lock.hcl`) hash providers from different registries — switching CLIs forces re-resolution.
- OpenTofu-encrypted state is unreadable to Terraform.
- Terraform's Stacks state is unreadable to OpenTofu.
- Version-specific bugs differ between the two.

This is the worst of both worlds. Pick one.

---

## Shared Modules: Constrain to the Intersection

If you publish a module intended to be used by **both** communities, restrict yourself to the common language subset:

```hcl
# ✅ Good: works in TF 1.5+ AND OpenTofu 1.6+
terraform {
  required_version = ">= 1.5"  # floor that catches both
  required_providers {
    google = {
      source  = "hashicorp/google"
      version = ">= 5.0"
    }
  }
}

# Use moved {} blocks, import {} blocks, for_each — all common.
# DON'T use Stacks. DON'T use OpenTofu state encryption inside a shared module.
```

The required-providers source `hashicorp/google` works for both tools; OpenTofu's registry mirrors HashiCorp's namespace.

Document compatibility explicitly:

```markdown
# Compatibility
- Terraform: >= 1.5
- OpenTofu: >= 1.6
```

---

## Migration Considerations

If you're considering OpenTofu → Terraform or vice versa:

| Direction | Cost |
|---|---|
| TF (OSS, no HCP features used) → OpenTofu | Usually painless — change CI to `tofu`, regenerate lock files. |
| TF (uses Stacks or HCP-specific features) → OpenTofu | Requires migrating off Stacks; potentially a major restructuring. |
| OpenTofu (uses native state encryption) → TF | Must decrypt state first; then re-encrypt at backend level. |
| OpenTofu (uses early variable eval in `source`) → TF | Refactor every dynamic `source` to be static. |

Either migration is a project, not a script. Decide upfront whether you'll commit to one tool for the lifetime of the estate.

---

## "Stacks" Is Terraform/HCP-Only

A common confusion: Terraform Stacks (GA 2025) bundle workspaces into a dependency-aware deployment. **They are not in the OSS Terraform CLI — they only run in HCP Terraform / Terraform Enterprise.** OpenTofu has no equivalent.

If you read about Stacks and the feature appeals to you, the path is HCP Terraform — not OSS Terraform, not OpenTofu. See `meta/terragrunt-vs-stacks-vs-workspaces.md`.

---

## Which to Pick (Heuristic)

- **Already on HCP / Enterprise, want Stacks or Sentinel:** stay on Terraform.
- **OSS only, want long-term license certainty:** OpenTofu.
- **OSS only, large existing investment in Terraform tooling and no clear need for OpenTofu-specific features:** stay on Terraform OSS for now; re-evaluate yearly.
- **Cloud-native shop with no HCP dependencies, building greenfield:** OpenTofu is the lower-risk OSS choice for the next 3-5 years.

There is no wrong answer for most teams. There **is** a wrong answer: not deciding.

---

## Related Rules

- [Terragrunt vs Stacks vs Workspaces](terragrunt-vs-stacks-vs-workspaces.md) — what Stacks is and when it'd matter.
- [Secrets and State](../security/secrets-and-state.md) — OpenTofu state encryption details.
- [Version Constraints](../language/version-constraints.md) — `required_version` floors that catch both tools.

---

## References

- [env0 — OpenTofu vs Terraform practical guide](https://www.env0.com/blog/opentofu-vs-terraform-a-practical-guide-for-enterprise-infrastructure-teams)
- [OpenTofu Documentation](https://opentofu.org/docs/)
- [Terraform — Stacks](https://developer.hashicorp.com/terraform/language/stacks)

<!-- Cross-platform: see AGENTS.md in the repository root for Cursor, Claude Code, and Copilot paths. -->
