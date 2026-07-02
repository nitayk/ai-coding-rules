# Secrets and State

A common, dangerous misconception: "I read this secret from Vault, so it isn't in my repo." True — but **anything Terraform reads ends up in state in plaintext**, and the state file is rarely treated with the rigor of a credential. The state bucket is the credential.

Source: [HashiCorp Recommended Practices](https://developer.hashicorp.com/terraform/cloud-docs/recommended-practices), [Terraform — Sensitive Data in State](https://developer.hashicorp.com/terraform/language/state/sensitive-data).

---

## The Plaintext Problem

This config looks safe — no secret in the repo:

```hcl
# ⚠️  Looks safe, but the secret lands in state
data "vault_kv_secret_v2" "db" {
  mount = "secret"
  name  = "prod/db"
}

resource "google_sql_user" "app" {
  instance = google_sql_database_instance.primary.name
  name     = "app"
  password = data.vault_kv_secret_v2.db.data["password"]  # ← in state, plaintext
}
```

After `apply`, `terraform.tfstate` (or the remote backend object) contains:

```json
{
  "resources": [{
    "type": "google_sql_user",
    "instances": [{
      "attributes": {
        "name": "app",
        "password": "actual-plaintext-secret-here"
      }
    }]
  }]
}
```

This is documented Terraform behavior, not a bug. The `sensitive = true` attribute only stops the value from being printed to **CLI output**; it does not encrypt or omit it from state.

---

## Defence: Encrypt and Lock Down the Backend

State backends are the perimeter. For each backend:

1. **Encryption at rest.** GCS: customer-managed encryption key (CMEK). S3: SSE-KMS with a dedicated CMK. Azure: storage account encryption with a managed key.
2. **Bucket-level IAM.** Only the CI service account that runs `apply` for that root has `write`; humans get `read` (for `plan`) at most, and only in non-prod.
3. **Object versioning.** GCS / S3 versioning **on** so a botched apply can be rolled back to the previous state snapshot.
4. **Audit logging.** Cloud Audit Logs / CloudTrail on every state-bucket access.
5. **State locking.** Use a backend that supports it (GCS, S3-with-DynamoDB, HCP). Locking prevents concurrent applies from corrupting state.

```hcl
# ✅ Good: GCS backend with locking + versioning + CMEK
terraform {
  backend "gcs" {
    bucket                      = "tf-state-prd-locked"
    prefix                      = "20-workload"
    encryption_key              = "projects/.../cryptoKeys/tfstate-cmek"
  }
}
```

GCS supports built-in state locking as of provider 3.x — no extra DynamoDB-equivalent needed.

---

## Defence: OpenTofu Native State Encryption (if you can)

OpenTofu **1.7+** supports encrypted state files at the file level — the state on disk and in the backend is unreadable without a key. Terraform (HashiCorp) does **not** have an equivalent in OSS.

```hcl
# ✅ Good: OpenTofu state encryption (OpenTofu only)
terraform {
  encryption {
    key_provider "pbkdf2" "kdf" {
      passphrase = var.state_passphrase  # supplied via env var TF_VAR_state_passphrase
    }
    method "aes_gcm" "default" {
      keys = key_provider.pbkdf2.kdf
    }
    state {
      method = method.aes_gcm.default
    }
    plan {
      method = method.aes_gcm.default
    }
  }
}
```

If your estate is on OpenTofu, turn this on. If on Terraform, you rely on backend-level encryption only (which is sufficient when properly configured — see above).

---

## Don't Hardcode — But Also Don't Be Smug

```hcl
# ❌ Bad: secret in repo
resource "google_sql_user" "app" {
  password = "p@ssw0rd123!"
}
```

Obviously bad. But:

```hcl
# ⚠️  Better, but still in state plaintext
resource "google_sql_user" "app" {
  password = data.vault_kv_secret_v2.db.data["password"]
}
```

is only "better" because the source-of-truth lives in Vault. The state file is still a copy of the secret. If the state bucket is misconfigured (public, over-permissive IAM, missing CMEK), the secret leaks anyway.

The honest mitigation: **don't manage secrets with Terraform** when you can avoid it. Provision the secret-storage primitive (Vault mount, Secret Manager secret container) in Terraform; have the application read the actual secret value at runtime via its own SDK.

```hcl
# ✅ Good: TF creates the Secret Manager *container*; app reads the value at runtime
resource "google_secret_manager_secret" "db_password" {
  secret_id = "db-password"
  replication {
    auto {}
  }
}

# Secret VERSIONS are set via gcloud / SDK / a one-shot job — not Terraform.
# Terraform manages the secret container, not its contents.
```

The application reads `db-password` via the Secret Manager SDK at boot. The secret value never touches Terraform state.

---

## Provider Credentials — Never in HCL

Provider auth (GCP SA key, AWS access key, Azure SPN secret) **must not** be in `.tf` files, `.tfvars` files, or environment variables committed to git.

```hcl
# ❌ Bad
provider "google" {
  credentials = file("./sa-key.json")  # committed file
}
```

```hcl
# ✅ Good: Workload Identity Federation (no static keys)
provider "google" {
  project = var.project_id
  region  = var.region
  # Auth resolves automatically via WIF — see gcp/workload-identity-federation.md
}
```

See `gcp/workload-identity-federation.md` for the WIF setup that replaces static SA keys.

---

## Treat State Access as a Credential

Operationally: a user with **read** on the state bucket has every database password, every API token, every TLS private key ever written through Terraform. State-bucket access is at least as sensitive as production database access.

- No `Project Editor` / `Owner` access to state buckets — least privilege only.
- No `gcloud auth application-default login` to humans against the state bucket service account.
- Audit-log every read; alert on unexpected readers.
- Rotate the encryption key on a schedule; rotation re-encrypts existing objects on next access.

---

## Anti-patterns

```hcl
# ❌ Bad: write a secret to a local file
resource "local_file" "db_password" {
  content  = data.vault_kv_secret_v2.db.data["password"]
  filename = "/tmp/db-password"   # plaintext on the runner's disk
}
```

```hcl
# ❌ Bad: output a secret (it's now also in plan output and any state copies)
output "db_password" {
  value = google_sql_user.app.password
}
```

```hcl
# ✅ Good: if you must output, mark sensitive AND document why
output "db_password" {
  value       = google_sql_user.app.password
  sensitive   = true
  description = "Used by downstream module X to seed the dev DB; rotate quarterly."
}
```

`sensitive = true` redacts the value from console output. It does **not** remove it from state or from `terraform output -json`.

---

## Related Rules

- [Workload Identity Federation](../gcp/workload-identity-federation.md) — avoid SA JSON keys entirely.
- [Root Module Blast Radius](../modules/root-module-blast-radius.md) — state file scope = blast radius.
- [Scanner Stack](scanner-stack.md) — Checkov / Trivy catch many secret-in-HCL patterns.

---

## References

- [HashiCorp Recommended Practices](https://developer.hashicorp.com/terraform/cloud-docs/recommended-practices)
- [Terraform — Sensitive Data in State](https://developer.hashicorp.com/terraform/language/state/sensitive-data)
- [OpenTofu — State Encryption](https://opentofu.org/docs/language/state/encryption/)

<!-- Cross-platform: see AGENTS.md in the repository root for deployment details. -->
