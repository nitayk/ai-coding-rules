# `terraform test` vs Terratest

Two testing tools, two different jobs. Use both — they complement each other.

| Tool | Language | Best for | Cost per test | Maintenance |
|---|---|---|---|---|
| Native `terraform test` | HCL | Input validation, output assertions, plan-time properties, conditional logic | None (uses mocks) or cheap (plan-only) | Built into Terraform 1.6+, no external dep |
| Terratest | Go | End-to-end: deploy real infra, hit real endpoints, assert behavior, then tear down | High (real cloud spend, multi-minute apply) | External dependency, Go toolchain |

Source: [Terraform — tests](https://developer.hashicorp.com/terraform/language/tests), [env0 — Terratest vs `terraform test`](https://www.env0.com/blog/terratest-vs-terraform-opentofu-test-in-depth-comparison).

---

## When to Use Native `terraform test`

`terraform test` runs in two modes:

1. **`command = plan`** (default) — runs `terraform plan` with given inputs, asserts on the planned outputs. No cloud resources created.
2. **`command = apply`** — actually creates resources, asserts on real outputs, then destroys them on cleanup.

Use it for:

- Input variable validation (does the `validation` block fire on bad input?)
- Plan-time output computation (does the module compute the right name from inputs?)
- Conditional logic (does `enable_private_endpoint = true` produce the expected resource shape?)

### ✅ Good: input-validation test (plan mode, no cloud spend)

```hcl
# tests/inputs.tftest.hcl
variables {
  cluster_name = "my-cluster"
  region       = "us-central1"
  project_id   = "test-project"
}

run "valid_inputs" {
  command = plan

  assert {
    condition     = length(google_container_cluster.this) == 1
    error_message = "Expected one GKE cluster to be planned."
  }

  assert {
    condition     = google_container_cluster.this.location == "us-central1"
    error_message = "Region should propagate to cluster location."
  }
}

run "invalid_cluster_name" {
  command = plan

  variables {
    cluster_name = "INVALID-Caps"  # violates validation regex
  }

  expect_failures = [var.cluster_name]
}
```

Runs in seconds, no cloud auth needed beyond plan-time, fits comfortably in pre-commit.

### ✅ Good: apply-mode test for output verification

```hcl
# tests/outputs.tftest.hcl
run "apply_creates_cluster" {
  command = apply

  variables {
    cluster_name = "tftest-${run.id}"  # unique per run
    project_id   = var.test_project_id
  }

  assert {
    condition     = output.cluster_endpoint != ""
    error_message = "cluster_endpoint output should be populated post-apply."
  }
}
```

`terraform test` auto-destroys after each `run` block, so cleanup is implicit. Use unique resource names (`${run.id}`) to allow parallel test runs.

---

## When to Use Terratest

Use Terratest when you need to assert on **real-infrastructure behavior** that Terraform can't observe — connectivity, application response, downstream API calls.

### ✅ Good: deploy, hit the cluster, assert, destroy

```go
// test/gke_cluster_test.go
package test

import (
    "testing"
    "github.com/gruntwork-io/terratest/modules/terraform"
    "github.com/gruntwork-io/terratest/modules/k8s"
    "github.com/stretchr/testify/assert"
)

func TestGKEClusterDeploysAndAcceptsKubectl(t *testing.T) {
    t.Parallel()

    tfOptions := &terraform.Options{
        TerraformDir: "../examples/private-cluster",
        Vars: map[string]interface{}{
            "cluster_name": "terratest-" + random.UniqueId(),
            "project_id":   os.Getenv("TEST_GCP_PROJECT"),
        },
    }

    defer terraform.Destroy(t, tfOptions)  // always teardown
    terraform.InitAndApply(t, tfOptions)

    // Real-infra assertion: kubectl get nodes returns the expected count
    kubectlOptions := k8s.NewKubectlOptions("", "", "default")
    nodes := k8s.GetNodes(t, kubectlOptions)
    assert.Equal(t, 3, len(nodes))
}
```

Tests like this take minutes (apply + assert + destroy) and cost real cloud money. Run them on a schedule (nightly) or on PRs that touch the module's core resources — not on every commit.

---

## Pipeline Layout

A typical module's test pipeline:

| Stage | Runs | Frequency | Cost |
|---|---|---|---|
| `terraform fmt -check` + `validate` | Pre-commit + CI | Every PR | Free |
| `terraform test -filter=tests/*.tftest.hcl` (plan-only) | CI | Every PR | Free |
| `terraform test` (apply-mode, ephemeral env) | CI | Every PR for `main` branch | Minutes + cloud $ |
| Terratest suite | CI | Nightly or pre-release | Many minutes + cloud $$ |

Avoid running Terratest on every PR — the cost and flakiness will overwhelm the signal.

---

## Test File Layout

```text
my-module/
├── main.tf
├── variables.tf
├── outputs.tf
├── tests/                       # native terraform test
│   ├── inputs.tftest.hcl        # plan-only validation
│   └── outputs.tftest.hcl       # apply-mode output checks
├── test/                        # Terratest (Go convention)
│   ├── go.mod
│   ├── go.sum
│   └── module_test.go
└── examples/
    ├── minimal/                 # consumed by both test suites
    └── private-cluster/
```

`tests/` (plural, native HCL) vs `test/` (singular, Go convention) is the de-facto split. Don't relitigate.

---

## Mock Providers (Native Test, 1.7+)

For input-validation tests that don't need any real provider, mock the provider:

```hcl
# tests/inputs.tftest.hcl
mock_provider "google" {}  # no real GCP calls

run "valid_inputs" {
  command = plan
  # asserts as above
}
```

Mock providers make plan-mode tests truly free — no cloud auth, no real resource lookup.

---

## What NOT to Do

```hcl
# ❌ Bad: use Terratest for what terraform test handles natively
# (a Go file that just runs `terraform plan` and greps the output for a string)
```

If you're not asserting on real-infrastructure behavior, you're paying Terratest's overhead for nothing.

```hcl
# ❌ Bad: bypass the destroy
run "create_cluster" {
  command = apply
}
# (no follow-up to ensure cleanup — leaks resources between runs)
```

`terraform test` auto-destroys at the end of the file, but if your CI cancels mid-run, you may leak resources. Tag every test resource with a label like `terratest = "true"` and run a nightly cleanup script.

---

## Related Rules

- [Plan as PR Artifact](plan-as-pr-artifact.md) — runtime equivalent: `terraform plan` output reviewed before any `apply`.
- [Module Structure](../modules/module-structure.md) — what `examples/` look like and why they double as test inputs.

---

## References

- [Terraform — Tests](https://developer.hashicorp.com/terraform/language/tests)
- [env0 — Terratest vs `terraform test`](https://www.env0.com/blog/terratest-vs-terraform-opentofu-test-in-depth-comparison)
- [Terratest](https://terratest.gruntwork.io/)

<!-- Cross-platform: see AGENTS.md in the repository root for Cursor, Claude Code, and Copilot paths. -->
