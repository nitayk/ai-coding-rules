# Authentication and Secrets — Reference Documentation

> **Provenance (not runtime dependencies):**
> These docs are bundled from [Unity-Technologies/github-actions-workflows](https://github.com/Unity-Technologies/github-actions-workflows).
> If upstream docs change, refresh this file to match; do not improvise new workflow YAML.
> Last synced: 2026-04-09

---

## auth-gke

Composite action that authenticates to a GKE cluster and sets up `helm` and `kubectl`. You can use this action to access a cluster and run some commands against it.

This action is used internally by deploy and rollback actions.

Action [source code](https://github.com/Unity-Technologies/github-actions-workflows/blob/main/actions/auth-gke/action.yml).

### Pre-requisites

If you are in the "ads ecosystem" and want to use shared `ci-deploy` and `ci-push` account you can just add your repo here: <https://github.com/Unity-Technologies/mz-terraform-common-workspace/blob/a9792ee52ed6515a15c3c151a5a92b2c4d909d64/variables-local.tf#L130>

Otherwise you need to set up Workload Identity Federation for your service account that you would like to use for deploying to your cluster: [Configuring Workload Identity Federation (WIF)](https://github.com/Unity-Technologies/github-actions-workflows/blob/main/docs/user-guides/using_workload_identity_federation.md)

This action is typically used with our self-hosted GitHub runner. These runners need to be able to reach your GKE cluster. You need to allow them by adding our public NAT addresses in your `master_authorized_networks_config` in your GKE's terraform resource.

The self-hosted GitHub runners are deployed within the Shared VPC and span multiple regions. We currently deploy these runners in the europe-west1 and us-central1 regions.

### Inputs

| parameter                  | description                                                                                                                                                     | required | default       |
|----------------------------|-----------------------------------------------------------------------------------------------------------------------------------------------------------------|----------|---------------|
| gke_cluster                | GKE cluster                                                                                                                                                     | `true`   |               |
| gke_project                | GKE project                                                                                                                                                     | `true`   |               |
| gke_location               | GKE location                                                                                                                                                    | `false`  | `us-central1` |
| helm_cli_version           | Helm version                                                                                                                                                    | `false`  | `v3.9.0`      |
| kubectl_version            | Kubectl client version                                                                                                                                          | `false`  | `v1.23.8`     |
| workload_identity_provider | Workload identity provider (Deprecated. Uses [PRE Centralized Workload Identity Provider](https://docs.internal.unity.com/pre-unity-identity-pools) by default) | `false`  |               |
| service_account            | Service Account used by workload identity provider                                                                                                              | `true`   |               |

### Usage / example

```yaml
name: my workflow

on: [push, workflow_dispatch]

jobs:
  # do a build and other CI/CD things here
  auth_gke:
    name: Auth GKE
    runs-on: [unity-linux-runner]
    steps:
      - name: Checkout
        uses: actions/checkout@v3
      - name: Auth GKE
        uses: Unity-Technologies/github-actions-workflows/actions/auth-gke@main
        with:
          # required
          gke_cluster: ads-gke-test-usc1
          gke_project: ads-gke-test
          service_account: ci-deploy@unity-ads-common-prd.iam.gserviceaccount.com
          # optional
          gke_location: us-central1
          helm_cli_version: v3.9.0
          kubectl_version: v1.23.8
          # run any kubectl or helm command here
```

### Recommended usage

- Use this whenever you want to do some action in your cluster with `kubectl` or `helm`.
- The checkout step must be done before this action is called, omitting the checkout step or putting it after this action will cause future steps to be unable to authenticate.

---

## auth-aks

Composite action that authenticates to an AKS (Azure Kubernetes Service) cluster and sets up `helm` and `kubectl` optionally. You can use this action to access a cluster and run some commands against it.

This action is used internally by deploy and rollback actions.

Action [source code](https://github.com/Unity-Technologies/github-actions-workflows/blob/main/actions/auth-aks/action.yml).

### Pre-requisites

See this [guide](https://github.com/Unity-Technologies/github-actions-workflows/blob/main/docs/user-guides/using_workload_identity_federation_in_azure.md) on how to setup Workload Identity Federation for Azure.

### Inputs

| parameter                 | description                                         | required | default                                |
| ------------------------- | --------------------------------------------------- | -------- | -------------------------------------- |
| aks_cluster               | AKS cluster                                         | `true`   |                                        |
| aks_resource_group        | AKS resource group                                  | true     | `aks`                                  |
| helm_cli_version          | Helm version                                        | `false`  | v3.9.0                                 |
| kubectl_version           | Kubectl client version                              | `false`  | v1.23.8                                |
| client-id                 | Client ID                                           | `true`   |                                        |
| tenant-id                 | Tenant ID                                           | `false`  | `45b9a1d4-a8af-40da-8eca-96bebddf6fc7` |
| subscription-id           | Subscription ID                                     | `true`   |                                        |
| install_cli               | If install AZ CLI                                   | `false`  | `false`                                |
| install_helm              | If installing Helm                                  | `false`  | `true`                                 |
| install_kubectl           | If installing kubectl                               | `false`  | `true`                                 |
| install_kubelogin         | If installing keubelogin                            | `false`  | `true`                                 |
| install_kubelogin_version | kubelogin version                                   | `false`  | `v0.0.32`                              |
| auth_aks                  | If authenticating to the AKS e.g. the `aks_cluster` | `false`  | `true`                                 |

### Usage / example

```yaml
name: my workflow

on: [push, workflow_dispatch]

jobs:
  auth_aks:
    name: Auth AKS
    runs-on: [unity-linux-runner]
    permissions: write-all
    needs: [concurrent-run]
    steps:
      - name: Checkout
        uses: actions/checkout@v3
      - name: Auth AKS
        id: auth_aks
        uses: Unity-Technologies/github-actions-workflows/actions/auth-aks@main
        with:
          client-id: 4d60ba58-ea77-45f7-b246-214078be14b9
          subscription-id: 0788f43f-1bd7-4728-a6ae-c75a91a54295
          aks_cluster: unity-pre-services-test
      # run any kubectl or helm command here
```

### Recommended usage

- Use this whenever you want to do some action in your cluster with `kubectl` or `helm`.
- The checkout step must be done before this action is called, omitting the checkout step or putting it after this action will cause future steps to be unable to authenticate.
- If you run this action on a GitHub hosted runner or a runner that has `az` CLI installed, you should set `install_cli` to `false`.

---

## auth-eks

Composite action that authenticates to an EKS (Elastic Kubernetes Service for AWS) cluster and sets up `helm` and `kubectl`. You can use this action to access a cluster and run some commands against it.

This action is used internally by deploy and rollback actions.

Action [source code](https://github.com/Unity-Technologies/github-actions-workflows/blob/main/actions/auth-eks/action.yml).

### Pre-requisites

[Set up OIDC for your EKS cluster](https://github.com/Unity-Technologies/pre-terraform-services-workspace/tree/main/aws/modules/github-actions-oidc)

### Inputs

| parameter | description | required | default |
| - | - | - | - |
| cluster_name | Cluster Name | `true` |  |
| role-to-assume | role to assume. should look like this: arn:aws:iam::111111111111:role/my-github-actions-role-test | `true` |  |
| aws-region | AWS region defaults to us-east-1 | `false` | us-east-1 |
| helm_cli_version| Helm version | `false` | v3.9.0 |
| kubectl_version | Kubectl client version | `false` | v1.23.8 |
| install_cli     | If install AWS CLI     | `false`  | `true` |

### Usage / example

```yaml
name: my workflow

on: [push, workflow_dispatch]

jobs:
  auth_eks:
    name: Auth EKS
    runs-on: [unity-linux-runner]
    permissions: write-all
    needs: [concurrent-run]
    steps:
      - name: Checkout
        uses: actions/checkout@v3

      - name: Auth EKS
        id: auth_eks
        uses: Unity-Technologies/github-actions-workflows/actions/auth-eks@main
        with:
          # use your own values here:
          cluster_name: pre-services-test
          role-to-assume: arn:aws:iam::866313802286:role/github-actions
          aws-region: us-east-1
```

### Recommended usage

- Use this whenever you want to do some action in your cluster with `kubectl` or `helm`.
- The checkout step must be done before this action is called, omitting the checkout step or putting it after this action will cause future steps to be unable to authenticate.
- If you run this action on a GitHub hosted runner or a runner that has `aws` CLI installed, you should set `install_cli` to `false`.

---

## global-config

An action that exposes common configuration values for use in other actions.

Action [source code](https://github.com/Unity-Technologies/github-actions-workflows/blob/main/actions/global-config).

### Outputs

| **Name**                         | **Description**                                                                                                                                                       |
|----------------------------------|-----------------------------------------------------------------------------------------------------------------------------------------------------------------------|
| `gcp-workload-identity-provider` | The workload identity provider to use for GCP authentication. See [PRE Centralized Workload Identity Pools](https://docs.internal.unity.com/pre-unity-identity-pools) |
| `vault-auth-path`                | Vault Auth Path to use for GitHub Actions                                                                                                                             |

### Usage / example

```yaml
name: Example workflow

on:
  workflow_dispatch:
    inputs:

jobs:
  my_job:
    name: My Job
    runs-on: [unity-linux-runner]
    steps:
      - id: global-config
        uses: Unity-Technologies/github-actions-workflows/actions/global-config@main

      - name: Authenticate Google Cloud SDK
        uses: google-github-actions/auth@v1
        with:
          workload_identity_provider: ${{ steps.global-config.outputs.gcp-workload-identity-provider }}
          service_account: <service-account-name>@<gcp-project>.iam.gserviceaccount.com
      
      - name: Fetch Vault secrets
        uses: hashicorp/vault-action@v2.5.0
        with:
          url: https://vault.corp.unity3d.com
          path: ${{ steps.global-config.outputs.vault-auth-path }}
          method: jwt
          role: <role-name>
          secrets: |
            ...
...
```

---

## github-app-token

An action used to generate an auth token on behalf of a GitHub App.

Action [source code](https://github.com/Unity-Technologies/github-actions-workflows/blob/main/actions/github-app-token/action.yaml).

### Pre-requisites

You need to have a GitHub App, installed on the repository running this GitHub action. You also need a private key generated for this GitHub app.

You can also install the app on another repo, and use the authentication like if it was a service account to perform actions on a remote repository.

### Inputs

| parameter      | description                                                                                                                                                                                    | required | default                                                          |
| -------------- | ---------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- | -------- | ---------------------------------------------------------------- |
| app-id         | The GitHub app identifier                                                                                                                                                                      | `true`   |                                                                  |
| private-key    | A private key generated from the GitHub app                                                                                                                                                    | `true`   |                                                                  |
| repository     | The repository where the app is installed (owner/repo).                                                                                                                                        | `false`  | By default this will be the repository running the GitHub action |
| GitHub-api-url | The GitHub api endpoint, useful for private GitHub installations                                                                                                                               | `false`  | The API endpoint from the GitHub action context                  |
| permissions    | Custom permissions needed for the auth token. When specified, this must be a subset of the permissions granted to the GitHub app. This is useful to grant less permissions for specific cases. | `false`  | All the permissions granted to the GitHub app.                   |

### Outputs

| parameter | description    |
| --------- | -------------- |
| token     | the auth token |

### Usage / example

```yaml
name: my workflow

on:
  issues:
    types: [assigned]

jobs:
  add-issue-comment:
    name: Add an automated comment to an issue as a GitHub App
    runs-on: ubuntu-latest
    steps:
      - name: Get GitHub App auth token
        id: generate_token
        uses: Unity-Technologies/github-actions-workflows/actions/github-app-token@main
        with:
          app-id: "307534"
          private-key: ${{ secrets.MY_PRIVATE_KEY }}
      ## Obviously, your GitHub App needs its permissions to match the action you're trying to perform
      - name: Add labels as the GitHub App
        uses: actions/github-script@v6
        with:
          github-token: ${{ steps.generate_token.outputs.token }}
          script: |
            github.rest.issues.createComment({
              issue_number: context.issue.number,
              owner: context.repo.owner,
              repo: context.repo.repo,
              body: `This is an automated comment`
            })
```

---

## fetch-remote-github-token (reusable workflow)

A reusable workflow that can be used to fetch a GitHub token for a remote repository, so long as the calling repository has been approved to do so.

Workflow [source code](https://github.com/Unity-Technologies/github-actions-workflows/blob/main/.github/workflows/fetch-remote-github-token.yml).

### Pre-requisites

- The remote repository must be assigned the `pre-shared-workflows-auth` app. You can use [repodb](https://repodb.ds.unity3d.com/app) to do this. Note: There is an app for github.com and github.cds you need to assign the app for the github instance where the remote repository is hosted.
- The remote repository must have a `.github/allowed-remote-repos.yaml` file with the following format:

```yaml
# This file is used to specify which remote workflows are allowed to trigger this repos workflows.
workflows:
# Allow the following remote workflows to fetch a temporary GitHub token for write access to this repo
allow-fetch-token:
    - Unity-Technologies/tessen-infra/.github/workflows/update-chart-version.yaml@.* # Allow all branches
    - Unity-Technologies/tessen-infra/.github/workflows/update-chart-version.yaml@refs/heads/main # Allow only main branch
    - unity/my-repo/.github/workflows/my-workflow.yaml@refs/heads/main # Allow only main branch
```

**Note**: This is currently only supported for cloning/pushing to github.com/Unity-Technologies and github.cds/unity repositories, if you wish to use it on other Github.com organizations please contact us in #ask-pre.

### Inputs

| Argument Name       | Required | Default                                             | Description                                                                                                                                                 |
| ------------------- | -------- | --------------------------------------------------- | ----------------------------------------------------------------------------------------------------------------------------------------------------------- |
| `owner`             | false    | The organization where the Github Action is running | The owner of the repository where the workflow is contained.                                                                                                |
| `repo`              | True     | N/A                                                 | The repository where the workflow is contained.                                                                                                             |
| `github-server-url` | false    | The server URL where the Github Action is running   | The URL of the GitHub server, defaults to the current Github server so unless you are cloning Github.com from Github.cds for example you can leave it blank |

### Outputs

| Argument Name       | Description                                                                                   |
| ------------------- | --------------------------------------------------------------------------------------------- |
| `github-server-url` | The URL of the GitHub server.                                                                 |
| `encrypted-token`   | The encrypted token that can be used to clone/push to the remote repository.                  |

### Usage / example

The following example fetches a GitHub token for the remote repository `Unity-Technologies/my-remote-repo` and uses it to clone and push the repository.

```yaml
name: Clone and commit to remote repository

on:
  push:

jobs:
  fetch-remote-github-token:
    name: Fetch the remote GitHub token
    uses: Unity-Technologies/github-actions-workflows/.github/workflows/fetch-remote-github-token.yml@main
    with:
      owner: Unity-Technologies
      repo: my-remote-repo

  commit-to-remote-repo:
    needs: [fetch-remote-github-token]
    name: Clone and push to the remote repository
    runs-on: [unity-linux-runner]
    permissions: write-all # Necessary for fetch-vault-secrets
    steps:
      # Decrypt the remote GitHub token
      - uses: Unity-Technologies/github-actions-workflows/actions/decrypt-remote-github-token@main
        id: remote-repo-token
        with:
          github-server-url: ${{ needs.fetch-remote-github-token.outputs.github-server-url }}
          encrypted-token: ${{ needs.fetch-remote-github-token.outputs.encrypted-token }}

      - name: Clone the remote repository
        uses: actions/checkout@v4
        with:
          github-server-url: ${{ needs.fetch-remote-github-token.outputs.github-server-url }}
          repository: Unity-Technologies/my-remote-repo
          token: ${{ steps.remote-repo-token.outputs.token }}

      - name: Create a new branch and commit to test auth token works
        run: |
          # Configure git
          git config --global user.name "${GITHUB_ACTOR}"
          git config --global user.email "${GITHUB_ACTOR}@users.noreply.github.com"

          # Create a test-branch and commit/push to it
          git checkout -b test-branch
          echo "Test" > test.txt
          git add test.txt
          git commit -m "Test commit"
          git push origin test-branch

          # Delete the branch
          git push origin --delete test-branch
```

---

## decrypt-remote-github-token (composite action)

Composite action that decrypts the remote GitHub token obtained from the `fetch-remote-github-token` workflow. Used as a companion step after calling the reusable workflow.

Action [source code](https://github.com/Unity-Technologies/github-actions-workflows/blob/main/actions/decrypt-remote-github-token/action.yml).

### Inputs

| parameter          | description                                                                        | required | default      |
| ------------------ | ---------------------------------------------------------------------------------- | -------- | ------------ |
| github-server-url  | GitHub Server URL for the token you want to revoke, defaults to github.com         | `false`  | `github.com` |
| encrypted-token    | The encrypted GitHub token for the remote repository.                              | `true`   |              |
| revoke             | Revoke the token after it is being used. Generally you shouldn't change this.      | `false`  | `true`       |

### Outputs

| parameter | description                                           |
| --------- | ----------------------------------------------------- |
| token     | The decrypted GitHub token for the remote repository. |

### Usage / example

See the [fetch-remote-github-token](#fetch-remote-github-token-reusable-workflow) example above for the full end-to-end pattern. This action is used as a step inside a job that depends on the `fetch-remote-github-token` workflow:

```yaml
- uses: Unity-Technologies/github-actions-workflows/actions/decrypt-remote-github-token@main
  id: remote-repo-token
  with:
    github-server-url: ${{ needs.fetch-remote-github-token.outputs.github-server-url }}
    encrypted-token: ${{ needs.fetch-remote-github-token.outputs.encrypted-token }}
```

---

## fetch-vault-using-proxy (condensed)

Custom action to fetch secrets from Hashicorp Vault when using an HTTP proxy server. This is needed for the `unity-azure-linux-runners` self-hosted runner which must access Vault through a proxy (`http://10.100.18.4:3128`).

Action [source code](https://github.com/Unity-Technologies/github-actions-workflows/tree/main/actions/fetch-vault-using-proxy).

### Inputs

| Input                 | Description                                                                                                                                          | Default                                               | Required |
| --------------------- | ---------------------------------------------------------------------------------------------------------------------------------------------------- | ----------------------------------------------------- | -------- |
| `url`                 | The URL for the vault endpoint                                                                                                                       |                                                       | Yes      |
| `secrets`             | A semicolon-separated list of secrets to retrieve. These will automatically be converted to environmental variable keys. See README for more details |                                                       |          |
| `namespace`           | The Vault namespace from which to query secrets. Vault Enterprise only, unset by default                                                             |                                                       |          |
| `method`              | The method to use to authenticate with Vault.                                                                                                        | `token`                                               |          |
| `role`                | Vault role for specified auth method                                                                                                                 |                                                       |          |
| `path`                | Custom vault path, if the auth method was enabled at a different path                                                                                |                                                       |          |
| `token`               | The Vault Token to be used to authenticate with Vault                                                                                                |                                                       |          |
| `roleId`              | The Role Id for App Role authentication                                                                                                              |                                                       |          |
| `secretId`            | The Secret Id for App Role authentication                                                                                                            |                                                       |          |
| `githubToken`         | The Github Token to be used to authenticate with Vault                                                                                               |                                                       |          |
| `jwtPrivateKey`       | Base64 encoded Private key to sign JWT                                                                                                               |                                                       |          |
| `jwtKeyPassword`      | Password for key stored in jwtPrivateKey (if needed)                                                                                                 |                                                       |          |
| `jwtGithubAudience`   | Identifies the recipient ("aud" claim) that the JWT is intended for                                                                                  | `sigstore`                                            |          |
| `jwtTtl`              | Time in seconds, after which token expires                                                                                                           | 3600                                                  |          |
| `kubernetesTokenPath` | The path to the service-account secret with the jwt token for kubernetes based authentication                                                        | `/var/run/secrets/kubernetes.io/serviceaccount/token`  |          |
| `username`            | The username of the user to log in to Vault as. Available to both Userpass and LDAP auth methods                                                     |                                                       |          |
| `password`            | The password of the user to log in to Vault as. Available to both Userpass and LDAP auth methods                                                     |                                                       |          |
| `authPayload`         | The JSON payload to be sent to Vault when using a custom authentication method.                                                                      |                                                       |          |
| `extraHeaders`        | A string of newline separated extra headers to include on every request.                                                                             |                                                       |          |
| `exportEnv`           | Whether or not export secrets as environment variables.                                                                                              | `true`                                                |          |
| `exportToken`         | Whether or not export Vault token as environment variables (i.e VAULT_TOKEN).                                                                        | `false`                                               |          |
| `outputToken`         | Whether or not to set the `vault_token` output to contain the Vault token after authentication.                                                      | `false`                                               |          |
| `caCertificate`       | Base64 encoded CA certificate the server certificate was signed with.                                                                                |                                                       |          |
| `clientCertificate`   | Base64 encoded client certificate the action uses to authenticate with Vault when mTLS is enabled.                                                   |                                                       |          |
| `clientKey`           | Base64 encoded client key the action uses to authenticate with Vault when mTLS is enabled.                                                           |                                                       |          |
| `tlsSkipVerify`       | When set to true, disables verification of server certificates when testing the action.                                                              | `false`                                               |          |
| `httpProxy`           | The HTTP proxy value to use with the proxy agent.                                                                                                    | `http://10.100.18.4:3128`                             |          |
| `httpsProxy`          | The HTTPS proxy value to use with the proxy agent.                                                                                                   | `http://10.100.18.4:3128`                             |          |

> For more details, refer to the complete [hashicorp/vault-action guide](https://github.com/hashicorp/vault-action#vault-github-action).

### Usage / example

```yaml
name: Example of fetch-vault-using-proxy
on:
  push:
jobs:
  fetch-vault-secrets:
    name: Fetch Vault secrets
    runs-on: [unity-azure-linux-runners]
    permissions:
      id-token: write
      contents: read
    steps:
      - name: Checkout
        uses: actions/checkout@v3
      - name: Fetch vault using proxy
        uses: Unity-Technologies/github-actions-workflows/actions/fetch-vault-using-proxy@main
        with:
          url: https://vault.corp.unity3d.com
          role: github-actions-repos-ucb
          path: github-actions
          method: jwt
          secrets: |
            secret/ttas-cicd/github-actions/ucb/UNITY3D_JFROG_READ_USERNAME secret | UNITY3D_JFROG_READ_USERNAME ;
            secret/ttas-cicd/github-actions/ucb/UNITY3D_JFROG_READ_PASSWORD secret | UNITY3D_JFROG_READ_PASSWORD ;
```

---

## get-secrets-from-azurekeyvault (condensed)

Custom action for retrieving the values of secrets from an Azure Key Vault. Credentials used to login should have access to the AKV. The job requires permissions `id-token: write` and `contents: read` set either globally or at the job level.

Action [source code](https://github.com/Unity-Technologies/github-actions-workflows/tree/main/actions/get-secrets-from-azurekeyvault).

### Inputs

| Input             | Description                                                                                                     | Default | Required |
| ----------------- | --------------------------------------------------------------------------------------------------------------- | ------- | -------- |
| `client-id`       | Client Id                                                                                                       |         | Yes      |
| `tenant-id`       | Tenant Id                                                                                                       |         | Yes      |
| `subscription-id` | Subscription Id                                                                                                 |         | Yes      |
| `keyvault`        | Name of the Azure Key Vault                                                                                     |         | Yes      |
| `secrets`         | List of newline-separated environment variables' names and key vault secret names that should be masked out     |         |          |
| `configs`         | List of newline-separated environment variables' names and key vault secret names that should not be masked out |         |          |
| `install_cli`     | If set to true, will attempt to install the Azure CLI.                                                          | `true`  |          |

### Usage / example

```yaml
name: Example of fetch-azure-key-vault
on:
  push:
jobs:
  fetch-azure-key-vault-secrets:
    name: Fetch Azure Key Vault secrets
    runs-on: [unity-linux-runner]
    permissions:
      id-token: write
      contents: read
    steps:
      - name: Checkout
        uses: actions/checkout@v3

      - uses: Unity-Technologies/github-actions-workflows/actions/get-secrets-from-azurekeyvault@main
        with:
          client-id: ${{ secrets.AZURE_CLIENT_ID_MI }}
          tenant-id: ${{ secrets.AZURE_TENANT_ID }}
          subscription-id: ${{ secrets.AZURE_SUBSCRIPTION_ID }}
          keyvault: ${{ env.VAULT_NAME }}
          secrets: | # Secrets would be masked
            <your-env-variable-name>=<your-azure-secret-name>
            ...
            <your-env-variable-name>=<your-azure-secret-name>
          configs: | # Configs would not be masked
            <your-env-variable-name>=<your-azure-secret-name>
            ...
            <your-env-variable-name>=<your-azure-secret-name>
```
