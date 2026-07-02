# Prefer `for_each` Over `count`

`count` creates resources addressed by **integer index** (`aws_instance.web[0]`, `[1]`, …). Removing or reordering an element shifts the indexes of every subsequent resource, and Terraform reads "index 2 is now a different resource" as **destroy-and-recreate**. `for_each` addresses resources by **stable string key** and avoids the destructive shift.

Source: [Terraform — `for_each`](https://developer.hashicorp.com/terraform/language/meta-arguments/for_each), [Spacelift on `for_each` vs `count`](https://spacelift.io/blog/terraform-foreach).

---

## The Failure Mode

```hcl
# ❌ Bad: count over a list — removing "web-b" destroys web-c too
variable "servers" {
  default = ["web-a", "web-b", "web-c"]
}

resource "google_compute_instance" "web" {
  count = length(var.servers)
  name  = var.servers[count.index]
  # ...
}
```

Initial state:

| Address | Name |
|---|---|
| `google_compute_instance.web[0]` | `web-a` |
| `google_compute_instance.web[1]` | `web-b` |
| `google_compute_instance.web[2]` | `web-c` |

Now remove `"web-b"`. Indexes shift:

| Address | Name | Action |
|---|---|---|
| `google_compute_instance.web[0]` | `web-a` | unchanged |
| `google_compute_instance.web[1]` | `web-c` | **destroy + recreate** (name changed from `web-b`) |
| `google_compute_instance.web[2]` | — | **destroy** |

Two destructive actions for one logical deletion. In production this can mean dropping a database, a load balancer, or a managed IP.

---

## The Fix: `for_each` with Stable Keys

```hcl
# ✅ Good: for_each over a set/map — keys are stable
variable "servers" {
  type    = set(string)
  default = ["web-a", "web-b", "web-c"]
}

resource "google_compute_instance" "web" {
  for_each = var.servers
  name     = each.key
  # ...
}
```

Now addresses are `google_compute_instance.web["web-a"]`, `["web-b"]`, `["web-c"]`. Removing `"web-b"` only plans the destruction of `web["web-b"]`; the others are untouched.

### Map form for per-instance config

```hcl
# ✅ Good: map gives keyed access + per-instance attributes
variable "servers" {
  type = map(object({
    machine_type = string
    zone         = string
  }))
  default = {
    web-a = { machine_type = "e2-small",  zone = "us-central1-a" }
    web-b = { machine_type = "e2-medium", zone = "us-central1-b" }
  }
}

resource "google_compute_instance" "web" {
  for_each     = var.servers
  name         = each.key
  machine_type = each.value.machine_type
  zone         = each.value.zone
}
```

---

## When `count` Is Still Right

`count` is fine — and clearer than `for_each` — for a **conditional single resource**:

```hcl
# ✅ Good: count for a feature flag (0 or 1)
resource "google_compute_global_address" "lb_ip" {
  count = var.enable_load_balancer ? 1 : 0
  name  = "${var.cluster_name}-lb"
}
```

Don't reach for `for_each` here — `for_each = var.enable_load_balancer ? toset(["singleton"]) : toset([])` is strictly worse to read.

---

## Migrating from `count` to `for_each`

Use `moved` blocks (TF 1.1+) so the migration is non-destructive. See `language/moved-blocks-for-refactoring.md` for the full pattern.

```hcl
# ✅ Good: moved blocks make the count→for_each migration a no-op
moved {
  from = google_compute_instance.web[0]
  to   = google_compute_instance.web["web-a"]
}

moved {
  from = google_compute_instance.web[1]
  to   = google_compute_instance.web["web-b"]
}

moved {
  from = google_compute_instance.web[2]
  to   = google_compute_instance.web["web-c"]
}
```

Run `terraform plan` and confirm "0 to add, 0 to change, 0 to destroy" — only "moved" entries. Then delete the `moved` blocks in a follow-up PR.

---

## Picking Stable Keys

A `for_each` key must be a value Terraform can compute **before** any resources are created (i.e. not derived from an unknown attribute of another resource being created in the same plan).

```hcl
# ❌ Bad: key derived from a not-yet-known resource attribute
resource "google_service_account" "sa" {
  for_each   = google_compute_instance.web   # error: depends on unknowns
  account_id = each.value.name
}

# ✅ Good: key from a known input
resource "google_service_account" "sa" {
  for_each   = var.servers
  account_id = "${each.key}-sa"
}
```

If you genuinely need to iterate over another resource's output, structure the code so the source collection is an input variable, not a derived computation.

---

## References

- [Terraform — `for_each` meta-argument](https://developer.hashicorp.com/terraform/language/meta-arguments/for_each)
- [Terraform Pilot — moved-block explained](https://www.terraformpilot.com/articles/terraform-moved-block-explained/)
- [Spacelift — `for_each` vs `count`](https://spacelift.io/blog/terraform-foreach)

<!-- Cross-platform: see AGENTS.md in the repository root for Cursor, Claude Code, and Copilot paths. -->
