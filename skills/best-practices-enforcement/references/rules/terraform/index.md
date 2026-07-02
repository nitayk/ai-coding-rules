# Terraform / HCL Development Rules

**Terraform-Specific Rules**: Implementation details for HCL infrastructure-as-code, applicable to Terraform (≥1.5) and OpenTofu (≥1.7) unless explicitly flagged.

**How It Works**:
- Generic rules (correctness first, blast-radius thinking, least-privilege) load **automatically** when you open `.tf` files
- This index loads **automatically** when you open Terraform files (via globs)
- Use this to discover Terraform-specific patterns (file layout, `for_each`, `moved` blocks, scanner stack, GCP CFT modules)

**Key Principle**: This directory contains ONLY Terraform-specific patterns. Universal principles are in `generic/` and load automatically — they're referenced from here.

**Tool divergence**: Where Terraform and OpenTofu diverge (state encryption, Stacks, early variable evaluation), the relevant `meta/` rule calls it out explicitly. Treat the workspace as a single-tool estate; don't mix CLIs against the same state.

**UADS context**: UADS lives on **GCP/GKE**. The `gcp/` subdir captures opinionated patterns (CFT modules, Workload Identity Federation, GKE conventions) that don't apply outside that estate.

---

## Keyword → File Routing

| Keywords/Intent | Load File |
|----------------|-----------|
| **file layout**, `main.tf`, `variables.tf`, naming, structure | `language/file-layout-and-naming.md` |
| **for_each**, count, index shift, destroy-recreate | `language/for_each-over-count.md` |
| **moved**, refactor, rename resource, extract module | `language/moved-blocks-for-refactoring.md` |
| **import**, import block, adopt existing resource | `language/import-blocks-declarative.md` |
| **version constraints**, `~>`, `required_version`, provider pinning | `language/version-constraints.md` |
| **module structure**, repo layout, child module conventions | `modules/module-structure.md` |
| **semver**, module versioning, CHANGELOG, breaking changes | `modules/semantic-versioning.md` |
| **blast radius**, state size, environment split | `modules/root-module-blast-radius.md` |
| **secrets**, state plaintext, encrypt state | `security/secrets-and-state.md` |
| **scanners**, tflint, checkov, trivy, tfsec deprecated | `security/scanner-stack.md` |
| **pre-commit**, fmt, validate, terraform-docs | `security/pre-commit-hooks.md` |
| **CFT**, terraform-google-modules, Google modules | `gcp/terraform-google-modules-preference.md` |
| **Workload Identity Federation**, WIF, SA JSON key | `gcp/workload-identity-federation.md` |
| **GKE**, private cluster, release channel, node pools | `gcp/gke-cluster-conventions.md` |
| **kubernetes provider**, helm provider, vault provider | `providers/kubernetes-helm-vault.md` |
| **terraform test**, Terratest, native test | `testing/terraform-test-vs-terratest.md` |
| **plan artifact**, Atlantis, PR workflow, approve plan | `testing/plan-as-pr-artifact.md` |
| **OpenTofu**, Terraform fork, state encryption | `meta/opentofu-vs-terraform-compatibility.md` |
| **Terragrunt**, Stacks, workspaces, DRY multi-env | `meta/terragrunt-vs-stacks-vs-workspaces.md` |
| **drift**, drift detection, driftctl, cloud-concierge | `meta/drift-detection-strategy.md` |

---

## Available Rules (Leaves)

### Language (`language/`)
- **[File Layout and Naming](language/file-layout-and-naming.md)** — `main.tf` / `variables.tf` / `outputs.tf` / `versions.tf`, resource naming conventions
- **[`for_each` over `count`](language/for_each-over-count.md)** — Stable map/set keys, why `count` shifts destroy resources, `moved` migration
- **[`moved` Blocks for Refactoring](language/moved-blocks-for-refactoring.md)** — TF 1.1+ refactor-without-destroy; rename, extract, restructure
- **[`import` Blocks (Declarative)](language/import-blocks-declarative.md)** — TF 1.5+ `import {}` blocks over `terraform import` CLI; PR-reviewable
- **[Version Constraints](language/version-constraints.md)** — `required_version`, provider `~>` pinning, unbounded `>=` is unsafe

### Modules (`modules/`)
- **[Module Structure](modules/module-structure.md)** — `terraform-<provider>-<name>` naming, one module per repo, no provider/backend config in shared modules
- **[Semantic Versioning](modules/semantic-versioning.md)** — MAJOR/MINOR/PATCH discipline for module releases; CHANGELOG required
- **[Root Module Blast Radius](modules/root-module-blast-radius.md)** — ≤~100 resources per state; modules/environments split

### Security (`security/`)
- **[Secrets and State](security/secrets-and-state.md)** — Secrets land in state plaintext; encrypt backend, restrict access
- **[Scanner Stack](security/scanner-stack.md)** — tflint + Checkov + Trivy; tfsec is deprecated (merged into Trivy)
- **[Pre-commit Hooks](security/pre-commit-hooks.md)** — `fmt`, `validate`, `tflint`, `terraform-docs` via `pre-commit-terraform`

### Providers (`providers/`)
- **[Kubernetes / Helm / Vault](providers/kubernetes-helm-vault.md)** — GKE auth handoff, Helm provider dependency ordering, Vault on its own state

### GCP (`gcp/`)
- **[`terraform-google-modules` Preference](gcp/terraform-google-modules-preference.md)** — CFT modules over hand-rolled equivalents; pin to SemVer tags
- **[Workload Identity Federation](gcp/workload-identity-federation.md)** — SA JSON keys are an anti-pattern; WIF for CI/CD
- **[GKE Cluster Conventions](gcp/gke-cluster-conventions.md)** — Private clusters, Workload Identity, release-channel pinning, regional node pools

### Testing (`testing/`)
- **[`terraform test` vs Terratest](testing/terraform-test-vs-terratest.md)** — Native HCL test for config validation; Terratest (Go) for live-infra behavior
- **[Plan as PR Artifact](testing/plan-as-pr-artifact.md)** — Always `plan -out=plan.tfplan`; approve plan before `apply`; matches Atlantis/HCP

### Meta (`meta/`)
- **[OpenTofu vs Terraform Compatibility](meta/opentofu-vs-terraform-compatibility.md)** — Divergent features: state encryption (OpenTofu), Stacks (HCP only)
- **[Terragrunt vs Stacks vs Workspaces](meta/terragrunt-vs-stacks-vs-workspaces.md)** — When each pattern fits; tradeoffs by estate size
- **[Drift Detection Strategy](meta/drift-detection-strategy.md)** — driftctl is in maintenance; platform-level vs self-hosted alternatives

## Related Rules

**Universal Principles:**
- [Generic Code Quality Principles](../../generic/code-quality/core-principles.md) — Universal principles (SOLID, DRY, KISS, YAGNI, correctness first)
- [Generic Architecture Principles](../../generic/architecture/core-principles.md) — Universal architecture principles
- [Generic Testing Principles](../../generic/testing/core-principles.md) — Universal testing principles

**Terraform-Specific:**
- This directory contains Terraform-specific implementations and examples

---

## References

- [Terraform Style Guide (HCL)](https://developer.hashicorp.com/terraform/language/style) — official HashiCorp style guide, versioned with current release
- [HashiCorp Recommended Practices](https://developer.hashicorp.com/terraform/cloud-docs/recommended-practices) — enterprise adoption maturity model
- [Google Cloud Terraform Best Practices](https://docs.cloud.google.com/docs/terraform/best-practices/general-style-structure) — canonical for GCP/GKE estates
- [GCP Terraform — Root Modules](https://docs.cloud.google.com/docs/terraform/best-practices/root-modules) — blast-radius rule, modules/environments split
- [terraform-google-modules (CFT)](https://github.com/terraform-google-modules) — Google's opinionated GKE / project-factory / foundation modules
- [Terraform Best Practices — Anton Babenko](https://www.terraform-best-practices.com/) — most-cited community guide; pairs with pre-commit-terraform
- [OpenTofu Docs](https://opentofu.org/docs/) — Linux Foundation fork; note divergent features (state encryption since 1.7)
- [Terraform Stacks (HCP)](https://developer.hashicorp.com/terraform/language/stacks) — GA 2025; bundles workspaces (HCP/Enterprise only)
- [TFLint](https://github.com/terraform-linters/tflint) — de-facto HCL linter; provider-specific rules
- [Checkov](https://github.com/bridgecrewio/checkov) — deepest IaC security scanner (1,000+ policies, graph-based)
- [Trivy (tfsec successor)](https://github.com/aquasecurity/tfsec) — tfsec is now in maintenance; new pipelines should target Trivy
- [terraform-docs](https://github.com/terraform-docs/terraform-docs) — module README generator

<!-- Cross-platform: see AGENTS.md in this repository for Cursor, Claude Code, and Copilot paths. -->
