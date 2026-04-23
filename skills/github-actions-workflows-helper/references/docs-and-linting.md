# Documentation and Linting — Reference Documentation

> **Provenance (not runtime dependencies):**
> These docs are bundled from [Unity-Technologies/github-actions-workflows](https://github.com/Unity-Technologies/github-actions-workflows).
> If upstream docs change, refresh this file to match; do not improvise new workflow YAML.
> Last synced: 2026-04-09
>
> **Note:** For full TechDocs onboarding (mkdocs.yml, catalog-info.yaml, local validation),
> use the `techdocs-onboarding` skill instead. This file covers the action/workflow API reference.

---

## 1. TechDocs Build and Publish Action (composite action)

Composite action that builds and publishes TechDocs documentation. Runs in the same job context as your workflow, making it suitable for cases that require templating, preprocessing, or other custom build steps before generating documentation.

**Use this composite action when:**
- You need to run preprocessing, templating, or custom build steps
- You want to generate content before building docs
- You want maximum flexibility in your build process

**Use the reusable workflow (section 2) when:**
- You have simple, static documentation
- You want clean workflow separation
- You prefer the isolation of separate jobs

### Inputs

| Input               | Description                                            | Required | Default        |
|---------------------|--------------------------------------------------------|----------|----------------|
| `entity_name`       | The name of the entity                                 | Yes      |                |
| `entity_namespace`  | The namespace of the entity                            | No       | `default`      |
| `entity_kind`       | The kind of the entity                                 | No       | `Component`    |
| `debug`             | Enable debug mode (uploads site as artifact)           | No       | `false`        |
| `working_directory` | Working directory for the action                       | No       | `.`            |
| `publish`           | Publishing behavior: `never`, `default-only`, `always` | No       | `default-only` |

### Usage Examples

Basic usage:

```yaml
jobs:
  build-docs:
    runs-on: unity-linux-runner
    steps:
      - uses: actions/checkout@v4
      
      - name: Build and publish TechDocs
        uses: Unity-Technologies/github-actions-workflows/actions/techdocs-build@main
        with:
          entity_name: my-service
```

With custom preprocessing:

```yaml
jobs:
  build-docs:
    runs-on: unity-linux-runner
    steps:
      - uses: actions/checkout@v4
      
      # Custom preprocessing steps         
      - name: Process templates
        run: |
          export SERVICE_NAME="my-service"
          export VERSION="${{ github.ref_name }}"
          envsubst < docs/template.md > docs/README.md
          
      - name: Run custom preprocessing
        run: python scripts/preprocess_docs.py
      
      # Build and publish
      - name: Build TechDocs
        uses: Unity-Technologies/github-actions-workflows/actions/techdocs-build@main
        with:
          entity_name: my-service
          entity_namespace: my-team
          entity_kind: Component
```

Debug mode:

```yaml
- name: Build TechDocs (debug mode)
  uses: Unity-Technologies/github-actions-workflows/actions/techdocs-build@main
  with:
    entity_name: my-service
    debug: true
    publish: never  # Don't publish when debugging
```

Custom working directory:

```yaml
- name: Build TechDocs from subdirectory
  uses: Unity-Technologies/github-actions-workflows/actions/techdocs-build@main
  with:
    entity_name: my-service
    working_directory: ./docs
```

Force publishing on any branch:

```yaml
- name: Build and publish TechDocs on feature branch
  uses: Unity-Technologies/github-actions-workflows/actions/techdocs-build@main
  with:
    entity_name: my-service
    publish: always  # Publish even on feature branches
```

### Publishing Behavior

- **`default-only` (default):** Publishes only on main/master default branches.
- **`always`:** Publishes on any branch (useful for feature branch previews).
- **`never`:** Only generates docs, never publishes (useful for testing).

### Permissions

Requires `contents: read` and `id-token: write` (for GCP authentication). When using this composite action (not the reusable workflow), your repository must be individually allowlisted in the Workload Identity Federation IAM Terraform configuration.

---

## 2. TechDocs Build (reusable workflow)

Reusable workflow that builds and publishes TechDocs documentation sites to Google Cloud Storage. Generates documentation from your repository and publishes it to both staging and production environments when changes are merged to the main branch.

**Use this reusable workflow when:**
- You have simple, static documentation
- You want clean workflow separation
- You prefer the isolation of separate jobs

### Inputs

| Parameter         | Description                                  | Required | Default     |
|-------------------|----------------------------------------------|----------|-------------|
| `entity_namespace`| The namespace of the entity                  | No       | `default`   |
| `entity_kind`     | The kind of the entity                       | No       | `Component` |
| `entity_name`     | The name of the entity                       | Yes      |             |
| `debug`           | Enable debug mode (uploads site as artifact) | No       | `false`     |

### Usage Example

```yaml
name: Build and Publish TechDocs

on:
  pull_request:
    paths:
      - docs/**
      - mkdocs.yml     
  push:
    branches:
      - main
    paths:
      - docs/**
      - mkdocs.yml

jobs:
  publish-techdocs:
    # Remember to set these permissions
    permissions:
      id-token: write
      contents: read
    uses: Unity-Technologies/github-actions-workflows/.github/workflows/techdocs-build.yml@main
    with:
      entity_name: my-service-name
      # Optional: override defaults
      # entity_namespace: my-team
      # entity_kind: Component
```

### Prerequisites

- Repository must have a `catalog-info.yaml` file at the root level.
- At least one Component with TechDocs enabled via a `backstage.io/techdocs-ref` annotation.
- Repositories using the reusable workflow do **not** need to be individually allowlisted (unlike the composite action).

---

## 3. TechDocs Preview (reusable workflow)

Reusable workflow that automatically adds a PR comment with a preview link to TechDocs documentation when docs are modified in a pull request.

### Usage Example

```yaml
name: TechDocs Preview

on:
  pull_request:
    paths:
      - docs/**
      - mkdocs.yml
      - .github/workflows/techdocs-preview.yml

jobs:
  techdocs_preview:
    uses: Unity-Technologies/github-actions-workflows/.github/workflows/techdocs-preview.yml@main
```

### Requirements

- Repository must have a `catalog-info.yaml` file at the root level.
- At least one Component with TechDocs enabled via a `backstage.io/techdocs-ref` annotation.

---

## 4. MkDocs (composite action)

Composite action that builds documentation in MkDocs format and uploads the result to a GCS bucket.

If you are looking to host documentation at `https://pages.prd.mz.internal.unity3d.com` or `https://services.docs.internal.unity3d.com`, check the Blob Proxy Workflow (section 13) instead.

### Pre-requisites

A GCS bucket already created and a documentation server or similar setup to visualize the documentation uploaded to the bucket as a webpage.

Set up Workload Identity Federation for your service account: [Configuring WIF](https://github.com/Unity-Technologies/github-actions-workflows/blob/main/docs/user-guides/using_workload_identity_federation.md).

If your GCS buckets are in the PRE Services projects you can add your repo here: <https://github.com/Unity-Technologies/pre-terraform-services-workspace/blob/main/prd/locals.tf> and use the [Pre Doc Server](https://github.com/Unity-Technologies/pre-doc-server) to visualize the documentation.

### Inputs

| Parameter                  | Description                                                                                                                                                     | Required | Default  |
|----------------------------|-----------------------------------------------------------------------------------------------------------------------------------------------------------------|----------|----------|
| `bucket_name`              | Name of the GCS bucket where the docs will be uploaded                                                                                                          | Yes      |          |
| `mkdocs_version`           | Version of the us-docker.pkg.dev/unity-pre-services-prd/github-actions-workflows/mkdocs-material container used to build the docs                               | No       | `8.2.6`  |
| `mkdocs_path`              | Path where the documentation is located                                                                                                                         | No       | `${PWD}` |
| `mkdocs_plugins`           | Additional plugins in `pip` format to be installed in the build image, space separated                                                                          | No       |          |
| `workload_identity_provider` | Workload identity provider (Deprecated. Uses PRE Centralized Workload Identity Provider by default)                                                           | No       |          |
| `service_account`          | Service Account used by workload identity provider                                                                                                              | Yes      |          |

### Usage Example

```yaml
name: my workflow

on:
  push:
    branches:
      - main
    paths:
      # add other docs paths as required
      - "mkdocs.yaml"
      - "docs/**"

jobs:
  build_publish:
    name: Build and publish docs
    runs-on: [unity-linux-runner]
    permissions: write-all
    steps:
      - name: Checkout
        uses: actions/checkout@v3
      - name: Build and publish docs
        uses: Unity-Technologies/github-actions-workflows/actions/mkdocs@main
        with:
          # required
          bucket_name: my-bucket # paths inside the bucket also supported
          service_account: doc-writer@unity-pre-services-prd.iam.gserviceaccount.com
          # optional
          mkdocs_version: 8.2.6
          mkdocs_path: ${PWD}/my_custom_docs_path
          mkdocs_plugins: mkdocs-redirects==1.2.0 mkdocs-awesome-pages-plugin==2.8.0
```

### Recommended Usage

- Use this action to upload documentation to standalone GCS buckets.
- Do not put other content in the target bucket unless using a custom path; the action mirrors the MkDocs build folder to the destination, and uploading to the root will overwrite any existing paths.
- If your docs are displayed by the [Pre Doc Server](https://github.com/Unity-Technologies/pre-doc-server), call this action with the staging bucket on pull requests (for preview), then with the production bucket on main/master branch.

---

## 5. Docusaurus (composite action)

Composite action that builds documentation in [Docusaurus](https://docusaurus.io/) format.

If you are looking to host documentation at `https://pages.prd.mz.internal.unity3d.com` or `https://services.docs.internal.unity3d.com`, check the Blob Proxy Workflow (section 13) instead.

### Inputs

| Parameter               | Description                                                                                                                  | Required | Default                               |
| ----------------------- | ---------------------------------------------------------------------------------------------------------------------------- | -------- | ------------------------------------- |
| `docusaurus_version`    | Version of the us-docker.pkg.dev/unity-pre-services-prd/github-actions-workflows/docusaurus container used to build the docs | No       | `latest`                              |
| `docusaurus_path`       | Folder where the docusaurus files are located                                                                                | No       | `docusaurus`                          |
| `docusaurus_base_url`   | Documentation base URL                                                                                                       | No       | `${{ github.event.repository.name }}` |
| `copy_legacy_docs_folder` | Legacy option to copy the docs folder at root of the repo, when it is placed outside the given `docusaurus_path`           | No       | `false`                               |
| `copy_package_json`     | Option to copy the package.json and perform a `yarn install`                                                                 | No       | `false`                               |

### Outputs

| Parameter         | Description                                               |
| ----------------- | --------------------------------------------------------- |
| `docusaurus-output` | Path of the folder where the build outputs will be placed |

### Usage Example

```yaml
name: my workflow

on:
  push:
    branches:
      - main
    paths:
    # add other docs paths as required
      - 'docusaurus/docs/**'

jobs:
  build_publish:
    name: Build docs
    runs-on: [unity-linux-runner]
    permissions: write-all
    steps:
      - name: Checkout
        uses: actions/checkout@v3
      - name: Build docs
        id: docusaurus
        uses: Unity-Technologies/github-actions-workflows/actions/docusaurus@main
        with:
          # optional
          docusaurus_version: latest # default
          docusaurus_path: docusaurus # default
          docusaurus_base_url: ${{ github.event.repository.name }} # default, repository name of the action caller
     - name: echo output folder
       run: |
         # Example how to get the build output to use in another action, e.g upload the docs
         output_folder=${{ steps.docusaurus.outputs.docusaurus-output }}
         echo ${output_folder}
```

### Docusaurus Repository Setup

- Install node + yarn, see <https://v2.docusaurus.io/docs/installation>.
- Run `npx @docusaurus/init@latest init docusaurus classic` to create the `docusaurus` folder.
- Set `baseUrl: process.env.DOCS_BASE_URL || '/'` in `docusaurus/docusaurus.config.js`.
- Use `stable` as `docusaurus_version` for old-format docs supported by the Jenkins shared libs.

---

## 6. OpenAPI Spec Validation (composite action)

Composite action that validates an OpenAPI spec file against a set of rules using [Spectral](https://github.com/stoplightio/spectral-action). The result of this validation is annotated in the spec file.

### Inputs

| Parameter  | Description                                                                                          | Required | Example        |
|------------|------------------------------------------------------------------------------------------------------|----------|----------------|
| `spec-files` | OpenAPI spec files to validate. Follows [fast-glob](https://www.npmjs.com/package/fast-glob) pattern | Yes      | `'specs/*.y*ml'` |
| `rule-file`  | File containing the rules to validate against                                                        | Yes      | `'ruleset.yaml'` |

The ruleset file format is a [Spectral ruleset file](https://docs.stoplight.io/docs/spectral/e5b9616d6d50c-rulesets).

### Spec Files Patterns

All files in a folder:

```yaml
spec-files: 'specs/*.y*ml'
```

Changed files only: use [tj-actions/changed-files](https://github.com/tj-actions/changed-files) to get the list of changed files, then transform the output to fast-glob format.

### Ruleset Examples

Recommended ruleset:

```yaml
extends: [["spectral:oas", recommended]]
```

All rules:

```yaml
extends: [[spectral:oas, all]]
```

### Outputs

The action annotates the spec file with linting results. Annotations appear next to the code in the Pull Request. The action fails if there are any errors; warnings alone will not cause failure. Severity is configurable in the ruleset file.

### Usage Example

```yaml
name: Validate Internal OpenAPI documentation for changed files

on:
  pull_request:
    branches:
      - "main"
    paths:
      - "config/internal/docs/routes/**/routes.y*ml"

jobs:
  oas-validation-per-change:
    permissions:
      contents: read
      pull-requests: write
      checks: write
    runs-on: [unity-linux-runner]
    steps:
      - uses: actions/checkout@v3
      - name: Filter changed files in internal/docs/routes folder
        id: routes-files
        uses: tj-actions/changed-files@v37
        with:
          write_output_files: true
          files: |
            config/internal/docs/routes/**/routes.y*ml
      - name: Prepare glob pattern for changed files
        shell: bash
        id: glob_pattern
        run: |
          if [ ${{ steps.routes-files.outputs.all_changed_files_count}} == 1 ]; then
            transformed_string=${{ steps.routes-files.outputs.all_changed_files}}
          else
            transformed_string="{$(echo ${{ steps.routes-files.outputs.all_changed_files}} | tr ' ' ',')}"
          fi
          echo "glob_string=$transformed_string" >> "$GITHUB_ENV"
      - name: Run OAS validation for changed files
        id: oas-validation
        uses: Unity-Technologies/github-actions-workflows/actions/oas-validation@main
        with:
          spec-files: ${{ env.glob_string }}
          rule-file: tools/oas-validator/config/spectral-oas-validation-ruleset-base.yaml
```

### Local Development

Run validation locally using the [Spectral CLI](https://github.com/stoplightio/spectral) with the same parameters. IDE extensions are also available via [Spectral integrations](https://github.com/stoplightio/spectral#%EF%B8%8F-integrations).

---

## 7. OpenAPI Validation (reusable workflow)

Reusable workflow that runs the [Spectral](https://stoplight.io/open-source/spectral) linting tool on a set of OpenAPI specification files. Uses the rules from [unity-common-open-api-ruleset](https://github.com/Unity-Technologies/unity-common-open-api-ruleset).

Two sets of rules are applied:
1. OpenAPI specification validation
2. Service Foundation guidelines validation (separated into modified-files and new-files jobs to enforce rules on new files without blocking changes on existing ones)

Results are posted as PR comments with downloadable reports and documentation links. PR files are also annotated with errors and warnings.

### Inputs

| Parameter                  | Description                                                                | Required | Default                     |
|----------------------------|----------------------------------------------------------------------------|----------|-----------------------------|
| `target-files`             | The glob pattern of files to validate                                      | Yes      |                             |
| `openapi-ruleset`          | The ruleset to use to validate OpenAPI specifications                      | No       | `.spectral.oapi.js`         |
| `service-foundation-ruleset` | The ruleset to use to validate service foundation guidelines             | No       | `.spectral.usf-guidelines.js` |
| `package-version`          | The version of the @unity/unity-common-open-api-ruleset package to install | No       | `1.x`                       |
| `dry-run`                  | Run the workflow but skip all jobs if true                                 | No       | `false`                     |

### Usage Example

```yaml
name: Validate OpenAPI specifications for changed files

on:
  pull_request:
    branches:
      - "master"
    paths:
      - "config/internal/docs/routes/**/routes.y*ml"
jobs:
  openapi-validation:
    uses: Unity-Technologies/github-actions-workflows/.github/workflows/openapi-validation.yml@main
    with:
      target-files: config/internal/docs/routes/**/routes.y*ml
```

### Dry Run

The dry-run option executes the workflow but skips all jobs. Useful when you want to set the validation as required even though it is not executed on every PR.

---

## 8. Terraform Format (reusable workflow + composite action)

### Reusable Workflow

Reusable workflow that runs `terraform fmt` and optionally auto-suggests the fixes to the PR.

If suggestions are committed, the user should pull changes:

```bash
git pull --rebase
```

#### Workflow Inputs

| Parameter           | Description                                                                                    | Required | Default |
|---------------------|------------------------------------------------------------------------------------------------|----------|---------|
| `working_directory` | Working directory where to run the action, space separated if multiple                         | No       | `.`     |
| `terraform_version` | Version of Terraform to use for the fmt action                                                 | Yes      |         |
| `auto_suggest`      | Boolean to decide if the fixes made by terraform fmt will be automatically suggested on the PR | No       | `true`  |

#### Workflow Usage Example

```yaml
name: Terraform fmt

on:
  workflow_dispatch:
  push:
    paths:
      - "**.tf"
  pull_request:
    paths:
      - "**.tf"

jobs:
  terraform-fmt:
    uses: Unity-Technologies/github-actions-workflows/.github/workflows/terraform-format.yml@main
    with:
      working_directory: .
      terraform_version: 1.2.2
      auto_suggest: true
```

### Composite Action

Composite action that runs Terraform fmt directly.

#### Action Inputs

| Parameter           | Description                                                            | Required | Default |
|---------------------|------------------------------------------------------------------------|----------|---------|
| `working_directory` | Working directory where to run the action, space separated if multiple | No       | `.`     |
| `terraform_version` | Version of Terraform to use for the fmt action                         | Yes      |         |

#### Action Usage Example

```yaml
name: Terraform fmt

on:
  workflow_dispatch:
  push:
    paths:
      - "**.tf"

jobs:
  terraform:
    name: Terraform fmt
    runs-on: [unity-linux-runner]
    permissions: write-all
    steps:
      - uses: actions/checkout@v3
      - name: Terraform fmt
        uses: Unity-Technologies/github-actions-workflows/actions/terraform-format@main
        with:
          working_directory: .
          terraform_version: 1.2.2
```

---

## 9. Packer Format (reusable workflow + composite action)

### Reusable Workflow

Reusable workflow that runs `packer fmt` and optionally auto-suggests the fixes to the PR.

If suggestions are committed, the user should pull changes:

```bash
git pull --rebase
```

#### Workflow Inputs

| Parameter           | Description                                                                                  | Required | Default |
|---------------------|----------------------------------------------------------------------------------------------|----------|---------|
| `working_directory` | Working directory where to run the action, space separated if multiple                       | No       | `.`     |
| `packer_version`    | Version of Packer to use for the fmt action (supports 1.7.1 and above)                       | Yes      |         |
| `auto_suggest`      | Boolean to decide if the fixes made by packer fmt will be automatically suggested on the PR  | No       | `true`  |

#### Workflow Usage Example

```yaml
name: Packer fmt

on:
  workflow_dispatch:
  push:
    paths:
      - "**.hcl"
  pull_request:
    paths:
      - "**.hcl"

jobs:
  packer-fmt:
    uses: Unity-Technologies/github-actions-workflows/.github/workflows/packer-format.yml@main
    with:
      working_directory: .
      packer_version: 1.9.4
      auto_suggest: true
```

### Composite Action

Composite action that runs Packer fmt directly.

#### Action Inputs

| Parameter           | Description                                                            | Required | Default |
|---------------------|------------------------------------------------------------------------|----------|---------|
| `working_directory` | Working directory where to run the action, space separated if multiple | No       | `.`     |
| `packer_version`    | Version of Packer to use for the fmt action (supports 1.7.1 and above) | Yes      |         |

#### Action Usage Example

```yaml
name: Packer fmt

on:
  workflow_dispatch:
  push:
    paths:
      - "**.hcl"

jobs:
  packer:
    name: Packer fmt
    runs-on: [unity-linux-runner]
    permissions: write-all
    steps:
      - uses: actions/checkout@v3
      - name: Packer fmt
        uses: Unity-Technologies/github-actions-workflows/actions/packer-format@main
        with:
          working_directory: .
          packer_version: 1.9.4
```

---

## 10. Lint YAML (workflow)

Internal workflow that lints all YAML files in the repository using `yamllint` (version 1.28.0). This workflow is defined in `.github/workflows/lint-yaml.yml` but does not have a dedicated docs README. It is not a reusable workflow; it runs directly on push events that touch `**.yaml` or `**.yml` files.

No configurable inputs. It installs Python 3.10, installs `yamllint==1.28.0`, and runs `yamllint .` against the repository root.

---

## 11. Docs Links Checker (reusable workflow)

Reusable workflow that performs sanity checks against the links in Docs projects' Markdown files. Validates that no absolute URLs relative to the same Docs repository or broken links were introduced in a PR.

The workflow runs several jobs: relative-links checking, image references checking, includes references checking, broken-links checking (via `linkcheck`), and language-slug-consistency checking.

### Inputs

| Parameter                      | Description                                                      | Required | Type   | Default   |
| ------------------------------ | ---------------------------------------------------------------- | -------- | ------ | --------- |
| `project-id`                   | The identifier of the docs project                               | Yes      | string |           |
| `project-dir`                  | The directory where the docs project is located                  | No       | string | `project` |
| `dockerfile-directory`         | The directory where the Dockerfile is located                    | No       | string | `.`       |
| `host-port`                    | The port exposed to the host                                     | No       | number | `3000`    |
| `container-port`               | The port which the service is listening to inside the container  | No       | number | `80`      |
| `linkcheck-version`            | The version of linkcheck to be used                              | No       | string | `3.0.0`   |
| `relative-links-checker-version` | The version of docs-relative-links-checker to be used         | No       | string | `""`      |
| `skip-file-content`            | The content of the file with URLs to be skipped                  | No       | string | `\/___$`  |

### Usage Example

```yaml
name: Check docs links

on: pull_request

jobs:
  check:
    uses: Unity-Technologies/github-actions-workflows/.github/workflows/docs-links-checker.yml@main
    with:
      project-id: my-project
```

---

## 12. Table of Contents Checker (reusable workflow)

Reusable workflow that runs `toc-tool`, a TypeScript NodeJS project published to Unity's internal JFrog Artifactory, to validate table of contents files.

The workflow runs two jobs:
1. **Compare** -- provides a semantic diff of the table of contents
2. **Validate** -- validates the table of contents

The caller workflow must listen to `pull_request_target` events (not `pull_request`) so that it runs even when the PR has merge conflicts in `.toc.json` files.

### Prerequisites

Enable [Unity self-hosted runners](https://docs.internal.unity.com/github-actions-runners/user-guides/using-self-hosted-runners) on the repo (required for fetching binaries from internal JFrog Artifactory).

### Inputs

| Parameter          | Description                                                               | Required | Type    | Default                                                           |
| ------------------ | ------------------------------------------------------------------------- | -------- | ------- | ----------------------------------------------------------------- |
| `toc-tool-version` | The version of the ToC tool to be used                                    | No       | number  | `latest`                                                          |
| `npm-registry-url` | The URL to the NPM registry to be used                                    | No       | number  | `https://unity3d.jfrog.io/artifactory/api/npm/doc-tools-npm-prod` |
| `node-version`     | The NodeJS version to be used                                             | No       | number  | `18`                                                              |
| `dry-run`          | Whether or not to run the actual toc-tool command against a Pull Request  | No       | boolean | `false`                                                           |

### Usage Example

```yaml
name: Check Table of Contents

on:
  pull_request_target:
    paths:
      - "**.toc.json"
  workflow_dispatch:

jobs:
  checker:
    uses: Unity-Technologies/github-actions-workflows/.github/workflows/table-of-contents-checker.yml@main
```

---

## 13. Blob Proxy (reusable workflow)

Reusable workflow that publishes documentation to be displayed at:

- `https://pages.prd.mz.internal.unity3d.com`
- `https://services.docs.internal.unity3d.com`

All branches also get their documentation uploaded. Branch preview URLs follow the format `https://pages-branches.prd.mz.internal.unity3d.com/<repository_name>-<branch_name>/`, where `branch_name` has all non-alphanumeric characters replaced with `_`.

### Pre-requisites

- Documentation that can be displayed as a webpage available in a build artifact.
- Alternatively, any pre-built documentation already present in the repository; use `docs_path` to point to the corresponding folder.

### Inputs

| Parameter          | Description                                               | Required | Default          |
| ------------------ | --------------------------------------------------------- | -------- | ---------------- |
| `docs_path`        | Path where the docs files are located                     | No       | `tmp/docs-build` |
| `docs_artifact`    | Name of the build artifact containing the docs, if any    | No       |                  |
| `docs_artifact_path` | Path where to download the build artifact, if there is one | No     | `tmp/docs-build` |

### Outputs

| Parameter   | Description                              |
| ----------- | ---------------------------------------- |
| `upload_path` | Path where the docs were uploaded in GCS |

### Usage Examples

Building and publishing Docusaurus documentation:

```yaml
name: my workflow

on:
  push:
    paths:
      # add other docs paths as required
      - "docusaurus/**"

jobs:
  build:
    name: Build docs
    runs-on: [unity-linux-runner]
    permissions: write-all
    steps:
      - name: Checkout
        uses: actions/checkout@v3

      - name: Build docs
        id: docusaurus
        uses: Unity-Technologies/github-actions-workflows/actions/docusaurus@main

      # If invoking the workflow from github.cds use upload-artifact@v3
      - name: Upload artifact
        uses: actions/upload-artifact@v4
        with:
          name: docs-build
          path: ${{ steps.docusaurus.outputs.docusaurus-output }}
          retention-days: 1

  build_publish:
    needs:
      - build
    uses: Unity-Technologies/github-actions-workflows/.github/workflows/blob-proxy.yml@main
    with:
      docs_artifact: docs-build
      # optional
      docs_path: tmp/docs-build # default
      docs_artifact_path: tmp/docs-build # default
```

Publishing pre-built documentation already in the repository:

```yaml
name: my workflow

on:
  push:
    paths:
      # add other docs paths as required
      - "docs/**"

jobs:
  publish:
    needs:
    uses: Unity-Technologies/github-actions-workflows/.github/workflows/blob-proxy.yml@main
    with:
      docs_path: docs
```
