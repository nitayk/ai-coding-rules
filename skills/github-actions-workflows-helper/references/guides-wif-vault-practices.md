# User Guides — WIF, Vault, Slack, and Practices

> **Provenance (not runtime dependencies):**
> These guides are bundled from [Unity-Technologies/github-actions-workflows/docs/user-guides/](https://github.com/Unity-Technologies/github-actions-workflows/tree/main/docs/user-guides).
> If upstream docs change, refresh this file to match.
> Last synced: 2026-04-09

---

## Using Workload Identity Federation (WIF) in GitHub Actions

Workload Identity Federation in this context is a method of granting specific GitHub repositories or specific GitHub Actions workflows access to impersonate a Google Cloud service account. The benefit of this method is that there is no need to generate a service account key and store it as a secret somewhere.

The typical usage is to have a CI service account in your production GCP project that has access to deploy to the corresponding test, staging and production projects. We use the term "deploy" loosely here to also mean things like writing to a bucket or container registry, or deploying containers to a cluster, all depending on what kind of things you are building.

In the interest of security and reliability, it is recommended to have a CI service account dedicated to your project or a small set of projects, and tailoring it's access according to needs, rather than reusing service accounts with wide access across the organization.

**Note:** PRE has now a centralized set of workload identity pools you can read about them [here](https://docs.internal.unity.com/pre-unity-identity-pools) it is recommended to use these pools as creation of new pools will be blocked in the future due to security concerns.

### Using shared projects

Follow this section if you want to use the shared projects `unity-source` and `unity-ads-common-prd`, they are used by many teams.

#### Pushing images to unity-source

Make a PR that adds your repository [here](https://github.com/Unity-Technologies/pre-terraform-unity-source-workspace/blob/b11d815da22e0e0dab0734e0152ad15f6c85fb5e/iam.tf#L5)

Use these values to push images:

```yaml
service_account: ci-push@unity-source.iam.gserviceaccount.com
```

#### Deployments to Ads clusters and pushing images to unity-ads-common-prd

Make a PR that adds your repository [here](https://github.com/Unity-Technologies/mz-terraform-common-workspace/blob/45ab5d12248111c91087370e8e8c978337e40a72/variables-local.tf#L145)

Use these values to push images:

```yaml
service_account: ci-push@unity-ads-common-prd.iam.gserviceaccount.com
```

Use these values for deployments:

```yaml
service_account: ci-deploy@unity-ads-common-prd.iam.gserviceaccount.com
```

### Using your own service accounts

If you have your own GCR registry or a GKE cluster, follow this guide on how to setup workload identity federation for it. If you want to use a service account for something else like uploading files to a bucket and you already have a service account and permissions configured you can jump in to [Configure WIF on the "GCP side"](#configure-wif-on-the-gcp-side) section.

### Create a service account

In the production section of your Terraform repo:

```hcl
# CI/CD user for GitHub Actions
resource "google_service_account" "github-actions-cicd" {
  project    = local.project
  account_id = "github-actions-cicd"
}
```

### Grant the service account access to push images

This is very different based on your use case, but here is an example of the configuration needed to push a container image to your own GCR registry.

```hcl
# Define a Custom role if it doesn't already exist
resource "google_project_iam_custom_role" "gcr_read_write" {
  role_id     = "gcrReadWrite"
  title       = "GCR Read/Write"
  project     = local.project
  description = "A role for enabling read/write permissons on all GCR storage buckets"
  permissions = [
    # Get the project ID if necessary
    "resourcemanager.projects.get",

    # Get and list buckets
    "storage.buckets.get",
    "storage.buckets.list",

    # Get, create, update, delete, and list container images, and also set IAM policy for the objects
    "storage.objects.get",
    "storage.objects.create",
    "storage.objects.update",
    "storage.objects.delete",
    "storage.objects.list",
    "storage.objects.getIamPolicy",
    "storage.objects.setIamPolicy",
  ]
}

# Allow CI jobs to push container images to GCR
resource "google_project_iam_binding" "gcr_read_write" {
  project = local.project_id
  role    = "projects/${local.project_id}/roles/${google_project_iam_custom_role.gcr_read_write.role_id}"
  members = [
    "serviceAccount:${google_service_account.github-actions-cicd.email}",
  ]
}
```

### Grant the service account access to deploy

Here's an example on how to deploy to your own staging and production clusters.

In the _production_ section of your Terraform repo:

```hcl
# Allow CI jobs to deploy to GKE clusters
resource "google_project_iam_member" "github-actions-cicd" {
  project = local.project
  role    = "roles/container.developer"  # or roles/container.admin if you need to deploy some cluster-scoped objects like ClusterRole
  member  = "serviceAccount:${google_service_account.github-actions-cicd.email}"
}
```

In the _staging_ section of your Terraform repo:

```hcl
# Allow CI jobs to deploy to GKE clusters
resource "google_project_iam_member" "github-actions-cicd" {
  project = local.project
  role    = "roles/container.developer"  # or roles/container.admin if you need to deploy some cluster-scoped objects like ClusterRole
  member  = "serviceAccount:github-actions-cicd@myproject-prd.iam.gserviceaccount.com"
}
```

> **Note:** We are granting the _production_ service account access to deploy to both _production_ and _staging_. No need to have separate service accounts for staging and production - if the CI job is allowed to deploy to production, it can also be allowed to deploy to staging.

### Configure WIF on the GCP side

Add this module invocation to your project's Terraform repository:

```hcl
module "github_actions_auth" {
  source          = "app.terraform.io/unity-technologies/pre-workload-identity-federation/google"
  version         = "2.0.6"
  github_instance = "github.com" # optional: defaults to github.com valid values are github.com, github.cds or github-vcs-sol
  service_accounts = {
    "deploy" : {
      service_account_id = google_service_account.github-actions-cicd.name
      additional_checks  = []
      allowed_repositories = [
        "Unity-Technologies/myproject",
      ]
    }
  }
}
```

### Impersonate a service account in your GitHub Actions workflow

If you're using a shared action/workflow that already includes the impersonation step, it will typically expect the following inputs:

```yaml
service_account: github-actions-cicd@myproject.iam.gserviceaccount.com
```

The project number can be seen in the web dashboard of Google Console or by typing `gcloud projects describe <your_project_name>` on the command line.

If you need to perform the impersonation step in your own workflow, you can use the `google-github-actions/auth@v1` action:

```yaml
jobs:
  <your_job_name>:
    permissions: write-all
...
- uses: "actions/checkout@v3"
- uses: google-github-actions/auth@v1
  with:
    workload_identity_provider: projects/525934517767/locations/global/workloadIdentityPools/github-com-unity-technologies/providers/github-com-unity-technologies #  replace github-com-unity-technologies with github-cds-unity if using GitHub.cds.internal.unity3d.com
    service_account: github-actions-cicd@myproject.iam.gserviceaccount.com
    retries: 3
```

After the Auth step, you can use any [Google-made GCP Action](https://github.com/google-github-actions) without specifying the credentials argument, and authentication should work automatically.

### References

If you want to see the different ways of configuring the Terraform module, check its [documentation](https://github.com/Unity-Technologies/terraform-google-pre-workload-identity-federation)

Here's some background information that you hopefully don't need:

- [Infrasec team's guide to authenticating GitHub Actions](https://backstage.corp.unity3d.com/docs/default/component/security-guides/gcp/github-actions/authenticating/)
- [GCP docs](https://cloud.google.com/iam/docs/workload-identity-federation)

---

## Using Workload Identity Federation (WIF) in GitHub Actions for Azure

A small guide on how to set up "Workload Identity Federation" for Azure using terraform. We only support this way of accessing the clusters through our actions.

See: <https://learn.microsoft.com/en-us/azure/active-directory/develop/workload-identity-federation>

### Pre-requisites

Run this workflow once in your repository: <https://github.com/Unity-Technologies/github-actions-workflows/blob/main/.github/workflows/customize_oidc.yml>. Copy-paste this under your `.github/workflows` and commit and push. See that it ran successfully under "Actions" tab in GitHub. You can now `git remove` it.

> **Note:** GitHub tokens contain context in the subject claim, but Azure requires an exact match, creating limitations. The workflow removes excess metadata from token `sub` claim, enabling proper assertion based on the repository name and overcoming these limitations. For details, consult the [GitHub Actions documentation](https://docs.github.com/en/actions/deployment/security-hardening-your-deployments/about-security-hardening-with-openid-connect#example-granting-access-to-a-specific-repository).

This Document assumes that you already have an AKS cluster created using terraform and have resource group associated with it. Something similar to this:

```hcl
resource "azurerm_resource_group" "aks" {
  location = "eastus"
  name     = "aks"
}
```

```hcl
resource "azurerm_kubernetes_cluster" "default" {
  # long cluster specific resource definition here
...
}
```

We reference to this resource group here later with `azurerm_resource_group.aks`.

We reference to this AKS cluster here later with `azurerm_kubernetes_cluster.default`.

### AKS Terraform resources

```hcl
resource "azurerm_user_assigned_identity" "github_actions" {
  name                = "github-actions"
  location            = azurerm_resource_group.aks.location
  resource_group_name = azurerm_resource_group.aks.name
}


locals {
  # a list of the repositories that have access to the github-actions managed identity
  github_actions_repositories = [
    "Unity-Technologies/my-repo",
    "Unity-Technologies/my-other-repo",
  ]
}

# Create federated identity credentials for each repository
resource "azurerm_federated_identity_credential" "federated_identity_credential_github_actions" {
  for_each            = toset(local.github_actions_repositories)
  name                = "github-actions-${md5(each.value)}"
  resource_group_name = azurerm_resource_group.aks.name
  audience            = ["api://AzureADTokenExchange"]
  issuer              = "https://token.actions.githubusercontent.com"
  parent_id           = azurerm_user_assigned_identity.github_actions.id
  subject             = "repo:${each.value}"
}

# assign Contributor role for "github-actions" identity to the AKS resource group
resource "azurerm_role_assignment" "github_actions_contributor" {
  principal_id          = azurerm_user_assigned_identity.github_actions.principal_id
  scope                 = azurerm_resource_group.aks.id
  role_definition_name = "Contributor"
}
```

### Setup ACR

This guides you how to create ACR (Azure Container Registry) and grant access for your cluster to pull images from there and grant access to your GitHub repository to push images there.

### ACR Terraform resources

```hcl
# create registry
resource "azurerm_container_registry" "registry" {
  # once created this will translate to yourregistrynamehere.azurecr.io
  # you can then push your service images to yourregistrynamehere.azurecr.io/my-service
  name                = "yourregistrynamehere"
  resource_group_name = azurerm_resource_group.aks.name
  location            = azurerm_resource_group.aks.location
  sku                 = "Premium"
}

# allow your cluster to pull images from this registry
resource "azurerm_role_assignment" "acr_pull" {
  principal_id                     = azurerm_kubernetes_cluster.default.kubelet_identity[0].object_id
  role_definition_name             = "AcrPull"
  scope                            = azurerm_container_registry.registry.id
  skip_service_principal_aad_check = true
}

# allow github actions to push images to this registry
resource "azurerm_role_assignment" "github_actions_acr_push" {
  principal_id         = azurerm_user_assigned_identity.github_actions.principal_id
  scope                = azurerm_container_registry.registry.id
  role_definition_name = "AcrPush"
}

# allow github actions to pull images to this registry
resource "azurerm_role_assignment" "github_actions_acr_pull" {
  principal_id         = azurerm_user_assigned_identity.github_actions.principal_id
  scope                = azurerm_container_registry.registry.id
  role_definition_name = "AcrPull"
}
```

### Notes

This feature is still on Beta on Azure side and they might improve this later.

You might need to apply the plan a couple of times.

Please note that registry name has to be more than 5 characters long and it has to be globally unique. We recommend to only use lower case characters.

---

## Using Vault secrets in your actions

### Important: Choose an authentication method that's right for your use case.

This guide is for using our internal [Vault](https://vault.corp.unity3d.com) in your GitHub actions for general-purpose build-time secrets, such as third-party API keys or credentials. If your goal is to authenticate a GitHub Action to a supported cloud provider, do not store a service account key in Vault. 
The recommended and more secure method is to use Workload Identity Federation ([WIF in GCP](https://docs.internal.unity.com/github-actions-workflows/user-guides/using_workload_identity_federation), [WIF in Azure](https://docs.internal.unity.com/github-actions-workflows/user-guides/using_workload_identity_federation_in_azure)). WIF allows your workflow to directly impersonate a GCP/Azure service account without managing long-lived keys.

- For third-party API keys or credentials, use Vault secrets (not GitHub secrets).
- For Authenticating to GCP, use [Workload Identity Federation](https://docs.internal.unity.com/github-actions-workflows/user-guides/using_workload_identity_federation)
- For Authenticating to Azure, use [Workload Identity Federation](https://docs.internal.unity.com/github-actions-workflows/user-guides/using_workload_identity_federation_in_azure)

- For runtime secrets see our [Vault Quickstart Guide](https://docs.internal.unity.com/vault/user-guides/quickstart).

### Expose the secret to your repository

Make a pull request to the [pre-terraform-vault-workspace repo](https://github.com/Unity-Technologies/pre-terraform-vault-workspace). You can find examples for github.com in [this file](https://github.com/Unity-Technologies/pre-terraform-vault-workspace/blob/master/prd/policies/auth-github-actions-github-com.tf) and [here](https://github.com/Unity-Technologies/pre-terraform-vault-workspace/blob/master/prd/policies/auth-github-actions-github-cds.tf) for github.cds. If you are using Vault KV Secrets Engine - Version 2 the path should include `.../data/...`. For Vault KV Secrets Engine - Version 1, this should be omitted.

If you don't already have have a secret store, approle, and okta group, you should create them following [this guide](https://docs.internal.unity.com/es-service-infra-setup/storing-secrets). If you already have a secret store you can use it here. If you are on "ads" you can use, the `secret/ads/prd/build/ads-your-service-name` for your build-time secrets, but you still need to make PR to map your secret path to your repositories to make them available for GitHub Actions.

> **Note:** Only repositories under the `Unity-Technologies` organization for GitHub.com or the `unity` GitHub.cds organization are currently supported.

### Use an internal runner

You must use our [internal runners](https://docs.internal.unity.com/github-actions-runners/user-guides/using-self-hosted-runners) to access our internal Vault because they communicate on the Shared VPC.

### Use the Vault action to fetch the secret

```yaml
jobs:
  fetch-secret-example:
    name: fetch-secret-example
    # it's required to use an internal runner to acccess vault
    runs-on: [ unity-linux-runner ]
    permissions: write-all
    steps:
    - id: global-config
      uses: Unity-Technologies/github-actions-workflows/actions/global-config@main
    - uses: actions/checkout@v3
    - name: Fetch Vault secrets
      id: 'fetch-vault-secrets'
      uses: hashicorp/vault-action@v2.5.0
      with:
        url: https://vault.corp.unity3d.com
        role: <use_the_role_name_from_your_PR>
        path: ${{ steps.global-config.outputs.vault-auth-path }}
        method: jwt
        # choose one of these based on the secret engine kv version you are using:
        # for vault KV Secrets Engine - Version 1, eg. all the secrets under /secrets
        secrets: |
          secret/<something>/SECRET_NAME secret | SECRET_ENV_VARIABLE_NAME ;
        # for vault KV Secrets Engine - Version 2
        secrets: |
          <something>/data/<something> SECRET_NAME | SECRET_ENV_VARIABLE_NAME ;
    # next steps now have the secret under this path from key secret in env variable called SECRET_ENV_VARIABLE_NAME
```

---

## Slack notifications

### Deployments

You can use [GitHub integration for Slack](https://github.com/integrations/slack#subscribe-to-an-organization-or-a-repository), that is installed into our Slack workspace to subscribe to deployment notifications. These notifications require you to have [environments](https://docs.github.com/en/actions/deployment/targeting-different-environments/using-environments-for-deployment) set for your repository.

e.g. `/github subscribe https://github.com/Unity-Technologies/github-actions-workflows-example`

If you have something like deployment channel and you are only interested in deployments, you can unsubscribe to other notifications.

```
/github unsubscribe https://github.com/Unity-Technologies/github-actions-workflows-example issues
/github unsubscribe https://github.com/Unity-Technologies/github-actions-workflows-example pulls
/github unsubscribe https://github.com/Unity-Technologies/github-actions-workflows-example commits
/github unsubscribe https://github.com/Unity-Technologies/github-actions-workflows-example releases
```

### Workflow runs

If you want to get a personal notification on workflow run failures you can use [GitHub native notification system](https://docs.github.com/en/actions/monitoring-and-troubleshooting-workflows/notifications-for-workflow-runs) for that.

### Custom notifications

Use the [send-slack-message workflow](https://github.com/Unity-Technologies/github-actions-workflows/tree/main/docs/workflows/send-slack-message/README.md) for any custom notifications you might need.

---

## Good Practices (Condensed)

### General guidelines

- **Optimize for speed:** Parallelize workflows and use [caching](https://docs.github.com/en/actions/using-workflows/caching-dependencies-to-speed-up-workflows) whenever possible. Only run workflows when relevant files change.
- **Automate everything:** GitHub Actions are not limited to CI/CD. Use them for PR review automation ([labeler](https://github.com/marketplace/actions/labeler), [release drafter](https://github.com/marketplace/actions/release-drafter), [close stale issues](https://github.com/marketplace/actions/close-stale-issues)).
- **Everything as code:** Avoid ClickOps. Keep configuration, alerts, dashboards, and deployments in code.

### Structuring workflows

- **Build Docker once:** Build one image and reuse it across environments.
- **Minimal runtime images:** Use [Distroless images](https://github.com/GoogleContainerTools/distroless) for smaller, more secure containers.
- **Use `paths` / `paths-ignore`:** Only [trigger workflows when relevant files change](https://docs.github.com/en/actions/using-workflows/workflow-syntax-for-github-actions#example-including-paths), or use [dorny/paths-filter](https://github.com/dorny/paths-filter).
- **Don't reinstall dependencies unnecessarily:** Cache installed software or use containers.
- **Lint everything:** Consider [Super Linter](https://github.com/github/super-linter).
- **Reliable, fast tests:** Avoid flaky tests. Run heavier suites only on PRs; run unit tests on every commit.
- **Fail fast:** Run fast checks (linters, unit tests) early or in parallel for rapid feedback.

### Don't reinvent the wheel

- Check the [example project](https://github.com/Unity-Technologies/github-actions-workflows-example).
- See [how others use these actions](https://github.com/search?q=org%3AUnity-Technologies+Unity-Technologies%2Fgithub-actions-workflows+path%3A.github%2Fworkflows&type=code&p=1).
- Use [community actions](https://github.com/marketplace). Prefer official actions; review code and pin to a commit SHA for less-known ones.
- Share reusable workflows/actions in the central repo.

### Process and workflows

- **Continuous Deployment:** Aim for small incremental changes, reviewed and deployed all the way to production after merge. Requires good test coverage, monitoring, and easy rollback.
- **Use [GitHub Environments](https://docs.github.com/en/actions/deployment/targeting-different-environments/using-environments-for-deployment):** Better visibility on deployments; gate production with [required approvals](https://docs.github.com/en/actions/deployment/targeting-different-environments/using-environments-for-deployment#required-reviewers).
- **Keep default branch green:** A broken default branch blocks merges and deployments for everyone.
- **Continuously optimize CI/CD:** Measure build times and improve them. Make CI/CD a team effort.

### Secrets and security

- Use [Vault](https://docs.internal.unity.com/github-actions-workflows/user-guides/using_vault_secrets) or GitHub Secrets for build-time secrets. Never store secrets in the repo. Prefer [Workload Identity Federation](https://docs.internal.unity.com/github-actions-workflows/user-guides/using_workload_identity_federation).
- Use security scanners like SonarQube and [Dependabot](https://docs.github.com/en/code-security/dependabot/dependabot-security-updates/configuring-dependabot-security-updates).

### Costs

- Use [self-hosted runners](https://docs.internal.unity.com/github-actions-runners/user-guides/using-self-hosted-runners) whenever possible (cheaper than GitHub-hosted).
- Be mindful of GitHub-provided macOS runner costs.

### Deployment options

| Option | When to use |
|--------|-------------|
| **Standard Deployments (ArgoCD / GitOps)** | Default for all new services. Render manifests, commit to a GitOps state repo, and let ArgoCD sync. Use the `argocd-onboarding` skill to get started. |
| **deploy-with-common-chart** | Legacy. Only for existing services already using direct Helm deploy. Not recommended for new services. |

---

## Using JFrog Artifactory with GitHub Actions

> Upstream source: [docs/user-guides/using_jfrog_artifactory.md](https://github.com/Unity-Technologies/github-actions-workflows/blob/main/docs/user-guides/using_jfrog_artifactory.md)

We have created example projects for Node.js and Python to showcase how JFrog Artifactory can be used with each language:

- [github-actions-workflows-npm-example](https://github.com/Unity-Technologies/github-actions-workflows-npm-example)
- [github-actions-workflows-pypi-example](https://github.com/Unity-Technologies/github-actions-workflows-pypi-example)

### Getting started with JFrog Artifactory

To get started with JFrog see the [JFrog Artifactory docs](https://docs.internal.unity.com/jfrog) and how to [pull and publish artifacts](https://docs.internal.unity.com/jfrog/getting-started#2-do-you-have-a-pipeline-that-pulls-and-pushes-to-jfrog-how-to-pull-artifacts-from-and-publish-artifacts-to-jfrog).

For publishing, you need [your own JFrog token](https://docs.internal.unity.com/jfrog/getting-started#creating-access-tokens-eg-for-ci) stored in Vault (see the Vault secrets section above).

### Using jfrog-readonly token

A general read-only token that can be fetched from Vault for any GitHub Actions workflow:

```yaml
- id: global-config
  uses: Unity-Technologies/github-actions-workflows/actions/global-config@main
- name: Get the token
  uses: hashicorp/vault-action@v2.5.0
  with:
    url: https://vault.corp.unity3d.com
    role: github-actions-repos-all
    path: ${{ steps.global-config.outputs.vault-auth-path }}
    method: jwt
    secrets: |
      pre/data/github-actions-workflows/jfrog-readonly JFROG_ARTIFACTORY_USER | JFROG_ARTIFACTORY_USER;
      pre/data/github-actions-workflows/jfrog-readonly JFROG_ARTIFACTORY_TOKEN | JFROG_ARTIFACTORY_TOKEN;
```

### Saving the token to .npmrc

```yaml
- name: Checkout
  uses: actions/checkout@v3

- name: Get auth token for JFrog
  uses: Unity-Technologies/github-actions-workflows/actions/auth-npm@main
```

### Installing dependencies from NPM registry with authentication

```yaml
name: Install from Artifactory NPM

on:
  push:
    branches: [main, master]
  pull_request:

jobs:
  build:
    runs-on: [unity-linux-runner]
    permissions: write-all
    steps:
      - id: global-config
        uses: Unity-Technologies/github-actions-workflows/actions/global-config@main

      - name: Checkout
        uses: actions/checkout@v3

      - name: Authenticate and Install dependencies
        uses: Unity-Technologies/github-actions-workflows/actions/npm-ci-install@main
        with:
          node-version: "16.18.0"
```

### Publishing packages to NPM registry

```yaml
name: Publish to Artifactory NPM

on:
  push:
    branches: [main, master]
  pull_request:

defaults:
  run:
    working-directory: ./npm-package-publish-test

jobs:
  publish:
    runs-on: [unity-linux-runner]
    needs: build
    if: github.ref == 'refs/heads/master' || github.ref == 'refs/heads/main'
    permissions: write-all
    steps:
      - id: global-config
        uses: Unity-Technologies/github-actions-workflows/actions/global-config@main

      - name: Checkout
        uses: actions/checkout@v3

      - name: Fetch Vault secrets
        uses: hashicorp/vault-action@v2.5.0
        with:
          url: https://vault.corp.unity3d.com
          role: github-actions-repos-jfrog-pre-dev-github-actions-rw
          path: ${{ steps.global-config.outputs.vault-auth-path }}
          method: jwt
          # Replace with your npm repo write secret
          secrets: |
            pre/data/github-actions-workflows/jfrog-pre-dev-github-actions-rw JFROG_ARTIFACTORY_TOKEN | NODE_AUTH_TOKEN;

      - name: Use Node.js 16.18.0
        uses: actions/setup-node@v3
        with:
          node-version: '16.18.0'
          cache: 'npm'
          # Replace with your registry and scope
          registry-url: 'https://unity3d.jfrog.io/artifactory/api/npm/pre-npm-dev-local'
          scope: '@pre'

      - name: Publish to registry
        run: npm publish
```

### Installing dependencies from PyPi registry

```yaml
name: Install from Artifactory PyPi

on:
  push:
    branches: [main, master]
  pull_request:

jobs:
  build:
    runs-on: [unity-linux-runner]
    permissions: write-all
    steps:
      - id: global-config
        uses: Unity-Technologies/github-actions-workflows/actions/global-config@main

      - uses: actions/checkout@v3

      - name: Set up Python
        uses: actions/setup-python@v4
        with:
          python-version: "3.10"
          cache: "pip"

      - name: Fetch Vault secrets
        uses: hashicorp/vault-action@v2.5.0
        with:
          url: https://vault.corp.unity3d.com
          role: github-actions-repos-all
          path: ${{ steps.global-config.outputs.vault-auth-path }}
          method: jwt
          secrets: |
            pre/data/github-actions-workflows/jfrog-readonly JFROG_ARTIFACTORY_USER | JFROG_ARTIFACTORY_USER;
            pre/data/github-actions-workflows/jfrog-readonly JFROG_ARTIFACTORY_TOKEN | JFROG_ARTIFACTORY_TOKEN;

      - name: Install dependencies
        run: |
          pip install -r requirements.txt \
            --index-url https://$JFROG_ARTIFACTORY_USER:$JFROG_ARTIFACTORY_TOKEN@unity3d.jfrog.io/artifactory/api/pypi/pre-pypi-dev-local/simple \
            --extra-index-url https://pypi.org/simple
```

### Publishing packages to PyPi registry

```yaml
publish:
  runs-on: [unity-linux-runner]
  permissions: write-all
  needs: build
  if: github.ref == 'refs/heads/master' || github.ref == 'refs/heads/main'
  steps:
    - id: global-config
      uses: Unity-Technologies/github-actions-workflows/actions/global-config@main

    - uses: actions/checkout@v3

    - name: Set up Python 3.10
      uses: actions/setup-python@v4
      with:
        python-version: "3.10"

    - name: Fetch Vault secrets
      uses: hashicorp/vault-action@v2.5.0
      with:
        url: https://vault.corp.unity3d.com
        role: github-actions-repos-jfrog-pre-dev-github-actions-rw
        path: ${{ steps.global-config.outputs.vault-auth-path }}
        method: jwt
        secrets: |
          pre/data/github-actions-workflows/jfrog-pre-dev-github-actions-rw JFROG_ARTIFACTORY_USER | JFROG_ARTIFACTORY_USER;
          pre/data/github-actions-workflows/jfrog-pre-dev-github-actions-rw JFROG_ARTIFACTORY_TOKEN | JFROG_ARTIFACTORY_TOKEN;

    - name: Build and upload
      run: |
        python setup.py sdist bdist_wheel
        twine upload dist/* --skip-existing \
          --repository-url https://unity3d.jfrog.io/artifactory/api/pypi/pre-pypi-dev-local \
          -u "$JFROG_ARTIFACTORY_USER" -p "$JFROG_ARTIFACTORY_TOKEN"
```

### Installing a chart from the Helm registry

```yaml
name: Install chart from Helm registry

on:
  push:
    branches: [main, master]
  pull_request:

jobs:
  build:
    runs-on: [unity-linux-runner]
    permissions: write-all
    steps:
      - id: global-config
        uses: Unity-Technologies/github-actions-workflows/actions/global-config@main

      - name: Checkout
        uses: actions/checkout@v3

      - name: Fetch Vault secrets
        uses: hashicorp/vault-action@v2.5.0
        with:
          url: https://vault.corp.unity3d.com
          role: github-actions-repos-all
          path: ${{ steps.global-config.outputs.vault-auth-path }}
          method: jwt
          secrets: |
            pre/data/github-actions-workflows/jfrog-readonly JFROG_ARTIFACTORY_USER | JFROG_ARTIFACTORY_USER;
            pre/data/github-actions-workflows/jfrog-readonly JFROG_ARTIFACTORY_TOKEN | JFROG_ARTIFACTORY_TOKEN;

      - name: Install Kronus helm chart
        run: |
          helm repo add kronus https://unity3d.jfrog.io/artifactory/kronus-helm-prod/ --username $JFROG_ARTIFACTORY_USER --password $JFROG_ARTIFACTORY_TOKEN
          helm install kronus kronus/kronus-client
```

For Helmsman-managed charts, export the secrets as environment variables and substitute them in your repo URLs:

```yaml
helmRepos:
  kronus: "https://$JFROG_ARTIFACTORY_USER:$JFROG_ARTIFACTORY_TOKEN@unity3d.jfrog.io/artifactory/kronus-helm-prod/"
```

---

## Building and Deploying Multiple Services

> Upstream source: [docs/user-guides/building_and_deploying_multiple_services.md](https://github.com/Unity-Technologies/github-actions-workflows/blob/main/docs/user-guides/building_and_deploying_multiple_services.md)

Key GitHub Actions features for multi-service repos:

- **`needs`** — sequence jobs (e.g., deploy staging before production)
- **`matrix`** — run multiple instances in parallel with different inputs. Use `max-parallel: 1` for sequential.
- **`environment`** — manual approval rules per deployment target
- **`concurrency`** — prevent simultaneous deployments per service

### Building multiple container images

```yaml
jobs:
  build:
    name: Build Image
    runs-on: [unity-linux-runner]
    permissions: write-all
    strategy:
      matrix:
        name: ["service1", "service2"]
        include:
          - name: service1
            image_name: gcr.io/unity-ads-common-prd/my-app
            docker_path: Dockerfile
          - name: service2
            image_name: gcr.io/unity-ads-common-prd/my-app-service2
            docker_path: service2.Dockerfile
    steps:
      - name: Checkout
        uses: actions/checkout@v3
      - name: Build
        uses: Unity-Technologies/github-actions-workflows/actions/build-docker-image@main
        with:
          docker_path: ${{ matrix.docker_path }}
          image_name: ${{ matrix.image_name }}
          service_account: ${{ env.gke_deploy_service_account }}
```

### Deploying multiple services with matrix + environment approvals

```yaml
jobs:
  deploy_prd:
    name: Deploy Production
    runs-on: [unity-linux-runner]
    permissions: write-all
    needs: canary
    if: github.ref == 'refs/heads/master' || github.ref == 'refs/heads/main'
    environment:
      name: production-${{ matrix.service }}
    concurrency: production-${{ github.ref }}-${{ matrix.service }}
    strategy:
      matrix:
        service: ["service1", "service2"]
    steps:
      - name: Checkout
        uses: actions/checkout@v3
      - name: Deploy
        uses: Unity-Technologies/github-actions-workflows/actions/deploy-with-common-chart@main
        with:
          helm_directory: helm/${{ matrix.service }}
          helm_env: prd
          gke_cluster: ${{ env.gke_cluster_prd }}
          gke_project: ${{ env.gke_project_prd }}
          helm_release: ${{ env.project_name }}-${{ matrix.service }}
          service_account: ${{ env.gke_deploy_service_account }}
```

### Rolling back multiple services

```yaml
jobs:
  rollback_prd:
    name: Rollback Production
    runs-on: [unity-linux-runner]
    permissions: write-all
    concurrency: production-${{ github.ref }}-${{ matrix.service }}
    strategy:
      matrix:
        service: ["service1", "service2"]
    steps:
      - name: Rollback
        uses: Unity-Technologies/github-actions-workflows/actions/rollback-helm@main
        with:
          gke_cluster: ${{ env.gke_cluster_prd }}
          gke_project: ${{ env.gke_project_prd }}
          helm_release: ${{ env.project_name }}-${{ matrix.service }}
          service_account: ${{ env.gke_deploy_service_account }}
```

Define environments (e.g., `production-service1`, `production-service2`) in your GitHub repo settings to configure approval rules.
