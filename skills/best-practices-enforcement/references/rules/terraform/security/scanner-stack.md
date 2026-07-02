# Scanner Stack: tflint + Checkov + Trivy

The Terraform tooling landscape is now stable on three complementary tools. Run all three — they catch overlapping but distinct issues. **tfsec is in maintenance**: Aqua merged it into Trivy in 2023 and the project README explicitly redirects there.

Source: [Spacelift — Terraform Scanning Tools](https://spacelift.io/blog/terraform-scanning-tools), [tfsec README (deprecation notice)](https://github.com/aquasecurity/tfsec).

---

## What Each Tool Does

| Tool | Role | What it catches |
|---|---|---|
| **tflint** | Linter | Provider-specific syntax errors, unsupported attribute values, deprecated arguments, missing `required_version`, dead variables |
| **Checkov** | IaC security scanner | 1000+ policies, graph-based cross-resource checks, secrets-in-HCL detection, compliance bundles (CIS, NIST, SOC2) |
| **Trivy** (IaC mode) | One-tool span | tfsec's old rule set + container/dep scanning in one binary; lighter ruleset than Checkov |
| ~~tfsec~~ | **Deprecated** | Merged into Trivy 2023; project frozen at v1.28.x |

These are not interchangeable:

- **tflint** is the only one that knows GCP/AWS/Azure provider schemas deeply enough to flag e.g. an invalid `machine_type` for a given zone.
- **Checkov** has the deepest IaC security ruleset and supports custom policies in Python or YAML.
- **Trivy** is what you reach for if you want **one** binary scanning Terraform + container images + dependencies in the same CI step.

Run **tflint + Checkov** as the primary pipeline. Add **Trivy** when you want unified scanning across other layers (containers, language deps).

---

## ✅ Good: A Real CI Pipeline

```yaml
# .github/workflows/terraform-ci.yml (sketch)
jobs:
  validate:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4

      - uses: hashicorp/setup-terraform@v3
      - run: terraform fmt -check -recursive
      - run: terraform init -backend=false
      - run: terraform validate

      - uses: terraform-linters/setup-tflint@v4
      - run: tflint --init && tflint --recursive

      - name: Checkov
        uses: bridgecrewio/checkov-action@master
        with:
          directory: .
          framework: terraform
          soft_fail: false
          # download_external_modules: true  # only if you trust the module sources

      # Optional: Trivy IaC for cross-cutting scan
      - uses: aquasecurity/trivy-action@master
        with:
          scan-type: config
          scan-ref: .
          exit-code: '1'
          severity: HIGH,CRITICAL
```

Order matters: `fmt` and `validate` are cheap and catch the silly errors first. Run the heavier scanners after.

---

## ❌ Bad: Don't Start New Pipelines on tfsec

```yaml
# ❌ Bad: tfsec on a new pipeline in 2026
- uses: aquasecurity/tfsec-action@v1.0.3
```

The [tfsec README](https://github.com/aquasecurity/tfsec) carries an official notice: "We are joining forces with Trivy. Please use Trivy for new pipelines." The tfsec binary still runs — Aqua hasn't removed it from package managers — but no new checks are landing.

**Migration:** for an existing pipeline, swap `tfsec` for `trivy config` (it inherits tfsec's rule corpus). Then layer Checkov on top for the deeper rules.

```yaml
# ✅ Good: Trivy is the direct tfsec replacement
- uses: aquasecurity/trivy-action@master
  with:
    scan-type: config
    scan-ref: .
```

---

## tflint Configuration

`tflint` ships with a "recommended" preset plus provider-specific plugins. Enable the plugin for whichever cloud(s) you target:

```hcl
# .tflint.hcl
plugin "terraform" {
  enabled = true
  preset  = "recommended"
}

plugin "google" {
  enabled = true
  version = "0.32.0"
  source  = "github.com/terraform-linters/tflint-ruleset-google"
}
```

Run `tflint --init` once to install plugins, then `tflint --recursive` to walk every subdirectory. The provider plugin catches things like:

- Invalid `machine_type` for the GCP project's quota.
- Deprecated `google_compute_network` arguments.
- Mismatched `region` vs `zone` parameters.

---

## Checkov Configuration

`.checkov.yaml` at the repo root:

```yaml
# .checkov.yaml
framework:
  - terraform

# Skip checks that don't apply to this estate
skip-check:
  - CKV_GCP_18  # GKE cluster legacy auth — handled by our org policy elsewhere

# Treat HIGH and CRITICAL as fatal
soft-fail: false

# Custom org policies live here
external-checks-dir:
  - .checkov-policies/
```

Custom policies are Python or YAML and live in your repo — useful for org-specific rules ("every GCS bucket must have label `team=`").

---

## Triaging Findings

Three buckets for any finding:

1. **True positive, fix it** — most common. Add the missing setting, re-run.
2. **True positive, accept the risk** — document the suppression inline with a reason:

   ```hcl
   #checkov:skip=CKV_GCP_29:Public bucket required for static site hosting — see docs/adr-014
   resource "google_storage_bucket" "site" {
     name                        = "my-public-site"
     uniform_bucket_level_access = false
   }
   ```

3. **False positive** — file an upstream issue if reproducible; suppress with the same inline marker and a link to the issue.

Avoid `.checkov.yaml`-level skips for one-off cases; they get stale and hide real issues. Inline suppressions with reasons are reviewable.

---

## Don't: Run Six Scanners

Running tfsec + Trivy + Checkov + Snyk + Aqua + Wiz produces overlapping findings, blows up CI runtime, and trains reviewers to ignore the output. Pick **two** (tflint + Checkov is the safe default), add a third only if you can justify the marginal coverage.

---

## Related Rules

- [Pre-commit Hooks](pre-commit-hooks.md) — same tools, but at PR-author time instead of CI.
- [Secrets and State](secrets-and-state.md) — Checkov catches many secret-in-HCL anti-patterns.

---

## References

- [Spacelift — Terraform Scanning Tools comparison](https://spacelift.io/blog/terraform-scanning-tools)
- [tfsec README — deprecation notice](https://github.com/aquasecurity/tfsec)
- [TFLint](https://github.com/terraform-linters/tflint)
- [Checkov](https://github.com/bridgecrewio/checkov)
- [Trivy IaC scanning](https://trivy.dev/latest/docs/coverage/iac/terraform/)

<!-- Cross-platform: see AGENTS.md in the repository root for deployment details. -->
