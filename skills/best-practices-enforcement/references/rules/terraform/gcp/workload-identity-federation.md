# Workload Identity Federation

Service-account JSON keys are credentials that **never rotate, never expire, and live as files** — typically in environment variables, secret stores, or (catastrophically) checked-in `.json` files. **Workload Identity Federation (WIF)** replaces them with short-lived, federated tokens minted on-demand from an external identity provider (GitHub OIDC, GitLab OIDC, AWS, Azure, OIDC in general).

For Terraform pipelines running on GitHub Actions targeting GCP, WIF is the modern default.

Source: [GCP Terraform — Operations](https://docs.cloud.google.com/docs/terraform/best-practices/operations), [GCP — Workload Identity Federation overview](https://docs.cloud.google.com/iam/docs/workload-identity-federation).

---

## Why SA JSON Keys Are an Anti-pattern

```yaml
# ❌ Bad: SA JSON key shipped to CI as a secret
- name: Terraform plan
  env:
    GOOGLE_APPLICATION_CREDENTIALS_JSON: ${{ secrets.GCP_SA_KEY }}
  run: |
    echo "$GOOGLE_APPLICATION_CREDENTIALS_JSON" > /tmp/sa.json
    export GOOGLE_APPLICATION_CREDENTIALS=/tmp/sa.json
    terraform plan
```

Problems:

- Long-lived (no expiry until manual rotation).
- Lives in CI secrets, build logs, runner filesystems, maybe in the artifact cache.
- Rotation is manual and error-prone — most orgs never rotate.
- A leaked key is a permanent breach until someone notices and revokes.
- Google's own Cloud Security Posture flags SA-key creation as a finding.

---

## ✅ Good: WIF Pattern for GitHub Actions

Two-step setup — first in Terraform (one-time, low-trust IAM admin), then in the workflow YAML (per-pipeline).

### Step 1: Provision the WIF Pool, Provider, and SA in Terraform

```hcl
# ✅ Good: WIF pool + GitHub OIDC provider + a dedicated CI SA
resource "google_iam_workload_identity_pool" "github" {
  workload_identity_pool_id = "github-pool"
  display_name              = "GitHub Actions"
  description               = "OIDC federation for GitHub Actions"
}

resource "google_iam_workload_identity_pool_provider" "github" {
  workload_identity_pool_id          = google_iam_workload_identity_pool.github.workload_identity_pool_id
  workload_identity_pool_provider_id = "github-provider"

  oidc {
    issuer_uri = "https://token.actions.githubusercontent.com"
  }

  attribute_mapping = {
    "google.subject"       = "assertion.sub"
    "attribute.actor"      = "assertion.actor"
    "attribute.repository" = "assertion.repository"
    "attribute.ref"        = "assertion.ref"
  }

  # CRITICAL: restrict to your org's repos only
  attribute_condition = "assertion.repository_owner == 'my-github-org'"
}

resource "google_service_account" "terraform_ci" {
  account_id   = "terraform-ci"
  display_name = "Terraform CI runner"
}

# Allow only a specific repo's workflows to impersonate this SA
resource "google_service_account_iam_member" "wif_binding" {
  service_account_id = google_service_account.terraform_ci.name
  role               = "roles/iam.workloadIdentityUser"
  member             = "principalSet://iam.googleapis.com/${google_iam_workload_identity_pool.github.name}/attribute.repository/my-github-org/my-infra-repo"
}

# Grant the CI SA only what Terraform needs
resource "google_project_iam_member" "terraform_ci_perms" {
  for_each = toset([
    "roles/editor",                  # tune down per-resource if possible
    "roles/iam.securityAdmin",
    "roles/resourcemanager.projectIamAdmin",
  ])
  project = var.project_id
  role    = each.value
  member  = "serviceAccount:${google_service_account.terraform_ci.email}"
}
```

The **`attribute_condition`** is the security perimeter. Without it, any GitHub user in the world could mint tokens for your SA. Always pin to your org + ideally a specific repo + ideally a specific ref/environment.

### Step 2: Use WIF in the GitHub Actions Workflow

```yaml
# ✅ Good: GitHub Actions workflow using WIF — no JSON key
permissions:
  id-token: write   # required for OIDC
  contents: read

jobs:
  terraform:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4

      - id: auth
        uses: google-github-actions/auth@v2
        with:
          workload_identity_provider: 'projects/123/locations/global/workloadIdentityPools/github-pool/providers/github-provider'
          service_account: 'terraform-ci@my-project.iam.gserviceaccount.com'

      - uses: hashicorp/setup-terraform@v3
      - run: terraform init
      - run: terraform plan
```

No `GOOGLE_APPLICATION_CREDENTIALS` env var. No JSON file. The auth action exchanges the GitHub OIDC token for a short-lived (~1h) GCP access token, scoped to exactly that SA.

---

## Common Pitfalls

### Forgetting the `attribute_condition`

```hcl
# ❌ Bad: every GitHub repo on the internet can impersonate this SA
resource "google_iam_workload_identity_pool_provider" "github" {
  # ...no attribute_condition...
}
```

Always include `assertion.repository_owner == '<your-org>'` at minimum.

### Granting `roles/owner` to the CI SA

A WIF SA scoped to `Owner` is barely an improvement over a JSON-key SA scoped to `Owner`. The win comes from **short-lived tokens** *plus* **least privilege**. Grant per-resource roles where possible; use `roles/editor` only as a temporary stepping stone.

### Sharing one SA across multiple repos

Each Terraform-managed component should have its own CI SA, scoped to only what that component manages. A shared "infra-ci" SA across 10 repos means any one of those 10 can mint a token to touch everything.

---

## In-Cluster: GKE Workload Identity

For workloads **inside GKE** that need GCP API access, the equivalent is **GKE Workload Identity** (sometimes called the WI bridge). Map a Kubernetes service account to a GCP service account:

```hcl
# ✅ Good: GKE workload binds to GCP SA via Workload Identity
resource "google_service_account" "app" {
  account_id = "my-app"
}

resource "google_service_account_iam_member" "wi_binding" {
  service_account_id = google_service_account.app.name
  role               = "roles/iam.workloadIdentityUser"
  member             = "serviceAccount:${var.project_id}.svc.id.goog[my-namespace/my-app-ksa]"
}
```

```yaml
# kubernetes/sa.yaml — annotate the KSA
apiVersion: v1
kind: ServiceAccount
metadata:
  name: my-app-ksa
  namespace: my-namespace
  annotations:
    iam.gke.io/gcp-service-account: my-app@my-project.iam.gserviceaccount.com
```

Pods using `serviceAccountName: my-app-ksa` get short-lived GCP credentials for `my-app@`. No JSON key, no `GOOGLE_APPLICATION_CREDENTIALS`.

---

## Migrating Off SA JSON Keys

1. Provision the WIF pool + provider + CI SA in Terraform (don't delete the old JSON key SA yet).
2. Switch one workflow at a time to WIF auth; verify plan/apply parity.
3. Audit IAM for any role still bound to the old SA; either migrate or delete.
4. Delete the JSON key (`gcloud iam service-accounts keys delete ...`).
5. Add an Org Policy `iam.disableServiceAccountKeyCreation` to prevent new keys.

---

## Related Rules

- [Secrets and State](../security/secrets-and-state.md) — why credentials in HCL / env vars are a separate hazard.
- [`terraform-google-modules` Preference](terraform-google-modules-preference.md) — CFT modules support WIF natively.

---

## References

- [GCP Terraform — Operations best practices](https://docs.cloud.google.com/docs/terraform/best-practices/operations)
- [GCP — Workload Identity Federation overview](https://docs.cloud.google.com/iam/docs/workload-identity-federation)
- [google-github-actions/auth](https://github.com/google-github-actions/auth)
- [GKE — Workload Identity](https://docs.cloud.google.com/kubernetes-engine/docs/concepts/workload-identity)

<!-- Cross-platform: see AGENTS.md in the repository root for deployment details. -->
