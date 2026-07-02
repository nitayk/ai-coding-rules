# Kubernetes / Helm / Vault Providers

Mixing the `google` provider (creates a GKE cluster), the `kubernetes` provider (talks to that cluster), and the `helm` provider (installs releases) in one root is the most common source of "works on Tuesday, breaks on Wednesday" pain. The fix is disciplined separation of concerns and explicit auth flow.

Source: [Terraform Kubernetes provider — auth](https://registry.terraform.io/providers/hashicorp/kubernetes/latest/docs), [Terraform Helm provider — auth](https://registry.terraform.io/providers/hashicorp/helm/latest/docs).

---

## The Chicken-and-Egg Problem

```hcl
# ❌ Bad: cluster + workloads in one root, auth read from cluster output
resource "google_container_cluster" "this" {
  # ...
}

provider "kubernetes" {
  host  = "https://${google_container_cluster.this.endpoint}"
  token = data.google_client_config.default.access_token
  cluster_ca_certificate = base64decode(google_container_cluster.this.master_auth[0].cluster_ca_certificate)
}

resource "kubernetes_namespace" "app" {
  metadata { name = "app" }
}
```

This works on the first apply. It then breaks the moment you `terraform destroy` (the kubernetes provider can't authenticate to a cluster that's being deleted) or the cluster endpoint changes (provider config re-evaluates with stale state).

The general guidance: **do not mix providers that depend on resources managed by another provider in the same state**. Split into two roots.

---

## ✅ Good: Two Root Modules, One per Lifecycle

```text
environments/prd/
├── 10-cluster/        # google provider — creates GKE
│   └── outputs.tf     # exports cluster_endpoint, cluster_ca, cluster_name
└── 20-workloads/      # kubernetes + helm providers — reads cluster via data
    └── main.tf
```

```hcl
# environments/prd/20-workloads/main.tf — reads cluster from the other root
data "terraform_remote_state" "cluster" {
  backend = "gcs"
  config = {
    bucket = "tf-state-prd"
    prefix = "10-cluster"
  }
}

data "google_client_config" "default" {}

# Always use a fresh data source for cluster details (don't cache through TF state)
data "google_container_cluster" "this" {
  name     = data.terraform_remote_state.cluster.outputs.cluster_name
  location = data.terraform_remote_state.cluster.outputs.cluster_location
}

provider "kubernetes" {
  host                   = "https://${data.google_container_cluster.this.endpoint}"
  token                  = data.google_client_config.default.access_token
  cluster_ca_certificate = base64decode(data.google_container_cluster.this.master_auth[0].cluster_ca_certificate)
}

provider "helm" {
  kubernetes {
    host                   = "https://${data.google_container_cluster.this.endpoint}"
    token                  = data.google_client_config.default.access_token
    cluster_ca_certificate = base64decode(data.google_container_cluster.this.master_auth[0].cluster_ca_certificate)
  }
}

resource "kubernetes_namespace" "app" {
  metadata { name = "app" }
}

resource "helm_release" "ingress_nginx" {
  name       = "ingress-nginx"
  repository = "https://kubernetes.github.io/ingress-nginx"
  chart      = "ingress-nginx"
  version    = "4.11.2"
  namespace  = "ingress-nginx"
  create_namespace = true
}
```

The cluster root and the workloads root have separate states. Destroying workloads doesn't touch the cluster; recreating the cluster doesn't confuse the kubernetes provider's view.

---

## Helm Provider Dependency Ordering

Within a workloads root, helm releases that depend on each other need explicit `depends_on`:

```hcl
# ✅ Good: cert-manager must be ready before any Issuer is created
resource "helm_release" "cert_manager" {
  name             = "cert-manager"
  repository       = "https://charts.jetstack.io"
  chart            = "cert-manager"
  version          = "v1.15.0"
  namespace        = "cert-manager"
  create_namespace = true

  set {
    name  = "installCRDs"
    value = "true"
  }
}

resource "kubernetes_manifest" "letsencrypt_issuer" {
  manifest = yamldecode(file("${path.module}/issuer.yaml"))

  depends_on = [helm_release.cert_manager]  # wait for CRDs to be registered
}
```

`depends_on` is the only reliable way; the helm provider's plan doesn't infer that a CRD it installs is a prerequisite for a `kubernetes_manifest` resource referring to that CRD type.

---

## Vault: Its Own Project, Its Own State

Vault is special: it's the source of truth for secrets across other workloads, so its blast radius and uptime requirements differ from app workloads.

```text
# ✅ Good: vault on a dedicated GCP project, dedicated state
gcp-projects/
├── prd-platform-vault/    # dedicated GCP project for Vault
│   └── terraform/         # provisions: GKE cluster (small), Vault Helm release, KMS keys for auto-unseal
└── prd-platform-apps/     # everything else
```

The `terraform-google-vault` CFT module handles the typical setup (GKE + auto-init + KMS auto-unseal):

```hcl
module "vault" {
  source  = "terraform-google-modules/vault/google"
  version = "~> 6.0"

  project_id  = google_project.vault.project_id
  region      = var.region
  vault_ui    = true

  # KMS auto-unseal — Vault unseal keys live in Google KMS, not on Operators' laptops
  storage_bucket   = google_storage_bucket.vault_data.name
}
```

Application roots consume Vault via the `vault` provider, pointing at the Vault address — they do **not** manage Vault itself.

```hcl
# ✅ Good: app root reads Vault secrets but doesn't manage Vault
provider "vault" {
  address = "https://vault.platform.example.com"
  # auth via Vault GCP auth method or short-lived token from CI
}

data "vault_kv_secret_v2" "db" {
  mount = "secret"
  name  = "prd/postgres"
}
```

Remember: `data.vault_kv_secret_v2.db.data["password"]` ends up in the **app root's** state in plaintext. See `security/secrets-and-state.md`.

---

## Auth via Token, Not kubeconfig File

```hcl
# ❌ Bad: load kubeconfig from disk — assumes the CI runner has run gcloud first
provider "kubernetes" {
  config_path = "~/.kube/config"
}
```

This works locally but breaks in CI (different home dir, no gcloud auth, race against the runner's filesystem).

```hcl
# ✅ Good: explicit token from google_client_config
provider "kubernetes" {
  host                   = "https://${data.google_container_cluster.this.endpoint}"
  token                  = data.google_client_config.default.access_token
  cluster_ca_certificate = base64decode(data.google_container_cluster.this.master_auth[0].cluster_ca_certificate)
}
```

The token comes from the same identity Terraform is already using (typically via WIF — see `gcp/workload-identity-federation.md`). No kubeconfig, no `gcloud` shell-out, no surprises.

---

## Anti-patterns

```hcl
# ❌ Bad: cluster + 30 helm releases in one root
resource "google_container_cluster" "this" { ... }
resource "helm_release" "thing_1" { ... }
# ... 29 more
```

Single failure point. Plan latency explodes. Recovery requires deleting helm releases by hand.

```hcl
# ❌ Bad: kubernetes provider points at an exec plugin that shells to gcloud
provider "kubernetes" {
  host = data.google_container_cluster.this.endpoint
  exec {
    api_version = "client.authentication.k8s.io/v1beta1"
    command     = "gcloud"
    args        = ["container", "clusters", "get-credentials", "..."]
  }
}
```

Works on a laptop with `gcloud` installed and authenticated. Fails in any CI runner that doesn't match.

---

## Related Rules

- [Root Module Blast Radius](../modules/root-module-blast-radius.md) — why splitting cluster + workloads is the right call.
- [Workload Identity Federation](../gcp/workload-identity-federation.md) — how the underlying GCP token is obtained.
- [GKE Cluster Conventions](../gcp/gke-cluster-conventions.md) — the cluster the kubernetes provider is talking to.
- [Secrets and State](../security/secrets-and-state.md) — what happens when the vault provider reads a secret.

---

## References

- [Terraform Kubernetes provider — auth](https://registry.terraform.io/providers/hashicorp/kubernetes/latest/docs)
- [Terraform Helm provider — auth](https://registry.terraform.io/providers/hashicorp/helm/latest/docs)
- [CFT terraform-google-vault](https://github.com/terraform-google-modules/terraform-google-vault)

<!-- Cross-platform: see AGENTS.md in the repository root for deployment details. -->
