# Utility Actions and Workflows — Reference Documentation

> **Provenance (not runtime dependencies):**
> These docs are bundled from [Unity-Technologies/github-actions-workflows](https://github.com/Unity-Technologies/github-actions-workflows).
> If upstream docs change, refresh this file to match; do not improvise new workflow YAML.
> Last synced: 2026-04-09

---

## cache-node-modules

**Description:** Composite action that sets up Node.js, fetches Vault secrets for JFrog authentication, and installs/caches `node_modules`. Skips `npm ci` entirely on cache hit, providing significant speedup over `setup-node`'s built-in caching.

Cache key is based on `node-version`, the hash of `package-lock.json`, and the `npm-command`.

**Inputs:**

| parameter | description | required | default |
|-----------|-------------|----------|---------|
| node-version | Node.js version to install | `true` | |
| working-directory | Directory containing `package.json` and `package-lock.json` | `false` | `.` |
| registry-url | JFrog registry URL for npm | `false` | `https://unity3d.jfrog.io/artifactory/api/npm/unity-npm-prod-local/auth/unity` |
| npm-command | npm command to install dependencies | `false` | `ci` |

**Outputs:** `cache-hit`, `cache-key`

**Usage:**

```yaml
- uses: Unity-Technologies/github-actions-workflows/actions/cache-node-modules@main
  with:
    node-version: 18
    working-directory: tools/subfolder  # omit if package.json is in root
```

---

## npm-ci-install

**Description:** Composite action that authenticates npm to JFrog and runs `npm ci` with npm cache. Requires `permissions: write-all`.

**Inputs:**

| parameter | description | required | default |
|-----------|-------------|----------|---------|
| working-directory | Working directory | `false` | `.` |
| npm-params | Parameters to pass to npm | `false` | |
| node-version | Node version | `false` | `20.X` |

**Usage:**

```yaml
- uses: Unity-Technologies/github-actions-workflows/actions/npm-ci-install@main
# Then: npm run tsc, npm test, etc.
```

---

## npm-package-check

**Description:** Checks if a specific version of an npm package (from `package-lock.json`) already exists in JFrog Artifactory. Useful for skipping publish jobs when a version is already published.

**Inputs:**

| parameter | description | required | default |
|-----------|-------------|----------|---------|
| jfrog_artifactory_registry_url | JFrog Artifactory registry URL | `true` | `https://unity3d.jfrog.io/artifactory/api/npm/unity-npm-prod-local/` |
| jfrog_artifactory_registry_scope | JFrog Artifactory registry scope | `true` | `@unity` |

**Outputs:** `package_exist` (`'true'`/`'false'`), `package` (e.g., `@unity/node-monitoring@12.2.0`)

**Permissions required:** `id-token: write`, `contents: read`

**Usage:**

```yaml
- name: Check npm package
  id: check
  uses: Unity-Technologies/github-actions-workflows/actions/npm-package-check@main

# Then conditionally skip publish:
# if: needs.check-package.outputs.package_exist == 'false'
```

---

## auth-npm

**Description:** Authenticates npm for read-only access to `unity3d.jfrog.io/artifactory/`. Retrieves the auth token and writes it to `.npmrc`. Requires `permissions: write-all`.

**Inputs:**

| parameter | description | required | default |
|-----------|-------------|----------|---------|
| working-directory | Working directory | `false` | `.` |
| output-file | Output file for auth config | `false` | `.npmrc` |

**Outputs:** `jfrog-auth-token`

**Usage (e.g., for Docker builds needing JFrog auth):**

```yaml
- uses: Unity-Technologies/github-actions-workflows/actions/auth-npm@main
- uses: Unity-Technologies/github-actions-workflows/actions/build-docker-image@main
  with:
    image_name: gcr.io/unity-source/my-service
    service_account: ci-push@unity-source.iam.gserviceaccount.com
    docker_build_extra_args: "--secret id=npmrc,src=.npmrc"
```

---

## cache-gcloud-sdk

**Description:** Installs and caches the Google Cloud SDK. The official action is slow; this action caches the installation folder. Cache key is based on SDK version and additional components.

**Inputs:**

| parameter | description | required | default |
|-----------|-------------|----------|---------|
| sdk-version | Gcloud SDK version to install | `true` | |
| additional-components | Additional components (space-separated) | `false` | |

**Outputs:** `cache-hit`, `cache-key`

**Usage:**

```yaml
- uses: Unity-Technologies/github-actions-workflows/actions/cache-gcloud-sdk@main
  with:
    sdk-version: 422.0.0
    additional-components: beta bigtable pubsub-emulator
```

---

## ios-sdk-cache

**Description:** Caches shared gems, brew dependencies (xcodegen, clang-format), swift-format, and Cocoapods for iOS XCFramework development. Only works on GitHub.com (no macOS runners on GitHub.cds).

Caches: `vendor/bundle` (gems), xcodegen/clang-format (brew), `vendor/swift-format`, and `Pods` directory (keyed on `Podfile.lock`).

**Inputs:** None.

**Usage:**

```yaml
- uses: Unity-Technologies/github-actions-workflows/actions/ios-sdk-cache@main
```

---

## trigger-workflow-and-wait (reusable workflow)

**Description:** Triggers a workflow in another repository using `convictional/trigger-workflow-and-wait` and waits for completion. For same-repo triggers, use `convictional/trigger-workflow-and-wait` directly instead.

**Pre-requisites:**
- Remote repo must have the `pre-shared-workflows-auth` app assigned (via [repodb](https://repodb.ds.unity3d.com/app)).
- Remote repo must have `.github/allowed-remote-repos.yaml` specifying allowed callers.

**Key Inputs:**

| parameter | required | default | description |
|-----------|----------|---------|-------------|
| repo | true | | Target repository name |
| workflow_file_name | true | | Workflow file to trigger (e.g., `main.yml`) |
| owner | false | `Unity-Technologies` | Repository owner |
| ref | false | `main` | Branch/tag/SHA to run against |
| client_payload | false | `{}` | JSON payload |
| propagate_failure | false | `true` | Fail if downstream fails |
| wait_interval | false | `10` | Seconds between status checks |

**Usage:**

```yaml
jobs:
  trigger:
    uses: Unity-Technologies/github-actions-workflows/.github/workflows/trigger-workflow-and-wait.yml@main
    with:
      repo: 'my-repo'
      workflow_file_name: my_workflow.yaml
```

---

## run-on-pull-request-comment (reusable workflow)

**Description:** Runs arbitrary commands when a PR comment is made. Validates the PR is open, the commenter is a user (not bot), and the commenter has the required permission level.

**Pre-requisites:**
- Remote repo must have `pre-shared-workflows-auth` app and `.github/allowed-remote-repos.yaml`.
- Currently only supported for github.com/Unity-Technologies.

**Inputs:**

| parameter | required | description |
|-----------|----------|-------------|
| run | true | Command to run on PR comment |
| required_permission | true | Required permission: `admin`, `maintain`, `push`, `triage`, or `pull` |

**Usage (e.g., `/trigger-ci` comment adds empty commit to re-trigger CI):**

```yaml
on:
  issue_comment:
    types: [created]

jobs:
  trigger-ci:
    uses: Unity-Technologies/github-actions-workflows/.github/workflows/run-on-pull-request-comment.yaml@main
    if: ${{ github.event.comment.body == '/trigger-ci' }}
    with:
      required_permission: push
      run: |
        gh pr checkout ${{ github.event.issue.number }}
        git commit --allow-empty -m "Trigger CI"
        git push origin HEAD
```

---

## helm-chart-validate-publish (reusable workflow)

**Description:** Validates Helm charts (lint, unittest, kubeconform) and publishes them to GAR or ChartMuseum. Publishing occurs only on main/master branch pushes.

**Validation steps:** `helm lint --strict`, `helm unittest`, `kubeconform` on rendered templates.
**Publishing steps:** `helm package` then `helm push` to OCI registry.

**Key Inputs:**

| parameter | required | default | description |
|-----------|----------|---------|-------------|
| chart_name | true | | Name of chart to publish |
| helm_cli_version | false | `3.9.2` | Helm CLI version |
| files | false | `.` | Files/directories to validate |
| values_files | false | `values.yaml` | Values files for rendering |
| publish | false | `false` | Enable publishing |
| run_unittests | false | `false` | Run helm unittests |
| chart_repository | false | `https://chartmuseum.internal.unity3d.com` | Target chart repo |
| chart_version | false | | SemVer 2 version override |

**Usage:**

```yaml
jobs:
  helm-validate-publish:
    uses: Unity-Technologies/github-actions-workflows/.github/workflows/helm-chart-validate-publish.yml@main
    with:
      chart_name: my-chart
      publish: true
```

---

## merge-coverage

**Description:** Merges nyc-generated code coverage reports from parallelized test runners into a single report for SonarQube. Downloads unmerged reports from an artifact, merges them, and uploads the result.

**Inputs:**

| parameter | required | default | description |
|-----------|----------|---------|-------------|
| unmerged-coverage-reports-artifact-name | true | `unmerged-coverage-reports` | Artifact name containing unmerged reports |
| output-folder | true | `code-coverage-data` | Output folder for merged report |
| code-coverage-workspace-generates | true | | Workspace directory of the job that generated coverage |
| merged-code-coverage-artifact-name | true | `code-coverage-data` | Name of uploaded merged artifact |

**Usage:**

```yaml
- uses: Unity-Technologies/github-actions-workflows/actions/merge-coverage@main
  with:
    unmerged-coverage-reports-artifact-name: unmerged-code-coverage-data
    output-folder: code-coverage-data
    code-coverage-workspace-generates: /runner/_work/example-repo/example-repo
    merged-code-coverage-artifact-name: code-coverage-data
```

---

## only-allowed-files-changed

**Description:** Checks if only allowed files were changed in a PR. Designed for PR approval automation. Works with outputs from [tj-actions/changed-files](https://github.com/tj-actions/changed-files).

**Key Inputs:**

| parameter | required | description |
|-----------|----------|-------------|
| pr_added_files | true | Comma-separated added files |
| pr_modified_files | true | Comma-separated modified files |
| pr_deleted_files | true | Comma-separated deleted files |
| pr_all_changed_files | true | Comma-separated all changed files |
| added_files_allowed_folders | false | Folders where new files are allowed (globs supported) |
| modified_files_allowed | false | Files allowed to be modified |
| allow_added_files_entries_in_codeowners | false | Allow new CODEOWNERS entries for added files |

**Output:** `only_allowed_files_changed` (`'true'`/`'false'`)

**Usage:**

```yaml
- uses: tj-actions/changed-files@v45
  id: changed-files
  with:
    separator: ','
- uses: Unity-Technologies/github-actions-workflows/actions/only-allowed-files-changed@main
  with:
    added_files_allowed_folders: 'allowed_folder1,test_folder/test/*'
    modified_files_allowed: '.github/CODEOWNERS'
    pr_added_files: ${{ steps.changed-files.outputs.added_files }}
    pr_modified_files: ${{ steps.changed-files.outputs.modified_files }}
    pr_deleted_files: ${{ steps.changed-files.outputs.deleted_files }}
    pr_all_changed_files: ${{ steps.changed-files.outputs.all_changed_files }}
```

---

## fail-on-label

**Description:** Fails the workflow if the PR contains any of the specified blocking labels. Use to prevent merging PRs with labels like "do not merge".

**Inputs:**

| parameter | required | default | description |
|-----------|----------|---------|-------------|
| blocking_labels | true | `do not merge,do-not-merge` | Comma-separated blocking labels |
| pr_labels | false | | Override PR labels (testing only) |

**Usage:**

```yaml
on:
  pull_request:
    types: [labeled, unlabeled, opened, edited, synchronize]

jobs:
  check:
    runs-on: unity-linux-runner
    steps:
      - uses: Unity-Technologies/github-actions-workflows/actions/fail-on-label@main
        with:
          blocking_labels: "do-not-merge,do not merge"
```

---

## sendsafely

**Description:** Securely packages and sends secrets via [SendSafely](https://www.sendsafely.com/). Recipients are restricted to Unity email domains (`unity.com`, `unity3d.com`). All sensitive inputs are automatically masked in logs.

**Inputs:**

| parameter | required | default | description |
|-----------|----------|---------|-------------|
| sendsafely_api_key | true | | SendSafely API key |
| sendsafely_api_secret | true | | SendSafely API secret |
| recipients | true | | Comma-separated recipient emails |
| message | true | | Secret message/token to send |
| sendsafely_api_url | false | `https://share.unity.com` | SendSafely API URL |

**Outputs:** `secure_link`, `package_id`, `error_message`

**Usage:**

```yaml
- uses: Unity-Technologies/github-actions-workflows/actions/sendsafely@main
  with:
    sendsafely_api_key: ${{ secrets.SENDSAFELY_API_KEY }}
    sendsafely_api_secret: ${{ secrets.SENDSAFELY_API_SECRET }}
    recipients: 'user1@unity.com,user2@unity3d.com'
    message: ${{ steps.generator.outputs.secret_token }}
```

---

## download-yamato-artifact

**Description:** Downloads an artifact produced by a Yamato job and optionally extracts it. Exactly one of `api-key` or `token` must be provided.

**Inputs:**

| parameter | required | default | description |
|-----------|----------|---------|-------------|
| job-id | true | | Yamato job ID |
| artifact-name | true | | Artifact name to download |
| api-key | false | | Long-lived Yamato API key (mutually exclusive with `token`) |
| token | false | | Short-lived Yamato PAT (mutually exclusive with `api-key`) |
| extraction-path | false | | Path to extract to (omit to keep as zip) |

**Output:** `path` (zip file path or extraction directory)

**Usage:**

```yaml
- uses: Unity-Technologies/github-actions-workflows/actions/download-yamato-artifact@main
  with:
    job-id: "123456789"
    artifact-name: "build-output"
    token: ${{ secrets.YAMATO_TOKEN }}
    extraction-path: "./yamato-artifact"
```

---

## cleanup-artifactory-builds

**Description:** Deletes old unused builds in a JFrog Artifactory repo. Use to automate pruning old builds for many paths on a schedule.

**Key Inputs:**

| parameter | required | default | description |
|-----------|----------|---------|-------------|
| bearer_token | true | | JFrog token with read+delete permissions |
| paths | true | | Multiline list of paths to clean up |
| repo | false | `unity-npm-prod-local` | Repository name |
| max_builds | false | `50` | Number of builds to keep per path |
| dry_run | false | `false` | No-op on delete calls |
| registry_base_url | false | `https://unity3d.jfrog.io` | Registry URL |

**Usage:**

```yaml
on:
  schedule:
    - cron: "0 9 * * MON"

jobs:
  cleanup:
    runs-on: [self-hosted, gcp, linux]
    container: node:18.15
    steps:
      - uses: actions/checkout@v3
      - uses: Unity-Technologies/github-actions-workflows/actions/cleanup-artifactory-builds@main
        with:
          bearer_token: ${{ secrets.JFROG_ARTIFACTORY_DELETE_TOKEN }}
          paths: |
            path/to/service/1
            path/to/service/2
          max_builds: 50
```

---

## prevent-merges-during-the-build

**Description:** Marks a commit status as pending during default-branch builds. Require this status check in branch protection rules to prevent PR merges while the build is running. Must be called on every default branch commit and every PR commit.

**Inputs:**

| parameter | required | description |
|-----------|----------|-------------|
| token | true | `${{ secrets.GITHUB_TOKEN }}` |
| workflow-file-name | true | Workflow file name (e.g., `ci.yaml`) |

**Setup:** After first run, add `"(<workflow-file-name>) Wait default branch workflow completion"` as a required status check in branch protection rules.

**Usage:**

```yaml
on:
  push:
    branches: [main]
  pull_request:
    branches: [main]

concurrency:
  group: ${{ github.workflow }}-${{ github.ref }}

jobs:
  ci:
    runs-on: [unity-linux-runner]
    permissions: write-all
    steps:
      - uses: actions/checkout@v3
      - uses: Unity-Technologies/github-actions-workflows/actions/prevent-merges-during-the-build@main
        with:
          token: ${{ secrets.GITHUB_TOKEN }}
          workflow-file-name: ci.yaml
```

---

## add-team-permissions-for-codeowners

**Description:** Automatically adds write permissions to a GitHub team when a new CODEOWNER entry is added, provided all team members are in the `Employees` group. Only works in `Unity-Technologies` org.

**Pre-requisites:** GitHub App token with org members read, and repo admin/issues/PRs read-write.

**Inputs:**

| parameter | required | description |
|-----------|----------|-------------|
| codeowners_file | true | Path to CODEOWNERS file |
| github_token | true | GitHub App authentication token |

**Usage:**

```yaml
on:
  pull_request:
    types: [opened, reopened, synchronize, ready_for_review]
    paths:
      - '.github/CODEOWNERS'

jobs:
  add-perms:
    runs-on: unity-linux-runner
    steps:
      - uses: actions/checkout@v4
      - uses: actions/create-github-app-token@v1
        id: app-token
        with:
          app-id: YOUR_APP_ID
          private-key: ${{ secrets.APP_PRIVATE_KEY }}
      - uses: Unity-Technologies/github-actions-workflows/actions/add-team-permissions-for-codeowners@main
        if: ${{ github.event.pull_request.draft == false }}
        with:
          codeowners_file: '.github/CODEOWNERS'
          github_token: ${{ steps.app-token.outputs.token }}
```

---

## sync-files-remote-pull-request

**Description:** Opens a PR in another repository to sync files between repos. Use when you keep the source of truth in one repo but need to publish changes to another (e.g., API schemas, documentation).

**Pre-requisites:** Personal access token (ideally from a service account) with push access to the target repo.

**Key Inputs:**

| parameter | required | default | description |
|-----------|----------|---------|-------------|
| token | true | | Personal access token |
| user-email | true | | Committer email |
| user-name | true | | Committer name |
| checkout-folder | true | | Folder where remote repo was checked out |
| destination-repo | true | | Target repo (`org/repo`) |
| destination-branch | true | | Branch name for the PR |
| destination-base-branch | false | `main` | Base branch in target repo |
| commit-message | true | | Commit message |
| pr-title | true | | PR title |
| sync-files | true | | Multiline pairs: `<source-path> <dest-path>` |
| pr-description | false | | PR body |
| pr-teams-reviewer | false | | Team reviewers (comma-separated) |
| pr-reviewer | false | | Individual reviewers (comma-separated) |

**Usage:**

```yaml
- uses: actions/checkout@v3
- uses: actions/checkout@v3
  with:
    repository: Unity-Technologies/target-repo
    path: target
    token: ${{ secrets.PAT }}
- uses: Unity-Technologies/github-actions-workflows/actions/sync-files-remote-pull-request@main
  with:
    token: ${{ secrets.PAT }}
    user-email: "svc@unity3d.com"
    user-name: "Service Account"
    checkout-folder: "./target"
    destination-repo: "Unity-Technologies/target-repo"
    destination-branch: "sync/update-${{ github.sha }}"
    commit-message: "chore: sync files"
    pr-title: "Sync files from source repo"
    sync-files: |
      ./api/schema.yaml ./target/config/schema.yaml
```
