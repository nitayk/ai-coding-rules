# GitHub Actions Workflows — Complete Catalog

All actions and workflows available in `Unity-Technologies/github-actions-workflows`.
Each entry includes key inputs and a pointer to the bundled reference file with full documentation.

## Table of Contents
- [Build](#build)
- [Deployment](#deployment)
- [ArgoCD](#argocd)
- [Documentation](#documentation)
- [Linting and Formatting](#linting-and-formatting)
- [Monitoring and Alerting](#monitoring-and-alerting)
- [Security and Code Analysis](#security-and-code-analysis)
- [Terraform](#terraform)
- [Authentication and Access](#authentication-and-access)
- [Utility](#utility)

---

## Build
**Reference file:** `build-and-registry.md`

| Name | Type | Description | Key inputs |
|------|------|-------------|------------|
| build-docker-image | action | Build docker image, push to GCR/GAR/ACR/ECR. Multi-arch support | `image_name`, `service_account`, `cloud`, `push`, `platforms` |
| create-docker-manifest | action | Create multi-arch Docker manifest from arch-specific images | `manifest_tag`, `source_images`, `service_account` |
| vm-image-build | workflow | Build and push a VM / bare-metal image with Packer | `packer_directory`, `cloud`, `service_account` |
| gcr-cleaner | action | Clean up old container registry images | `registries`, `service_account`, `grace` |

## Deployment
**Reference file:** `argocd-and-gitops.md` (Standard Deployments)

| Name | Type | Description | Key inputs |
|------|------|-------------|------------|
| deploy-prebuilt-manifests | workflow | Deploy prebuilt manifests to a cluster | `gh_repository`, `service`, `environment` |

> **Note:** The legacy direct Helm deployment actions (`deploy-with-common-chart`, `preview-helm-changes`, `rollback-helm`) are not bundled in this skill. New services must use Standard Deployments (ArgoCD). If you have an existing service using direct Helm deploy and need help, refer to the upstream docs at [Unity-Technologies/github-actions-workflows](https://github.com/Unity-Technologies/github-actions-workflows).

## ArgoCD
**Reference file:** `argocd-and-gitops.md`

| Name | Type | Description | Key inputs |
|------|------|-------------|------------|
| render-with-common-chart | action | Render manifests using the common Helm chart | `service`, `environment`, `helm_directory` |
| render-with-kustomize | action | Render manifests with Kustomize | `service`, `environment`, `kustomize_directory` |
| render-with-helmfile | action | Render manifests with Helmfile | `service`, `environment`, `helmfile_directory` |
| render-with-tessen | action | Render manifests with Tessen | `service`, `environment` |
| preview-rendered-manifests | action | Preview rendered/prebuilt manifests changes | `service`, `environment`, `gh_repository` |
| deploy-rendered-manifests | action | Deploy rendered manifests to GitOps state repo | `service`, `environment`, `gh_repository` |
| render-with-common-chart | workflow | Render with Common Chart (reusable) | `service`, `environment`, `gh_repository`, `app_name` |
| render-with-kustomize | workflow | Render with Kustomize (reusable) | `service`, `environment`, `gh_repository` |
| render-with-tessen | workflow | Render with Tessen (reusable) | `service`, `environment`, `gh_repository` |
| preview-rendered-manifests-with-common-chart | workflow | Preview rendered manifests | `service`, `environment`, `gh_repository`, `app_name` |
| preview-prebuilt-manifests | workflow | Preview prebuilt manifests | `service`, `environment`, `gh_repository` |
| preview-cluster-component-changes | workflow | Preview cluster component changes | `cluster`, `gh_repository` |
| render-cluster-components | workflow | Render cluster components | `cluster`, `gh_repository` |
| deploy-prebuilt-manifests | workflow | Deploy prebuilt manifests | `gh_repository`, `service`, `environment` |
| revert-rendered-manifest-deployments | workflow | Revert rendered manifest deployments | `gh_repository`, `service`, `environment` |
| create-pr-preview-env | workflow | Create a PR preview environment | `gh_repository`, `service`, `environment` |
| destroy-pr-preview-env | workflow | Destroy a PR preview environment | `gh_repository`, `service`, `environment` |

## Documentation
**Reference file:** `docs-and-linting.md`

| Name | Type | Description | Key inputs |
|------|------|-------------|------------|
| mkdocs | action | Build and publish MkDocs documentation to GCS | `gcs_bucket`, `service_account` |
| docusaurus | action | Build Docusaurus documentation | `gcs_bucket`, `service_account` |
| techdocs-build | action | Build TechDocs for Backstage | `entity_kind`, `entity_name`, `entity_namespace` |
| techdocs-build | workflow | TechDocs build (reusable) | `entity_name`, `entity_namespace` |
| techdocs-preview | workflow | TechDocs preview | `entity_name` |
| blob-proxy | workflow | Publish docs to internal service pages | `cloud`, `service_account` |
| table-of-contents-checker | workflow | Check table of contents in docs | `file_types`, `directories` |
| docs-links-checker | workflow | Check for broken links in docs | `config_file` |

## Linting and Formatting
**Reference file:** `docs-and-linting.md`

| Name | Type | Description | Key inputs |
|------|------|-------------|------------|
| oas-validation | action | OpenAPI spec validation with annotations | `spectral_ruleset`, `fail_severity` |
| common-openapi-rules-setup | action | Set up common OpenAPI validation rules | (none) |
| terraform-format | action | Terraform fmt with auto-suggest fixes | `check_only`, `working_directory` |
| packer-format | action | Packer fmt with auto-suggest fixes | `check_only`, `working_directory` |
| terraform-format | workflow | Run Terraform fmt (reusable) | `working_directory` |
| packer-format | workflow | Run Packer fmt (reusable) | `working_directory` |
| openapi-validation | workflow | OpenAPI specifications validation | `spectral_ruleset` |
| lint-yaml | workflow | YAML linting | `config_file` |
| validate-input | action | Validate action inputs (internal) | — |
| remove-deactivated-users | workflow | Remove deactivated users | (admin) |
| remove-deactivated-users-auto-merge | workflow | Remove deactivated users with auto-merge | (admin) |

## Monitoring and Alerting
**Reference file:** `monitoring-and-notifications.md`

| Name | Type | Description | Key inputs |
|------|------|-------------|------------|
| duke | workflow | Configure monitoring and alerts with Duke | `duke_config_path`, `service_account` |
| duke-reviewer | workflow | Duke reviewer workflow | `duke_config_path` |
| dashboards-as-code | workflow | Generate Grafana dashboards from code | `dashboard_path`, `service_account` |
| send-slack-message | workflow | Send a Slack message | `channels`, `message` |
| test-alerts | action | Test alerting rules with promtool | `rules_path` |
| send-event-to-loki | action | Send events to Loki | `message`, `labels` |
| shared-workflow-stats | action | Record shared workflow usage stats (internal) | `shared_workflow_id` |
| duke-reviewer-comment | action | Duke reviewer comment for monitoring PRs | (internal) |

## Security and Code Analysis
**Reference file:** `utility-actions.md`

| Name | Type | Description | Key inputs |
|------|------|-------------|------------|
| only-allowed-files-changed | action | Validate only allowed files changed in PR | `allowed_files` |
| fail-on-label | action | Fail workflow if a specific label is present | `label` |

## Terraform
**Reference file:** `utility-actions.md`

| Name | Type | Description | Key inputs |
|------|------|-------------|------------|
| fetch-tfcloud-plan | action | Fetch Terraform Cloud Plan output and post to PR | `workspace_id`, `token` |
| terraform-pr-auto-approver | action | Auto-approve Terraform PRs based on plan output | `workspace_id` |

## Authentication and Access
**Reference file:** `auth-and-secrets.md`

| Name | Type | Description | Key inputs |
|------|------|-------------|------------|
| auth-gke | action | Authenticate to GKE cluster, set up kubectl and helm | `project_id`, `cluster_name`, `cluster_location`, `service_account` |
| auth-aks | action | Authenticate to AKS cluster | `resource_group`, `cluster_name`, `client-id`, `subscription-id` |
| auth-eks | action | Authenticate to EKS cluster | `cluster_name`, `role-to-assume`, `aws-region` |
| auth-npm | action | Authenticate NPM with JFrog Artifactory (read-only) | `working-directory` |
| github-app-token | action | Generate a GitHub App token | `app_id`, `vault_addr` |
| get-secrets-from-azurekeyvault | action | Get secrets from Azure Key Vault | `keyvault_name`, `secret_name`, `client-id` |
| fetch-vault-using-proxy | action | Fetch Vault secrets using proxy | `vault_addr`, `role`, `secrets` |
| fetch-remote-github-token | action | Fetch a remote GitHub token (composite action, used internally by the workflow) | `repository`, `permissions` |
| decrypt-remote-github-token | action | Decrypt a remote GitHub token | `encrypted_token` |
| fetch-remote-github-token | workflow | Fetch Remote GitHub token (reusable workflow — prefer this over the action) | `repository_name` |
| global-config | action | Global configuration (WIF provider, Vault path) | (no required inputs) |

## Utility
**Reference file:** `utility-actions.md`

| Name | Type | Description | Key inputs |
|------|------|-------------|------------|
| cache-node-modules | action | Set up Node.js and install/cache node modules | `node-version`, `working-directory` |
| npm-ci-install | action | NPM ci/install with caching | `working-directory` |
| npm-package-check | action | Check NPM package existence in JFrog | `package_name`, `package_version` |
| cache-gcloud-sdk | action | Install and cache gcloud SDK | `version` |
| ios-sdk-cache | action | Cache iOS SDK | `xcode_version` |
| cleanup-artifactory-builds | action | Clean up old Artifactory builds | `repository`, `older_than` |
| download-yamato-artifact | action | Download Yamato artifact | `artifact_name`, `build_number` |
| merge-coverage | action | Merge code coverage reports | `coverage_files` |
| commit-dist | action | Commit dist folder of TS/JS actions | (internal) |
| sync-files-remote-pull-request | action | Sync files in a remote pull request | `repository`, `files` |
| prevent-merges-during-the-build | action | Block PR merges while build in progress | (no required inputs) |
| sendsafely | action | Create secure SendSafely packages | `files`, `recipients` |
| send-slack-message | workflow | Send a Slack message | `channels`, `message` |
| trigger-workflow-and-wait | workflow | Trigger workflow in another repo and wait | `workflow`, `repo` |
| run-on-pull-request-comment | workflow | Run workflow triggered by PR comment | `trigger_phrase` |
| helm-chart-validate-publish | workflow | Validate and publish Helm charts | `chart_path` |
| merge-coverage | workflow | Merge coverage reports (reusable) | `coverage_files` |
| customize_oidc | workflow | Customize OIDC subject claim (run once) | (no inputs) |
