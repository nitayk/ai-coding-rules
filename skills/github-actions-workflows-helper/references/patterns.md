# Common Patterns and Conventions

## Referencing shared actions and workflows

**Composite actions:**
```yaml
uses: Unity-Technologies/github-actions-workflows/actions/<action-name>@main
```

**Reusable workflows:**
```yaml
uses: Unity-Technologies/github-actions-workflows/.github/workflows/<workflow-name>.yml@main
# or .yaml — extensions vary per workflow. Use the exact filename from the
# bundled reference files or catalog.md (e.g. render-with-common-chart.yaml,
# send-slack-message.yml).
```

Always use `@main` — this is the convention so teams receive non-breaking updates automatically. Never pin to a commit SHA for these shared actions.

For testing on a branch during development:
```yaml
uses: Unity-Technologies/github-actions-workflows/actions/<action-name>@my-feature-branch
```

## Runner labels

| Label | Use case |
|-------|----------|
| `unity-linux-runner` | Default for all jobs. Linux x86_64 |
| `unity-linux-runner-arm` | Native ARM64 builds (5-10x faster than QEMU emulation) |
| `unity-linux-runner-xlarge` | Large resource-intensive jobs |

Always use self-hosted runners — they have better performance and use Unity's GCP discounts.

## Permissions

Most actions require `permissions: write-all` or at minimum:
```yaml
permissions:
  id-token: write   # Required for WIF and Vault JWT auth
  contents: read     # Required for checkout
```

If the workflow also writes to PRs (comments, status checks):
```yaml
permissions:
  id-token: write
  contents: read
  pull-requests: write
```

## Authentication patterns

### GCP — Workload Identity Federation (WIF)

The recommended auth method for GCP. No service account keys needed.

**Pushing images to unity-source:**
```yaml
service_account: ci-push@unity-source.iam.gserviceaccount.com
```

**Pushing images to unity-ads-common-prd:**
```yaml
service_account: ci-push@unity-ads-common-prd.iam.gserviceaccount.com
```

**Deploying to ads clusters:**
```yaml
service_account: ci-deploy@unity-ads-common-prd.iam.gserviceaccount.com
```

For custom service accounts, set up WIF using the [terraform-google-pre-workload-identity-federation](https://github.com/Unity-Technologies/terraform-google-pre-workload-identity-federation) module and PRE's centralized identity pools.

### Azure — Workload Identity Federation

```yaml
cloud: Azure
client-id: <your-client-id>
subscription-id: <your-subscription-id>
tenant-id: <your-tenant-id>  # if needed
registry: <acr-registry-name>  # for container builds
```

### AWS — OIDC

```yaml
cloud: AWS
role-to-assume: arn:aws:iam::<account-id>:role/<role-name>
aws-region: us-east-1
```

### Vault secrets

For third-party API keys or credentials (not cloud auth — use WIF for that):

```yaml
- id: global-config
  uses: Unity-Technologies/github-actions-workflows/actions/global-config@main

- name: Fetch Vault secrets
  uses: hashicorp/vault-action@v2.5.0
  with:
    url: https://vault.corp.unity3d.com
    role: <your-vault-role>
    path: ${{ steps.global-config.outputs.vault-auth-path }}
    method: jwt
    secrets: |
      secret/<path>/SECRET_NAME secret | SECRET_ENV_VAR ;
```

The `global-config` action auto-detects `github.com` vs `github.cds` and sets the correct Vault auth path.

## Choosing between action and workflow

If both an action and a reusable workflow exist for the same task, **recommend the workflow first**:
- Workflows are more opinionated, easier to set up, and often need fewer inputs
- Actions give more flexibility and can be composed into custom workflows
- Workflows can call composite actions internally

## Conditional deployment pattern

Push on every commit, deploy only on merge to main:
```yaml
push: ${{ github.ref == 'refs/heads/main' }}
```

## Checkout

Always use `actions/checkout@v4`. Don't use older versions.

Actions in this repo do NOT perform checkout — the caller must do it for flexibility.

## Common gotchas

1. **OIDC 127-byte limit:** If your repo has long branch names, run the `customize_oidc` workflow once to shorten the OIDC subject claim.

2. **PR event SHA:** `$GITHUB_SHA` on PR events is the merge commit, not the head commit. Use `${{ github.event.pull_request.head.sha }}` for the actual commit. `$GITHUB_HEAD_REF` gives the branch name.

3. **ENV var cross-reference:** You cannot reference `${{ env.X }}` when defining another env variable at the same level. Use job outputs instead.

4. **PR conflicts:** If there's a merge conflict, no actions run and no failure is reported. The user gets no feedback until the conflict is resolved.

5. **Concurrency + environment reviews:** If a workflow uses concurrency and deploys to an environment requiring review, failing to approve a previous run will block all subsequent runs with no clear error message.

6. **Reusable workflow limits:** Reusable workflows can call other reusable workflows up to 4 levels deep. You cannot pass ENV variables to reusable workflows — use inputs/outputs instead.

## Standard workflow skeleton

```yaml
name: <Workflow Name>
on:
  push:
    branches: [main]
  pull_request:
    branches: [main]

jobs:
  build:
    runs-on: [unity-linux-runner]
    permissions:
      id-token: write
      contents: read
    steps:
      - name: Checkout
        uses: actions/checkout@v4

      - name: <Step Name>
        uses: Unity-Technologies/github-actions-workflows/actions/<action>@main
        with:
          # inputs here
```
