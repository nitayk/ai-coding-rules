# File Layout and Naming

Terraform configurations follow a small set of standard file names and resource-naming rules. The HashiCorp style guide treats these as defaults a reader of any module should be able to assume.

Source: [Terraform Style Guide — file structure & naming](https://developer.hashicorp.com/terraform/language/style).

---

## Standard File Names

Every module (root or child) should split configuration across a small, predictable set of files. Readers should not have to grep to find the variables or outputs.

```text
my-module/
├── main.tf          # primary resources + locals
├── variables.tf     # input variable declarations
├── outputs.tf       # output declarations
├── versions.tf      # terraform { required_version, required_providers }
├── providers.tf     # provider {} blocks (ROOT MODULES ONLY)
├── data.tf          # optional: data sources, when numerous
├── README.md        # generated/maintained by terraform-docs
└── examples/        # runnable usage examples
```

- `versions.tf` holds the `terraform { required_version = "..."; required_providers { ... } }` block. Keeping it in its own file makes upgrades obvious in PR diffs.
- `providers.tf` (provider configuration with credentials/region/etc.) belongs **only** in root modules. Shared/child modules must not configure providers — see `modules/module-structure.md`.
- Split `main.tf` into per-concern files (`network.tf`, `iam.tf`, `compute.tf`) once it grows past a few hundred lines. Don't pre-split tiny modules.

---

## Resource Naming

### Use nouns, not type prefixes

The resource type is already in the address; repeating it is noise.

```hcl
# ✅ Good: descriptive noun, no type prefix
resource "google_compute_instance" "web" {
  name = "web-${var.environment}"
  # ...
}

resource "google_storage_bucket" "artifacts" {
  name = "${var.project_id}-artifacts"
}
```

```hcl
# ❌ Bad: type repeated in the local name
resource "google_compute_instance" "web_instance" {
  name = "web-instance-${var.environment}"
}

resource "google_storage_bucket" "artifacts_bucket" {
  name = "${var.project_id}-artifacts-bucket"
}
```

### Use `underscores`, not `hyphens`, for identifiers

HCL identifiers (resource local names, variable names, module names) use underscores. **Resource attributes** (the `name = "..."` you pass to GCP/AWS) may use hyphens to match cloud-side conventions.

```hcl
# ✅ Good
resource "google_compute_instance" "app_server" {
  name = "app-server-prod"  # cloud-side name can use hyphens
}

variable "instance_count" {
  type = number
}
```

```hcl
# ❌ Bad
resource "google_compute_instance" "app-server" {  # hyphens in HCL identifier
  name = "app_server_prod"
}

variable "instance-count" {  # hyphens in variable name
  type = number
}
```

### Singular names for single resources

A `resource` block declares one resource (per `count` / `for_each` instance). Use singular nouns; let the address (`google_compute_instance.web[0]`) carry the plurality.

```hcl
# ✅ Good
resource "google_compute_instance" "web" {
  for_each = var.web_servers
  # ...
}

# ❌ Bad
resource "google_compute_instance" "webs" {  # plural local name
  for_each = var.web_servers
}
```

---

## Variable & Output Conventions

- Every `variable` declares **`type`**, **`description`**, and (when appropriate) **`default`** and **`validation`**.
- Every `output` declares **`description`**. Use `sensitive = true` for anything that could leak.
- Order inside `variables.tf` / `outputs.tf`: required first (no default), then optional (with defaults), alphabetised within each group.

```hcl
# ✅ Good: full variable declaration
variable "cluster_name" {
  type        = string
  description = "Name of the GKE cluster. Must match ^[a-z][a-z0-9-]{1,39}$."

  validation {
    condition     = can(regex("^[a-z][a-z0-9-]{1,39}$", var.cluster_name))
    error_message = "cluster_name must start with a lowercase letter and be 2-40 chars."
  }
}

variable "node_count" {
  type        = number
  description = "Number of nodes per node pool."
  default     = 3
}
```

```hcl
# ❌ Bad: no description, no type, defaults intermixed
variable "cluster_name" {}  # what is this? what type?
variable "node_count" {
  default = 3
}
variable "project_id" {  # required, but listed after an optional → confusing
  type = string
}
```

---

## Always Run `terraform fmt`

`terraform fmt` is a non-negotiable formatter (like `gofmt`). Wire it into pre-commit (see `security/pre-commit-hooks.md`) so PRs never debate whitespace.

```bash
terraform fmt -recursive
terraform fmt -check -recursive  # CI guard
```

---

## References

- [Terraform Style Guide — file structure](https://developer.hashicorp.com/terraform/language/style#file-structure)
- [Terraform Style Guide — resource naming](https://developer.hashicorp.com/terraform/language/style#resource-naming)
- [GCP Terraform Best Practices — general style](https://docs.cloud.google.com/docs/terraform/best-practices/general-style-structure)

<!-- Cross-platform: see AGENTS.md in the repository root for Cursor, Claude Code, and Copilot paths. -->
