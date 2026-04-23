# ArgoCD and GitOps — Reference Documentation

> **Provenance (not runtime dependencies):**
> These docs are bundled from [Unity-Technologies/github-actions-workflows](https://github.com/Unity-Technologies/github-actions-workflows).
> If upstream docs change, refresh this file to match; do not improvise new workflow YAML.
> Last synced: 2026-04-09
>
> **Note:** For full ArgoCD onboarding guidance (GitOps state repo setup, ApplicationSet
> configuration, cluster onboarding), use the `argocd-onboarding` skill instead. This file
> covers the action/workflow API reference only.

---

## Workflow: `render-with-common-chart`

Render manifests for ArgoCD using the common-chart and create a PR to your GitOps state repository.

**How it works:**

1. Picks up your values files and templates the common-chart with them. It picks up `values.yaml`, and depending on the workflow inputs `<env>.yaml` as well as your `<env>_<region>.yaml` files if you have set a region.
2. Each deployment is done by rendering your manifests from your code repo to your GitOps State Repository in the form of a Pull Request.
3. Opens a PR to your GitOps State Repository.
4. Merges it. Your workload is now deployed.
5. Checks whether the pods came up or not within a timeout.
6. If they didn't come up, reverts the PR and leaves the environment in the previous, clean, state.

Workflow [source code](https://github.com/Unity-Technologies/github-actions-workflows/blob/main/.github/workflows/render-with-common-chart.yaml)

### Pre-requisites

1. Setup GitOps State Repository, if your cluster doesn't have one already. Use repoDB to create one and use this template: <https://github.com/Unity-Technologies/pre-argocd-gitops-boilerplate>
2. Use PRE ApplicationSet template for your GitOps State Repository. It can automatically detect and create new ArgoCD Applications so you don't need anything else on ArgoCD side.
3. Make sure your service repository can make PRs to your GitOps State Repository. Follow the `fetch-remote-github-token` pre-requisites.
4. Pay extra attention on what value you choose for your `service`. Check from your GitOps State Repository that the name is not already in use.

### Inputs

| parameter | description | required | default |
| --- | --- | --- | --- |
| environment | Which environment files and target branches to use | `true` |  |
| image_tag | The image tag to use | `false` | ${GITHUB_SHA} |
| service | name of the service | `true` |  |
| gh_repository | GitOps state repository to make commits to (without Organization) e.g. my-repo | `true` |  |
| gh_org | Github Organization for the GitOps state repository to make commits to | `false` | `Unity-Technologies` |
| gh_server_url | GitHub Server URL for the GitOps repository (e.g., `https://github.com` or `https://github.cds.internal.unity3d.com`). **Do not include a trailing slash.** Use this if the repository is not on the current server (e.g., connecting from CDS to github.com). Leave empty to use the current server. | `false` | `` |
| gh_environment | The github environment to use | `false` |  |
| app_name | The name of the ArgoCD application to verify if synced | `true` |  |
| app_namespace | The argocd namespace the of the app. | `true` |  |
| wait_timeout | The timeout in seconds to wait for the app to sync. Defaults to 300 seconds (5 minutes). | `false` | 300 |
| argocd_url | The ArgoCD URL to use for the argocd CLI. | `false` | argocd.cd.internal.unity.com |
| add_image_tag | Set to false, if you only want to edit your values without changing the image | `false` | true |
| helm_extra_args | Extra arguments for helm template command | `false` |  |
| helm_directory | directory where helm values.yaml, stg.yaml and prd.yaml are | `false` | helm |
| auto_merge | Automatically merge the PR | `false` | true |
| output_dir | output dir in your GitOps State Repository | `false` | services |
| region | Region where app will be deployed (e.g., us-central1). Creates subdirectory under output_dir | `false` | |
| auto_rollback | Automatically revert the merged PR if the pods dont come up | `false` | true |
| chart_name | Chart name | `false` | unity-common-chart |
| chart_repo | Helm chart repository | `false` | <https://chartmuseum.internal.unity3d.com> |
| allow_delete | Allow deletion of services | `false` | `false` |
| release_name_override | Override the release name but use service name for the directory. Needed for preview environments. | `false` | |
| custom_labels | Custom labels for the PR. Format should be ",mylabel: myvalue,mysecondlabel: mysecondvalue" | `false` | |
| branch_suffix | add a suffix to the branch name for the generated PR. Used for PR Preview environments. | `false` | |
| auto_verify | Verify that the deployment went through and the pods came up | `false` | `true` |

### Outputs

| parameter | description |
| --- | --- |
| pr_number | PR that was created and merged |

### Usage Examples

#### Basic deployment

```yaml
  deploy_staging:
    needs: [ build, test ]
    uses: Unity-Technologies/github-actions-workflows/.github/workflows/render-with-common-chart.yaml@main
    with:
      environment: stg
      gh_repository: my-gitops-state-repo
      gh_org: Unity-Technologies
      service: my-awesome-service
      app_name: my-prefix-stg-my-awesome-service
      app_namespace: team-pre-cicd-demo
```

#### Deploying a Service for the First Time

If you use PRE ApplicationSet template, it discovers new services automatically. It takes some time for this to happen so the first deployment will take much longer on first time. It can take up to 3 minutes and you might see some warnings in the log when the workflow tries to poll until ArgoCD has created the Application. But you don't need to do anything special or any extra setup other than allowing service repository to access your GitOps repository.

#### Monorepo Deployments

Monorepo refers to having multiple services within your `helm` folder. To iterate over your services you can use a matrix:

```yaml
  deploy_<ENV>:
    uses: Unity-Technologies/github-actions-workflows/.github/workflows/render-with-common-chart.yaml@main
    name: Deploy <ENV>
    permissions: write-all
    needs: build
    strategy:
      matrix:
        service:
          - <SERVICE_1>
          - <SERVICE_2>
          - <SERVICE_3>
    concurrency: <ENV>-${{ github.ref }}-${{ matrix.service }}
    with:
      environment: <ENV>
      service: ${{ matrix.service }}
      gh_repository: <GITOPS_REPO_NAME>
      app_name: <TEAM_NAME>-<ENV>-${{ matrix.service }}
      app_namespace: <FULL_TEAM_NAME>
      helm_directory: <PATH_TO_HELM_FOLDER>/${{ matrix.service }}
```

#### Multiregion Deployments

The multiregion pattern requires a gitops repo created with more than one region per environment in mind. The argocd manifest created from the onboarding form will expect your manifests in your gitops repo to be under `/services/<region>/<app_name>`.

```yaml
  deploy_<ENV>:
    uses: Unity-Technologies/github-actions-workflows/.github/workflows/render-with-common-chart.yaml@main
    name: Deploy <ENV>
    permissions: write-all
    needs: build
    strategy:
      matrix:
        region:
          - <REGION_1>
          - <REGION_2>
          - <REGION_3>
    concurrency: <ENV>-${{ github.ref }}-my-awesome-service-${{ matrix.region }}
    with:
      environment: <ENV>
      service: my-awesome-service
      gh_repository: <GITOPS_REPO_NAME>
      app_name: <TEAM_NAME>-<ENV>-${{ matrix.region }}-my-awesome-service
      app_namespace: <FULL_TEAM_NAME>
      region: ${{ matrix.region }}
```

#### Combined Monorepo + Multiregion

```yaml
  deploy_<ENV>:
    uses: Unity-Technologies/github-actions-workflows/.github/workflows/render-with-common-chart.yaml@main
    name: Deploy <ENV>
    permissions: write-all
    needs: build
    strategy:
      matrix:
        service:
          - <SERVICE_1>
          - <SERVICE_2>
          - <SERVICE_3>
        region:
          - <REGION_1>
          - <REGION_2>
          - <REGION_3>
    concurrency: <ENV>-${{ github.ref }}-${{ matrix.service }}-${{ matrix.region }}
    with:
      environment: <ENV>
      service: ${{ matrix.service }}
      gh_repository: <GITOPS_REPO_NAME>
      app_name: <TEAM_NAME>-<ENV>-${{ matrix.region }}-${{ matrix.service }}
      app_namespace: <FULL_TEAM_NAME>
      helm_directory: <PATH_TO_HELM_FOLDER>/${{ matrix.service }}
      region: ${{ matrix.region }}
```

#### Directory structure for multiregion

When the `region` parameter is provided, the manifests will be organized in a regional directory structure:

- Without region: `/services/my-service/`
- With region: `/services/us-central1/my-service/`

Avoid using the region argument in a GitOps repo that has only one cluster per environment. GitOps repos have a set list of cluster states and all applications are expected to be deployed to all clusters in each environment. Create a new gitops repo where all apps will be deployed multi-regionally.

### Extending the Helm chart

You can add `raw_<env>_<something>.yaml` under your `helm_directory` where `<env>` is shorthand for the environment (stg/prd) or `all`. e.g. `raw_stg_my-custom-resource.yaml`. These files are copied into the `template/` into the chart. The content can be a k8s manifest with one or more resource or even a template that you provide values from the normal value files. The files are applied only for the env in `<env>` or all the envs if `<env>` is `all`.

When using the `region` flag, you can add region specific resources `raw_<env>_<region>_<something>.yaml`, where `<region>` is the name of the region (e.g. `raw_stg_us-central1_my-custom-resource.yaml`, `raw_stg_eu-west-1_my-custom-resource.yaml`). These files are treated the same way as the non-region specific files, but they are only applied to the specified region. If you want to target all environments for a given region, use `raw_all_<region>_<something>.yaml`.

### Deleting a Service

Go to your GitOps State Repository. Make a Pull Request that removes the whole directory of a service. Immediately after the PR is merged the service will be deleted. Make sure you disable all deploy workflows on your service repo. It will come back if it's deployed again.

### Changing Only Value Files Without Changing the Image

Set `add_image_tag: false` to only change the manifests without changing the image.

### Troubleshooting deployments

Go to the action that did the deployment, click "Summary" on the left-hand side, and download the "Artifacts". You should find logs and pod manifest there. Typical reasons are that the pod is crashing on startup or doesn't reach readiness. If it's crashing, you can find the `reason` and `exitCode` under `containerStatuses`.

The deployment tries to deploy until the deployment passes or until `wait_timeout` is reached. If the timeout is reached, it produces the artifacts, automatically rolls back the deployment (if `auto_rollback` is set), and fails the build. `ReadinessProbe`, `startUpProbe` and `livenessProbe` are used to gate the deployments.

---

## Workflow: `preview-rendered-manifests-with-common-chart`

Preview Helm Changes without deploying. See how changes in your values files will actually be reflected in the manifests. You can also use this action to validate your helm values. This action will fail if there are any errors in the manifests that your value files will produce.

By default, this workflow omits changes to the image.

Workflow [source code](https://github.com/Unity-Technologies/github-actions-workflows/blob/main/.github/workflows/preview-rendered-manifests-with-common-chart.yml)

### Pre-requisites

1. Setup GitOps State Repository, if your cluster doesn't have one already. Use repoDB to create one and use this template: <https://github.com/Unity-Technologies/pre-argocd-gitops-boilerplate>
2. Use PRE ApplicationSet template for your GitOps State Repository. It can automatically detect and create new ArgoCD Applications so you don't need anything else on ArgoCD side.
3. Make sure your service repository can make PRs to your GitOps State Repository. Follow the `fetch-remote-github-token` pre-requisites.

### Inputs

| **Parameter**             | **Description**                                                                                                          | **Required** | **Default**                    |
|---------------------------|--------------------------------------------------------------------------------------------------------------------------|--------------|--------------------------------|
| `environment`             | Which environment files and target branches to use                                                                       | Yes          |                                |
| `image_tag`               | The image tag to use                                                                                                     | No           | `${GITHUB_SHA}`                |
| `service`                 | Name of the service                                                                                                      | Yes          |                                |
| `gh_repository`           | GitOps state repository to make commits to (without Organization) e.g. my-repo                                           | Yes          |                                |
| `gh_org`                  | Github Organization for the GitOps state repository to make commits to                                                   | No           | `Unity-Technologies`           |
| `gh_server_url`           | GitHub Server URL for cross-server GitOps connections (no trailing slash). Leave empty to use current server             | No           | ``                             |
| `app_name`                | The name of the ArgoCD application to verify if synced                                                                   | Yes          |                                |
| `app_namespace`           | The ArgoCD namespace of the app                                                                                          | Yes          |                                |
| `argocd_url`              | The ArgoCD URL to use for the ArgoCD CLI                                                                                 | No           | `argocd.cd.internal.unity.com` |
| `add_image_tag`           | Set to true to display image changes in the diff                                                                         | No           | `false`                        |
| `helm_extra_args`         | Extra arguments for the Helm template command                                                                            | No           |                                |
| `helm_directory`          | Directory containing `values.yaml`, `stg.yaml`, and `prd.yaml`                                                           | No           | `helm`                         |
| `output_dir`              | Output directory in your GitOps State Repository                                                                         | No           | `services`                     |
| `post_in_pr`              | Post diff to PR. Set to `false` for non-PR events                                                                        | No           | `true`                         |
| `comment_collapse_nlines` | Number of lines above which comments become collapsible (0 to always collapse, -1 to never collapse)                     | No           | `20`                           |
| `region`                  | Region where app will be deployed (e.g., us-central1). Creates subdirectory under output_dir                             | No           |                                |
| `server_side_validate`    | Run ArgoCD server-side validation. Set to `false` for initial service onboarding when ArgoCD app does not exist yet      | No           | `true`                         |

### Usage Example

```yaml
name: Preview Helm Changes

on:
  pull_request:
    paths:
      - helm/*

jobs:
  preview-test:
    permissions: write-all
    uses: Unity-Technologies/github-actions-workflows/.github/workflows/preview-rendered-manifests-with-common-chart.yml@main
    with:
      environment: test
      gh_repository: my-gitops-repo
      gh_org: Unity-Technologies
      service: my-service
      app_name: my-service-test
      app_namespace: team-my-team
  preview-staging:
    permissions: write-all
    uses: Unity-Technologies/github-actions-workflows/.github/workflows/preview-rendered-manifests-with-common-chart.yml@main
    with:
      environment: stg
      gh_repository: my-gitops-repo
      gh_org: Unity-Technologies
      service: my-service
      app_name: my-service-stg
      app_namespace: team-my-team
  preview-production:
    permissions: write-all
    uses: Unity-Technologies/github-actions-workflows/.github/workflows/preview-rendered-manifests-with-common-chart.yml@main
    with:
      environment: prd
      gh_repository: my-gitops-repo
      gh_org: Unity-Technologies
      service: my-service
      app_name: my-service-prd
      app_namespace: team-my-team
```

### Recommendations

- Only run this on PRs and when there are changes to helm values.
- Run this against all your environments.

---

## Workflow: `deploy-prebuilt-manifests`

Deploy already-rendered manifests without running a renderer in this workflow.

Workflow [source code](https://github.com/Unity-Technologies/github-actions-workflows/blob/main/.github/workflows/deploy-prebuilt-manifests.yaml).

### How Does it Work

1. You produce manifests earlier in the same workflow run and upload them as an artifact named `manifests-<suffix>`.
2. This workflow validates that `artifact_name` starts with `manifests-`.
3. It extracts the suffix and passes it to `actions/deploy-rendered-manifests` as `artifact_timestamp`.
4. It opens and optionally auto-merges a PR to the GitOps repository for the target service/cluster-component.
5. It returns a singular `pr_number` from the deploy action.

### Prerequisites

1. Setup GitOps State Repository, if your cluster doesn't have one already. Use repoDB to create one and use this template: https://github.com/Unity-Technologies/pre-argocd-gitops-boilerplate
2. Use PRE ApplicationSet template for cluster-components for your GitOps State Repository.
3. Ensure your workflow uploads a manifests artifact before calling this workflow, and pass that artifact name as `artifact_name`.
4. If you run in GitHub CDS, use `Unity-Technologies/upload-artifact@v3` for artifact upload.

### Inputs

| parameter | description | required | default |
| --- | --- | --- | --- |
| `environment` | Which environment files and target branches to use | `Yes` | |
| `service` | Name of the service or cluster-component | `Yes` | |
| `artifact_name` | Name of the prebuilt manifests artifact. Must start with `manifests-` | `Yes` | |
| `app_namespace` | The argocd namespace of the app | `Yes` | |
| `app_name_prefix` | Prefix that matches what you have in your AppSet | `No` | `""` |
| `wait_timeout` | Timeout in seconds to wait for app sync | `No` | `300` |
| `argocd_url` | The ArgoCD URL to use for the argocd CLI | `No` | `argocd.cd.internal.unity.com` |
| `auto_merge` | Automatically merge the PR | `No` | `true` |
| `output_dir` | Output dir in your GitOps State Repository | `No` | `cluster-components` |
| `allow_delete` | Allow deletion of services | `No` | `false` |
| `auto_rollback` | Automatically revert merged PR if pods don't come up | `No` | `true` |
| `auto_verify` | Verify deployment completed and pods came up | `No` | `true` |
| `disallow_reruns` | Disallow reruns when run attempt > 1 | `No` | `false` |
| `gh_environment` | GitHub environment to use | `No` | |
| `region` | Region suffix for directory structure (e.g., `us-central1`) | `No` | |
| `gh_org` | GitHub Organization for the GitOps state repository | `No` | `Unity-Technologies` |
| `gh_server_url` | GitHub Server URL for the GitOps repository. Leave empty to use current server | `No` | `''` |
| `gh_repository` | GitOps state repository (without organization). If not provided, current repository name is used | `No` | |
| `cluster_component` | Whether this is deploying a cluster-component (vs a service) | `No` | `false` |
| `usf_app` | Use USF app naming convention | `No` | `false` |

### Outputs

| parameter | description |
| --- | --- |
| `pr_number` | PR that was created and/or merged |

### Usage Examples

#### Basic service deployment

```yaml
name: Deploy prebuilt manifests

on:
  push:
    branches:
      - main

jobs:
  build-manifests:
    runs-on: unity-linux-runner
    steps:
      - uses: actions/checkout@v6
      - name: Build manifests
        run: |
          mkdir -p out/
          cp my-rendered-manifests/*.yaml out/
      - name: Upload manifests artifact
        uses: actions/upload-artifact@v7
        with:
          name: manifests-my-service-change
          path: out/

  deploy:
    needs: [build-manifests]
    permissions: write-all
    uses: Unity-Technologies/github-actions-workflows/.github/workflows/deploy-prebuilt-manifests.yaml@main
    with:
      environment: test
      service: my-service
      artifact_name: manifests-my-service-change
      output_dir: services
      app_name_prefix: my-service-
      app_namespace: team-your-team
```

#### Cluster-component and region example

```yaml
  deploy-cluster-region:
    uses: Unity-Technologies/github-actions-workflows/.github/workflows/deploy-prebuilt-manifests.yaml@main
    with:
      environment: stg
      region: us-central1
      service: my-cluster-component
      artifact_name: manifests-my-cluster-change
      gh_repository: my-gitops-repo
      cluster_component: true
      output_dir: cluster-components
      app_name_prefix: my-cluster-component-
      app_namespace: team-your-team
      auto_merge: true
```

### Recommendations

- `cluster_component` defaults to `false` (service mode).
- Set `cluster_component: true` with `output_dir: cluster-components` for cluster-level manifests.
- Use `output_dir: services` for service manifests.
- Add `region` when your GitOps repository uses region subdirectories.

---

## Workflow: `preview-prebuilt-manifests`

Preview already-rendered manifests without running a renderer in this workflow. Compares downloaded manifests against the target environment branch in the GitOps repository. Returns `diff` and `has_changes`, and can post the diff in a PR comment and/or run server-side validation.

Workflow [source code](https://github.com/Unity-Technologies/github-actions-workflows/blob/main/.github/workflows/preview-prebuilt-manifests.yaml).

### Inputs

| Parameter | Description | Required | Default |
|-----------|-------------|----------|---------|
| `environment` | Which environment files and target branches to use | Yes | |
| `service` | Name of the service or cluster-component | Yes | |
| `artifact_name` | Name of the prebuilt manifests artifact. Must start with `manifests-` | Yes | |
| `app_namespace` | The argocd namespace of the app | Yes | |
| `post_in_pr` | Post diff to PR. Set to `false` for non-PR events | No | `true` |
| `app_name_prefix` | Prefix that matches what you have in your AppSet | No | `""` |
| `output_dir` | Output directory in your GitOps State Repository | No | `cluster-components` |
| `server_side_validate` | Do a server side validation for all changes | No | `true` |
| `comment_collapse_nlines` | Number of lines above which comments become collapsible (0 to always collapse, -1 to never collapse) | No | `20` |
| `region` | Region suffix for directory structure (e.g., `us-central1`) | No | |
| `argocd_url` | The ArgoCD URL to use for the argocd CLI | No | `argocd.cd.internal.unity.com` |
| `gh_org` | GitHub Organization for the GitOps state repository | No | `Unity-Technologies` |
| `gh_server_url` | GitHub Server URL for the GitOps repository. Leave empty to use current server | No | `''` |
| `gh_repository` | GitOps state repository (without organization). If not provided, current repository name is used | No | |
| `cluster_component` | Whether this is previewing a cluster-component (vs a service) | No | `false` |
| `usf_app` | Use USF app naming convention | No | `false` |

### Outputs

| Parameter | Description |
|-----------|-------------|
| `diff` | Diff formatted with markdown |
| `has_changes` | String `'true'` or `'false'` |

### Usage Example

```yaml
name: Preview prebuilt manifests

on:
  pull_request:

jobs:
  build-manifests:
    runs-on: unity-linux-runner
    steps:
      - uses: actions/checkout@v6
      - name: Build manifests
        run: |
          mkdir -p out/
          cp my-rendered-manifests/*.yaml out/
      - name: Upload manifests artifact
        uses: actions/upload-artifact@v7
        with:
          name: manifests-my-service-change
          path: out/

  preview:
    needs: [build-manifests]
    permissions: write-all
    uses: Unity-Technologies/github-actions-workflows/.github/workflows/preview-prebuilt-manifests.yaml@main
    with:
      environment: test
      service: my-service
      artifact_name: manifests-my-service-change
      output_dir: services
      app_name_prefix: my-service-
      app_namespace: team-your-team
```

---

## Workflow: `revert-rendered-manifest-deployments`

Rollback a Deployment that was done using `render-with-common-chart` or similar render workflows. Technically this just reverts a Pull Request. This is used internally by `render-with-common-chart`.

Can be used to rollback deployments to previous environments if one environment fails. For example, if you deploy test, staging and production and only production fails, you might want to automatically rollback staging and test.

Workflow [source code](https://github.com/Unity-Technologies/github-actions-workflows/blob/main/.github/workflows/revert-rendered-manifest-deployments.yaml)

### Inputs

| parameter | description | required | default |
| --- | --- | --- | --- |
| environment | Which environment files and target branches to use | `true` |  |
| pr_number | PR to revert | `true` |  |
| service | name of the service | `true` |  |
| gh_repository | GitOps state repository to make commits to (without Organization) e.g. my-repo | `true` |  |
| gh_org | Github Organization for the GitOps state repository to make commits to | `false` | `Unity-Technologies` |
| gh_server_url | GitHub Server URL for the GitOps repository (e.g., `https://github.com` or `https://github.cds.internal.unity3d.com`). **Do not include a trailing slash.** Use this if the repository is not on the current server (e.g., connecting from CDS to github.com). Leave empty to use the current server. | `false` | `` |

### Usage Example (Cascading Rollback)

```yaml
  # deploy_test, deploy_staging, deploy_production jobs omitted for brevity...
  # (each uses render-with-common-chart.yaml)

  # every deploy rolls itself back if it fails. This rolls back all previous environments
  # rollback test env if staging deploy failed
  rollback_test_after_stg_failure:
    needs: [ deploy_test, deploy_staging ]
    if: always() && needs.deploy_staging.result == 'failure'
    uses: Unity-Technologies/github-actions-workflows/.github/workflows/revert-rendered-manifest-deployments.yaml@main
    with:
      environment: test
      pr_number: ${{ needs.deploy_test.outputs.pr_number }}
      gh_repository: my-gitops-repo
      gh_org: Unity-Technologies
      service: my-service

  # if deploy fails on production these will rollback test and staging
  rollback_test_after_prd_failure:
    needs: [ deploy_test, deploy_production ]
    if: always() && needs.deploy_production.result == 'failure'
    uses: Unity-Technologies/github-actions-workflows/.github/workflows/revert-rendered-manifest-deployments.yaml@main
    with:
      environment: test
      pr_number: ${{ needs.deploy_test.outputs.pr_number }}
      gh_repository: my-gitops-repo
      gh_org: Unity-Technologies
      service: my-service

  rollback_stg_after_prd_failure:
    needs: [ deploy_staging, deploy_production ]
    if: always() && needs.deploy_production.result == 'failure'
    uses: Unity-Technologies/github-actions-workflows/.github/workflows/revert-rendered-manifest-deployments.yaml@main
    with:
      environment: stg
      pr_number: ${{ needs.deploy_staging.outputs.pr_number }}
      gh_repository: my-gitops-repo
      gh_org: Unity-Technologies
      service: my-service
```


## Workflow: `create-pr-preview-env`

Create PR Preview Environment. Spin up a new dedicated environment from your PRs with a shareable link. See the changes live in this environment before deploying them to staging and production. Meant to be used together with `destroy-pr-preview-env`.

**How it works:**

1. Opens a PR to your GitOps State Repository with a "preview" label.
2. The PR on the GitOps State Repository is mapped to the original PR and correct environment through the branch name.
3. There's an ApplicationSet on ArgoCD side that watches PRs with this "preview" label on your GitOps State Repository. When a PR is opened this AppSet will create a new Application.
4. When the PR on your code repo is closed or the label is removed it will close the PR on the GitOps State Repo (requires `destroy-pr-preview-env` workflow).

### Inputs

| parameter | description | required | default |
| --- | --- | --- | --- |
| check_names | A comma-separated string of check names to wait for. e.g. You might want to wait until your test pass before creating the preview env. (Optional) | `false` | |
| environment | Which environment files and target branches to use | `true` |  |
| service | Name of the service | `true` |  |
| gh_repository | GitOps state repository to make commits to (without Organization) e.g. my-repo | `true` |  |
| gh_org | Github Organization for the GitOps state repository to make commits to | `false` | `Unity-Technologies` |
| gh_environment | The github environment to use | `false` |  |
| app_name | The name of the ArgoCD application to verify if synced | `false` |  |
| app_namespace | The argocd namespace the of the app. | `false` |  |
| helm_extra_args | Extra arguments for helm template command. You can pass extra values specific to your preview env with this. | `false` | |
| helm_directory | Directory where helm values.yaml, stg.yaml and prd.yaml are | `false` | `helm` |
| url | Preview env url for the link in GH Deployment. | `false` |  |
| image_tag | Override the image name. Defaults to commit SHA | `false` | |
| wait_timeout | The timeout in seconds to wait for the app to sync. Defaults to 300 seconds (5 minutes). | `false` | `300` |

### Outputs

| parameter | description |
| --- | --- |
| pr_number | PR that was created and merged |

### Usage Example

```yaml
name: PR Preview Environment

on:
  pull_request:
    types: [opened, reopened, synchronize, labeled]

jobs:
  create_preview_env:
    if: |
      github.event.pull_request.state == 'open' &&
      contains(github.event.pull_request.labels.*.name, 'preview') &&
      ( !github.event.label || github.event.label.name == 'preview' )
    uses: Unity-Technologies/github-actions-workflows/.github/workflows/create-pr-preview-env.yaml@main
    with:
      check_names: "['Build Image','Test']"
      environment: test
      gh_repository: my-cluster-gitops
      gh_org: Unity-Technologies
      service: my-service
      app_name: my-argocd-namespace-test-my-service
      app_namespace: team-my-argocd-team
      helm_extra_args: -f helm/preview.yaml --set "httpRoute.hostnames[0]=pr-${{ github.event.number }}.myservice.something.unity.com"
      url: https://pr-${{ github.event.number }}.myservice.something.unity3d.com

```

### Recommendations

- Use a "preview" label as the mechanism to trigger this workflow.
- This feature is better suited for frontends.
- Your preview env likely differs from your normal service. Use `helm_extra_args` and create something like `helm/preview.yaml` to pass values that are only applied for each preview environment.
- Use `helm_extra_args` to pass additional values for your application (e.g., PR number to your endpoint).

---

## Workflow: `destroy-pr-preview-env`

Destroy PR Preview Environment. Closes a PR on the GitOps State Repository that was created by the `create-pr-preview-env` workflow.

Workflow [source code](https://github.com/Unity-Technologies/github-actions-workflows/blob/main/.github/workflows/destroy-pr-preview-env.yaml)

### Inputs

| parameter | description | required | default |
| --- | --- | --- | --- |
| environment | Which environment files and target branches to use | `true` |  |
| service | Name of the service | `true` |  |
| region | Region suffix (e.g., us-central1). Must match the value used when creating the preview. Omit if the preview was created without a region. | `false` |  |
| gh_repository | GitOps state repository to make commits to (without Organization) e.g. my-repo | `true` |  |
| gh_org | Github Organization for the GitOps state repository to make commits to | `false` | `Unity-Technologies` |
| gh_server_url | GitHub Server URL for the GitOps repository (e.g., `https://github.com` or `https://github.cds.internal.unity3d.com`). **Do not include a trailing slash.** Use this if the repository is not on the current server (e.g., connecting from CDS to github.com). Leave empty to use the current server. | `false` | `` |

### Usage Example

```yaml
name: Close PR Preview Environment

on:
  pull_request:
    types: [closed, unlabeled]

jobs:
  close_preview_env_pr:
    if: |
      ( github.event.action == 'closed' ) ||
      ( github.event.action == 'unlabeled' && github.event.label.name == 'preview' )
    uses: Unity-Technologies/github-actions-workflows/.github/workflows/destroy-pr-preview-env.yaml@main
    with:
      environment: stg
      gh_repository: my-cluster-gitops
      gh_org: Unity-Technologies
      service: my-service

```

---

## Workflow: `render-cluster-components`

Render cluster-components using helmfile and deploy them via PRs to the GitOps state repository.

Workflow [source code](https://github.com/Unity-Technologies/github-actions-workflows/blob/main/.github/workflows/render-cluster-components.yaml).

### How Does it Work

1. You use [helmfile](https://github.com/helmfile/helmfile) as interface for cluster components.
2. It uses `helmfile template` to render the manifests.
3. It adds the kronus helm repo credentials.
4. It sanitizes any secrets found. Don't use plaintext secrets -- use [external-secrets](https://externalsecrets.com) instead.
5. It makes a separate PR for each changed cluster-component, and each cluster-component is its own ArgoCD Application.
6. If it's a new component, the workflow will create a new ArgoCD Application (can take up to 3 minutes).
7. It makes sure the pods will come up.
8. If they don't, it does a rollback by reverting the PR that was created.

### Key Assumptions

1. **Branch names match environment names**: The `environment` input (e.g., `test`, `stg`, `prd`) is used both as the directory name for helmfile configs and the target branch in the GitOps state repository.
2. **Helmfile naming convention**: The workflow expects `helmfile.yaml` in the environment directory. When using regions, it expects `helmfile-{region}.yaml` (e.g., `helmfile-us-central1.yaml`).
3. **One component = one directory**: Each helmfile release produces a directory under `output_dir`. Each directory becomes a separate ArgoCD Application and gets its own PR.
4. **Repository structure**: Your helmfile configs should be organized as `{working_directory}/{environment}/helmfile.yaml` on the `main` branch.

### Directory Structure

The workflow constructs paths in the GitOps state repository as follows:

`{output_dir}/{region}/{component_name}/` (e.g., `cluster-components/us-central1/cert-manager/`)

**With sub_dir (for services):**
`{output_dir}/{sub_dir}/{release_name}/` (e.g., `services/my-service/my-helm-release/`)

`{output_dir}/{region}/{sub_dir}/{release_name}/` (e.g., `services/us-central1/my-service/my-helm-release/`)

### Inputs

| parameter          | description                                                               | required | default                        |
|--------------------|---------------------------------------------------------------------------|----------|--------------------------------|
| environment        | Environment name, used as the directory for helmfile configs and as the target branch in the GitOps state repo (e.g., `test`, `stg`, `prd`) | `Yes` | |
| app_namespace      | The ArgoCD namespace of the app                                           | `Yes`    |                                |
| app_name_prefix    | Prefix that matches what you have in your AppSet                          | `No`     | `""`                           |
| wait_timeout       | The timeout in seconds to wait for the app to sync. Defaults to 300 seconds (5 minutes) | `No` | `300` |
| argocd_url         | The ArgoCD URL to use for the argocd CLI                                  | `No`     | argocd.cd.internal.unity.com   |
| output_dir         | Output dir in your GitOps State Repository                                | `No`     | `cluster-components`           |
| region             | Region suffix for directory structure (e.g., `us-east-1`). Creates subdirectory under output_dir | `No` | |
| sub_dir            | (for services only) Groups all helmfile releases under a single subdirectory in the GitOps state repo (e.g., `my-service`). When set, the sub_dir is treated as a single deployable unit | `No` | |
| cluster_component  | Set to `false` when deploying services. Controls deletion behavior. `true` (default): aggressively removes entire component directory before re-rendering. `false`: preserves lockfile (`owner.txt`) | `No` | `true` |
| usf_app            | Only needed if your ApplicationSet uses the USF naming convention. Controls ArgoCD app name format. `false` (default): `{prefix}{env}-{component}`. `true`: `{prefix}{component}-{env}` | `No` | `false` |
| auto_rollback      | Automatically revert the merged PR if the pods don't come up              | `No`     | `true`                         |
| auto_merge         | Automatically merge the PR                                                | `No`     | `true`                         |
| auto_verify        | Verify that the deployment went through and the pods came up              | `No`     | `true`                         |
| working_directory  | Base local directory where helmfile configs live. Expected structure: `{working_directory}/{environment}/helmfile{-region}.yaml` | `No` | `.` |
| allow_delete       | Allow deletion of services                                                | `No`     | `false`                        |
| sanitize_secrets   | Sanitize secrets so they don't end up in the GitOps State Repo. You should only disable it under special circumstances | `No` | `true` |
| include_crds       | Include CRDs in rendered manifests (adds `--include-crds` to `helmfile template`) | `No` | `false` |
| disallow_reruns    | Disallow reruns. When `true`, rerun attempts will fail.                   | `No`     | `false`                        |
| gh_environment     | The github environment to use                                             | `No`     |                                |
| gh_org             | Github Organization for the GitOps state repository to make commits to    | `No`     | `Unity-Technologies`           |
| gh_server_url      | GitHub Server URL for the GitOps repository (e.g., `https://github.com`). Use it if the repository is not on the current server like connecting from CDS. Leave empty to use the current server | `No` | |
| gh_repository      | GitOps state repository to make commits to (without Organization). If not provided, uses current repository name | `No` | |
| extra_env_vars     | Extra environment variables for helmfile as a JSON object (e.g., `'{"HELMFILE_IMAGE_TAG": "v1.2.3"}'`). Variables are accessible via `requiredEnv`/`env` in helmfile templates. Must use `HELMFILE_*` prefix | `No` | |
| helm_major_version | Helm major version (3 or 4) | `No` | `3` |

### Usage Examples

#### Same Repository (Default)

```yaml
name: Apply

on:
  push:
    branches:
      - main

jobs:
  apply-test:
    uses: Unity-Technologies/github-actions-workflows/.github/workflows/render-cluster-components.yaml@main
    with:
      environment: test
      app_name_prefix: my-cluster-component-
      app_namespace: team-your-team
  apply-staging:
    uses: Unity-Technologies/github-actions-workflows/.github/workflows/render-cluster-components.yaml@main
    with:
      environment: stg
      app_name_prefix: my-cluster-component-
      app_namespace: team-your-team
  apply-production:
    uses: Unity-Technologies/github-actions-workflows/.github/workflows/render-cluster-components.yaml@main
    with:
      environment: prd
      app_name_prefix: my-cluster-component-
      app_namespace: team-your-team
```

#### Use helmfile as Renderer for Services and Dependencies

This allows you to manage 1st or 3rd party helm charts in your service repository. Helmfile supports kustomize as well. This example would render all releases from the helmfile to `services/my-service/my-helm-release`, `services/my-service/my-service-dependency`.

```yaml
name: Apply

on:
  push:
    branches:
      - main

jobs:
  apply-test:
    uses: Unity-Technologies/github-actions-workflows/.github/workflows/render-cluster-components.yaml@main
    with:
      environment: test
      app_name_prefix: my-service-
      app_namespace: team-your-team
      gh_repository: my-gitops-state-repo
      output_dir: 'services'
      sub_dir: 'my-service'
      cluster_component: false
  apply-staging:
    uses: Unity-Technologies/github-actions-workflows/.github/workflows/render-cluster-components.yaml@main
    with:
      environment: stg
      app_name_prefix: my-service-
      app_namespace: team-your-team
      gh_repository: my-gitops-state-repo
      output_dir: 'services'
      sub_dir: 'my-service'
      cluster_component: false
  apply-production:
    uses: Unity-Technologies/github-actions-workflows/.github/workflows/render-cluster-components.yaml@main
    with:
      environment: prd
      app_name_prefix: my-service-
      app_namespace: team-your-team
      gh_repository: my-gitops-state-repo
      output_dir: 'services'
      sub_dir: 'my-service'
      cluster_component: false
```

#### Multi-Region Deployment

For clusters with multiple regions, call the workflow once per region. Each region gets its own subdirectory and its own set of PRs. For each region, the workflow expects a region-specific helmfile (e.g., `helmfile-us-central1.yaml`, `helmfile-us-east1.yaml`):

```yaml
jobs:
  apply-test-us-central1:
    uses: Unity-Technologies/github-actions-workflows/.github/workflows/render-cluster-components.yaml@main
    with:
      environment: test
      region: us-central1
      app_name_prefix: my-cluster-component-
      app_namespace: team-your-team

  apply-test-us-east1:
    uses: Unity-Technologies/github-actions-workflows/.github/workflows/render-cluster-components.yaml@main
    with:
      environment: test
      region: us-east1
      app_name_prefix: my-cluster-component-
      app_namespace: team-your-team
```

#### Passing Environment Variables to Helmfile (`extra_env_vars`)

```yaml
extra_env_vars: '{"HELMFILE_IMAGE_TAG": "${{ github.sha }}"}'
```

In your helmfile, reference these with `requiredEnv "HELMFILE_IMAGE_TAG"` or `env "HELMFILE_IMAGE_TAG"`.

### Understanding sub_dir, output_dir, and cluster_component

- **`output_dir`** controls the top-level directory in the GitOps state repo. Defaults to `cluster-components`. For services, use `services`.
- **`sub_dir`** groups all helmfile releases under a single directory. Without it, each helmfile release gets its own directory directly under `output_dir`. When set, the entire `sub_dir` is treated as a single deployable unit.
- **`cluster_component`** controls deletion behavior. When `true` (default), the entire component directory is deleted and recreated on every render (aggressive cleanup). When `false`, the lockfile (`owner.txt`) is preserved, which prevents other repositories from accidentally overwriting your service. **Always set to `false` when deploying services.**

### Understanding usf_app

- **Default (`false`)**: `{prefix}{environment}{-region}-{component}` -- e.g., `my-prefix-test-us-central1-cert-manager`
- **USF (`true`)**: `{prefix}{component}-{environment}{-region}` -- e.g., `my-prefix-cert-manager-test-us-central1`

Set this to `true` **only** if your ArgoCD ApplicationSet uses the USF naming convention.

---

## Workflow: `preview-cluster-component-changes`

Preview cluster-component changes. Shows the diff of what would change in your manifests if the PR is merged.

Workflow [source code](https://github.com/Unity-Technologies/github-actions-workflows/blob/main/.github/workflows/preview-cluster-component-changes.yaml).

### Inputs

| Parameter              | Description                                                                                                                    | Required  | Default              |
|------------------------|--------------------------------------------------------------------------------------------------------------------------------|-----------|----------------------|
| `environment`          | Which environment files and target branches to use                                                                             | Yes       |                      |
| `app_namespace`        | The argocd namespace the of the cluster-components                                                                             | Yes       |                      |
| `app_name_prefix`      | Prefix that matches what you have in your AppSet.                                                                              | Yes       |                      |
| `post_in_pr`           | Post diff to PR. Set to `false` for non-PR events                                                                              | No        | `true`               |
| `working_directory`    | Working directory                                                                                                              | No        | `.`                  |
| `output_dir`           | Output Directory                                                                                                               | No        | `cluster-components` |
| `region`               | Region where component will be deployed (e.g., us-central1). Creates subdirectory under output_dir                               | No        |                      |
| `server_side_validate` | Do a server side validation for all changes. Generally you shouldn't turn this off. This is needed internally for testability. | No        | `true`               |
| `allow_delete`         | Allow deletion of services                                                                                                     | No        | `false`              |
| `include_crds`         | Include CustomResourceDefinitions in the rendered manifests (adds `--include-crds` to `helmfile template`). Keep `false` unless you need CRDs in previews. | No | `false` |
| `extra_env_vars`       | Extra environment variables for helmfile as a JSON object. Variables are accessible via `requiredEnv`/`env` in helmfile templates. All keys must start with `HELMFILE_*` prefix | No | |
| `comment_collapse_nlines` | Number of lines above which comments become collapsible (0 to always collapse, -1 to never collapse)                           | No        | `20`                 |
| `gh_org`               | Github Organization for the GitOps state repository to make commits to                                                        | No        | `Unity-Technologies` |
| `gh_server_url`        | GitHub Server URL for the GitOps repository (e.g., `https://github.com` or `https://github.cds.internal.unity3d.com`). **Do not include a trailing slash.** Use this if the repository is not on the current server (e.g., connecting from CDS to github.com). Leave empty to use the current server. | No | `` |
| `gh_repository`        | GitOps state repository name (without Organization). If not provided, uses current repository name                            | No        |                      |
| `helm_major_version`   | Helm major version (3 or 4) | No | `3` |

### Usage Examples

#### Same Repository (Default)

```yaml
name: Plan

on:
  pull_request:

jobs:
  plan-test:
    uses: Unity-Technologies/github-actions-workflows/.github/workflows/preview-cluster-component-changes.yaml@main
    with:
      environment: test
      app_name_prefix: my-cluster-component-
      app_namespace: team-your-team
  plan-staging:
    uses: Unity-Technologies/github-actions-workflows/.github/workflows/preview-cluster-component-changes.yaml@main
    with:
      environment: stg
      app_name_prefix: my-cluster-component-
      app_namespace: team-your-team
  plan-production:
    uses: Unity-Technologies/github-actions-workflows/.github/workflows/preview-cluster-component-changes.yaml@main
    with:
      environment: prd
      app_name_prefix: my-cluster-component-
      app_namespace: team-your-team
```

#### Use helmfile as Renderer for Services and Dependencies

```yaml
name: Plan

on:
  pull_request:

jobs:
  plan-test:
    uses: Unity-Technologies/github-actions-workflows/.github/workflows/preview-cluster-component-changes.yaml@main
    with:
      environment: test
      app_name_prefix: my-service-
      app_namespace: team-your-team
      gh_repository: my-gitops-state-repo
      output_dir: 'services'
      sub_dir: 'my-service'
      cluster_component: false
  plan-staging:
    uses: Unity-Technologies/github-actions-workflows/.github/workflows/preview-cluster-component-changes.yaml@main
    with:
      environment: stg
      app_name_prefix: my-service-
      app_namespace: team-your-team
      gh_repository: my-gitops-state-repo
      output_dir: 'services'
      sub_dir: 'my-service'
      cluster_component: false
```

### Recommendations

- Run this on PRs to see what would happen to your manifests if this PR is merged.
- This should live in the `main` branch of your GitOps repository.

---

## Composite Action: `render-with-common-chart`

Renders manifests for ArgoCD using the common-chart. Used internally by the `render-with-common-chart` reusable workflow. Can be used directly in composite workflows.

Action [source code](https://github.com/Unity-Technologies/github-actions-workflows/blob/main/actions/render-with-common-chart/action.yml)

### Inputs

| parameter | description | required | default |
| --- | --- | --- | --- |
| environment | Which environment files and target branches to use | `true` | |
| image_tag | The image tag to use | `false` | ${GITHUB_SHA} |
| service | Name of the service | `true` | |
| release_name_override | Override the release name but use service name for the directory. Needed for preview environments. | `false` | |
| add_image_tag | Set to false, if you only want to edit your values without changing the image | `false` | true |
| helm_extra_args | Extra arguments for helm template command | `false` | |
| helm_directory | directory where helm values.yaml, stg.yaml and prd.yaml are | `false` | helm |
| output_dir | Output dir in your GitOps State Repository | `false` | services |
| region | Region suffix for directory structure (e.g., us-central1). Creates subdirectory under output_dir | `false` | |
| chart_name | Chart name | `false` | unity-common-chart |
| allow_delete | Allow deletion of services | `false` | false |
| chart_repo | Helm chart repository | `false` | https://chartmuseum.internal.unity3d.com |

### Outputs

| parameter | description |
| --- | --- |
| timestamp | timestamp that's used in the uploaded artifact |

---

## Composite Action: `render-with-kustomize`

Renders manifests using Kustomize. Extracts the image name from `kustomization.yaml`, sets the image tag, and uploads the rendered manifests as an artifact.

Action [source code](https://github.com/Unity-Technologies/github-actions-workflows/blob/main/actions/render-with-kustomize/action.yml)

### Inputs

| parameter | description | required | default |
| --- | --- | --- | --- |
| kustomize_dir | Enter the kustomize directory path where manifests are present | `false` | kustomize |
| image_tag | The image tag to use | `false` | ${GITHUB_SHA} |
| add_image_tag | Set to false, if you only want to edit your values without changing the image | `false` | true |
| output_dir | Output directory for rendered manifests | `false` | services |
| region | Region suffix for directory structure (e.g., us-central1). Creates subdirectory under output_dir | `false` | |

### Outputs

| parameter | description |
| --- | --- |
| timestamp | timestamp that's used in the uploaded artifact |

---

## Composite Action: `render-with-helmfile`

Renders manifests using helmfile. Used internally by the `render-cluster-components` reusable workflow.

Action [source code](https://github.com/Unity-Technologies/github-actions-workflows/blob/main/actions/render-with-helmfile/action.yml)

### Inputs

| parameter | description | required | default |
| --- | --- | --- | --- |
| environment | Which environment files and target branches to use | `true` | |
| working_directory | Working directory | `false` | . |
| allow_delete | Allow deletion of services | `false` | false |
| sanitize_secrets | Sanitize secrets so they don't end up in the GitOps State Repo. You should only disable it under special circumstances. | `false` | true |
| include_crds | Include CRDs in rendered manifests (adds --include-crds to helmfile template) | `false` | false |
| region | Region suffix for directory structure (e.g., us-central1). Creates subdirectory under output_dir | `false` | |
| output_dir | Output dir for rendered variables | `false` | cluster-components |
| sub_dir | Only needed when this is used for rendering services | `false` | |
| gh_org | Github Organization for the GitOps state repository | `false` | Unity-Technologies |
| gh_repository | GitOps state repository name (without Organization) | `false` | |
| gh_server_url | GitHub Server URL for the GitOps repository. Leave empty to use the current server. | `false` | |
| same_repository | Whether the GitOps state repository is the same as the current repository | `false` | true |
| gh_app_token | GitHub App token for cross-repository access | `false` | |
| extra_env_vars | Extra environment variables provided to helmfile commands as JSON object. All keys must start with HELMFILE_ prefix (e.g., {"HELMFILE_APP1_IMAGE_TAG": "bv01g1934"}) | `false` | |
| helm_major_version | Helm major version (3 or 4) | `false` | 3 |

### Outputs

| parameter | description |
| --- | --- |
| directories | list of cluster-components |
| timestamp | timestamp that's used in the uploaded artifact |

---

## Composite Action: `render-with-tessen`

Renders manifests using Tessen deployment export for ArgoCD. Uses the Tessen CLI to generate Kubernetes manifests from docker-compose configurations.

Action [source code](https://github.com/Unity-Technologies/github-actions-workflows/blob/main/actions/render-with-tessen/action.yml)

### Inputs

| parameter | description | required | default |
| --- | --- | --- | --- |
| environment | Which environment to deploy to (test, stg, prd) | `true` | |
| image_tag | The image tag to use | `false` | ${GITHUB_SHA} |
| service | Name of the service | `true` | |
| output_dir | Output dir in your GitOps State Repository | `false` | services |
| region | Region suffix for directory structure (e.g., us-central1). Creates subdirectory under output_dir | `false` | |
| allow_delete | Allow deletion of services | `false` | false |
| tessen_extra_args | Extra arguments for tessen deployment export command | `false` | |
| docker_compose_path | Path to docker-compose.yml file | `false` | docker-compose.yml |
| tessen_config_path | Path to .tessen.yml config file | `false` | .tessen.yml |
| image_overrides | Image overrides in format service1=image:tag,service2=image:tag | `false` | |
| environment_variables | Environment variables to pass to Tessen in format VAR1=value1,VAR2=value2 | `false` | |
| gh_server_url | GitHub Server URL for the GitOps repository. Leave empty to use the current server. | `false` | |

### Outputs

| parameter | description |
| --- | --- |
| timestamp | timestamp that's used in the uploaded artifact |

---

## Composite Action: `preview-rendered-manifests`

Preview the rendered manifests for a service or cluster-component. Compares manifests against the target environment branch in the GitOps repository, produces a diff, and optionally posts it as a PR comment and/or runs ArgoCD server-side validation.

Action [source code](https://github.com/Unity-Technologies/github-actions-workflows/blob/main/actions/preview-rendered-manifests/action.yml)

### Inputs

| parameter | description | required | default |
| --- | --- | --- | --- |
| environment | Which environment files and target branches to use | `true` | |
| service | name of the service | `true` | |
| cluster_component | Whether this is previewing a cluster-component (vs a service) | `false` | false |
| gh_repository | GitOps state repository to make commits to (without Organization) e.g. my-repo | `true` | |
| gh_org | Github Organization for the GitOps state repository to make commits to | `false` | Unity-Technologies |
| gh_server_url | GitHub Server URL for the GitOps repository. Leave empty to use the current server. | `false` | |
| gh_app_token | token from GH App | `false` | |
| post_in_pr | Post Diff to PR. Set to `true` if you run this on non-pr event. | `false` | true |
| app_name | The name of the ArgoCD application to verify if synced | `true` | |
| app_namespace | The argocd namespace the of the app. | `true` | |
| argocd_url | The ArgoCD URL to use for the argocd CLI. | `false` | argocd.cd.internal.unity.com |
| output_dir | output dir in your GitOps State Repository | `false` | services |
| region | Region suffix for directory structure (e.g., us-central1). Should match the region used in the render action | `false` | |
| server_side_validate | Do a server side validation for all changes. | `false` | true |
| artifact_timestamp | Timestamp of the artifact from the renderer | `true` | |
| comment_collapse_nlines | Number of lines above which comments become collapsible (0 to always collapse, -1 to never collapse) | `false` | 20 |
| comment_id | ID of comment to update. Defaults to a combination of service, environment and region. | `false` | |
| encrypted_token | encrypted token from fetch-remote-github-token workflow | `false` | |

### Outputs

| parameter | description |
| --- | --- |
| diff | Diff formatted with markdown |
| has_changes | String 'true' or 'false' |

---

## Composite Action: `deploy-rendered-manifests`

Deploy rendered manifests to a GitOps state repository. Opens a PR, optionally auto-merges it, waits for ArgoCD sync, and optionally rolls back on failure.

Action [source code](https://github.com/Unity-Technologies/github-actions-workflows/blob/main/actions/deploy-rendered-manifests/action.yml)

### Inputs

| parameter | description | required | default |
| --- | --- | --- | --- |
| environment | Which environment files and target branches to use | `true` | |
| service | Name of the service | `true` | |
| gh_repository | GitOps state repository to make commits to (without Organization) e.g. my-repo | `true` | |
| gh_org | Github Organization for the GitOps state repository to make commits to | `false` | Unity-Technologies |
| gh_server_url | GitHub Server URL for the GitOps repository. Leave empty to use the current server. | `false` | |
| region | Region suffix for directory structure (e.g., us-central1). Creates subdirectory under output_dir | `false` | |
| app_name | The name of the ArgoCD application to verify if synced | `true` | |
| app_namespace | The argocd namespace the of the app. | `true` | |
| wait_timeout | The timeout in seconds to wait for the app to sync. Defaults to 300 seconds (5 minutes). | `false` | 300 |
| argocd_url | The ArgoCD URL to use for the argocd CLI. | `false` | argocd.cd.internal.unity.com |
| auto_merge | Automatically merge the PR | `false` | true |
| output_dir | Output dir in your GitOps State Repository | `false` | services |
| auto_rollback | Automatically revert the merged PR if the pods dont come up | `false` | true |
| auto_verify | Verify that the deployment went through and the pods came up | `false` | true |
| gh_app_token | token from GH App | `false` | |
| same_repository | Whether the rendering is done in the same repository as the GitOps state repository | `false` | false |
| cluster_component | Whether this is deploying a cluster-component (vs a service). Cluster-components use different artifact paths and deletion logic. | `false` | false |
| allow_delete | Allow deletion of services | `false` | false |
| artifact_timestamp | Timestamp of the artifact from the renderer | `true` | |
| custom_labels | Custom labels for the PR. Format should be ",mylabel: myvalue,mysecondlabel: mysecondvalue" | `false` | |
| branch_suffix | add a suffix to the branch name for the generated PR. Used for PR Preview environments. | `false` | |

### Outputs

| parameter | description |
| --- | --- |
| pr_number | PR that was created and/or merged |

---

## Quick Reference: Choosing the Right Workflow

| Goal | Workflow | Renderer |
|------|----------|----------|
| Deploy a service using common-chart | `render-with-common-chart` | common-chart (Helm) |
| Preview service changes before deploying | `preview-rendered-manifests-with-common-chart` | common-chart (Helm) |
| Deploy cluster-components using helmfile | `render-cluster-components` | helmfile |
| Preview cluster-component changes | `preview-cluster-component-changes` | helmfile |
| Deploy pre-rendered manifests (any renderer) | `deploy-prebuilt-manifests` | N/A (bring your own) |
| Preview pre-rendered manifests (any renderer) | `preview-prebuilt-manifests` | N/A (bring your own) |
| Show ArgoCD diff in PR comments | `argocd-app-diff` | N/A |
| Rollback a deployment | `revert-rendered-manifest-deployments` | N/A |
| Create PR preview environment | `create-pr-preview-env` | common-chart (Helm) |
| Destroy PR preview environment | `destroy-pr-preview-env` | N/A |

For **WIF/Vault authentication** details (Workload Identity Federation, service accounts, Vault secrets), see `guides-wif-vault-practices.md`.
