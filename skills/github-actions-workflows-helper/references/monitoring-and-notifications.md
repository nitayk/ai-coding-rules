# Monitoring and Notifications — Reference Documentation

> **Provenance (not runtime dependencies):**
> These docs are bundled from [Unity-Technologies/github-actions-workflows](https://github.com/Unity-Technologies/github-actions-workflows).
> If upstream docs change, refresh this file to match; do not improvise new workflow YAML.
> Last synced: 2026-04-09

---

## Send a Slack Message

Reusable workflow that can be used to send Slack messages to different destinations, such as a channel, a user based on their GitHub username, or an email address.
As this is a reusable workflow it's not possible to use this to send messages between `steps` in a single `job` and you should use the mechanism shown in the example instead.

Workflow [source code](https://github.com/Unity-Technologies/github-actions-workflows/blob/main/.github/workflows/send-slack-message.yml).

### Inputs

| parameter              | description                                                                                           | required | default          |
| ---------------------- | ----------------------------------------------------------------------------------------------------- | -------- | ---------------- |
| channels               | Comma-separated list of Slack channels to send the message to.                                        | `false`  |                  |
| gh_usernames           | Comma-separated list of GitHub usernames to send DMs to.                                              | `false`  |                  |
| gh_instance            | GitHub instance for user. Can be either 'github.com' or 'github.cds.internal.unity3d.com'.            | `false`  | `github.com`     |
| emails                 | Comma-separated list of email addresses to send DMs to.                                               | `false`  |                  |
| message                | Message text. When used with message_blocks, serves as the fallback text for notifications.           | `false`  |                  |
| message_blocks         | Slack Block Kit blocks (JSON string). Can be combined with 'message', where message acts as fallback. | `false`  |                  |
| fail-on-error          | fail the workflow if there are errors. Ignore errors by default.                                      | `false`  | `false`          |
| slack-bot-display-name | Display name of the bot sending the message.                                                          | `false`  | `GitHub Actions` |
| slack-bot-icon-emoji   | Emoji to use as the icon of the bot sending the message.                                              | `false`  | `:github:`       |

It's possible to send the same message to multiple destinations.

### Outputs

None.

### Usage Examples

> **Important:**
> If the channel is private, you need to add `@PRE Slackbot` to the channel to allow it to post messages there.

```yaml
name: CI/CD

on: [push, workflow_dispatch]

jobs:
  # your CI/CD could have a test job that does testing
  # a job here can be anything like build or deployment or whatever
  test:
    name: Test
    runs-on: [ unity-linux-runner ]
    permissions: write-all
    steps:
      - uses: actions/checkout@v3
      - uses: actions/setup-go@v3
        with:
          go-version-file: go.mod
          cache: true
          cache-dependency-path: go.sum
      - name: Run tests
        run: |
          go test -race -coverprofile=coverage.out -timeout 30s ./...

  # You might want to send the message when tests are completed.
  # here's three different ways:

  # send a message to a channel or DM slack user
  send-slack-message:
    # use needs to force order
    needs: [test]
    uses: Unity-Technologies/github-actions-workflows/.github/workflows/send-slack-message.yml@main
    with:
      channels: channelname
      message: "Tests completed!"

  # send a DM on slack based on github username
  send-slack-message-to-gh-username:
    needs: [test]
    uses: Unity-Technologies/github-actions-workflows/.github/workflows/send-slack-message.yml@main
    with:
      # you can hardcode any github user here if you want
      # or you can do this to get send it to the person who triggered the workflow
      gh_usernames: ${{ github.actor }}, other-github-username
      message: "Test completed!"

  # send a DM on slack based on github username
  # only send if dependant job failed.
  send-slack-message-to-gh-username-on-failure:
    needs: [test]
    if: always() && needs.test.result == 'failure'
    uses: Unity-Technologies/github-actions-workflows/.github/workflows/send-slack-message.yml@main
    with:
      # you can hardcode any github user here
      # or you can do this to get send it to the person who triggered the workflow
      gh_usernames: ${{ github.actor }}
      # example for GH Enterprise instance, pass the instance name for user resolution.
      gh_instance: github.cds.internal.unity3d.com 
      message: "Tests failed!"

  # you can use multiline messages, use hyperlinks, and use markdown-style formatting
  # see https://api.slack.com/reference/surfaces/formatting for more formatting tips
  send-slack-message-to-gh-username-with-special-characters:
    needs: [test]
    uses: Unity-Technologies/github-actions-workflows/.github/workflows/send-slack-message.yml@main
    with:
      gh_usernames: ${{ github.actor }}
      message: |
        *Hello!*
        This message is coming from <https://github.com/${{ github.repository }}/actions/runs/${{ github.run_id }}|this workflow run>!

  # you can also send messages with Slack Block Kit blocks
  send-slack-message-with-blocks:
    needs: [test]
    uses: Unity-Technologies/github-actions-workflows/.github/workflows/send-slack-message.yml@main
    with:
      # you can also send to multiple email addresses
      # see https://docs.slack.dev/block-kit/ for more formatting tips
      # use the block kit builder to test your message: https://app.slack.com/block-kit-builder
      emails: user@unity3d.com, other-user@unity3d.com
      # message acts as fallback for notifications that don't support blocks
      message: "*Your workflow is ready! :rocket:.*"
      # message_blocks is a JSON string of Slack Block Kit blocks
      message_blocks: |
        [
          {
            "type": "section",
            "text": {
              "type": "mrkdwn",
              "text": "*Your workflow is ready! :rocket:.*"
            }
          },
          {
            "type": "section",
            "text": {
              "type": "mrkdwn",
              "text": "Hello from <https://github.com/${{ github.repository }}/actions/runs/${{ github.run_id }}|GHA test run>!"
            }
          },
          {
            "type": "context",
            "elements": [
              {
                "type": "mrkdwn",
                "text": "From commit `${{ github.sha }}`"
              }
            ]
          }
        ]
```

---

## Duke

Reusable workflow that applies (or dry-runs) dashboards, alerts, recording rules, and SLOs using Duke.

Workflow [source code](https://github.com/Unity-Technologies/github-actions-workflows/blob/main/.github/workflows/duke.yml).

### Pre-requisites

The workflow operates on configuration files in predefined locations:

| File Type | Location |
| --------- | -------- |
| Dashboards | `./monitoring/dashboards/*.(yml\|yaml)` |
| Alerts | `./monitoring/alerts/*.(yml\|yaml)` |
| Recording Rules | `./monitoring/recording_rules/*.(yml\|yaml)` |
| Service Level Objectives | `./monitoring/slos/*.(yml\|yaml)` |
| Combined Config | `./monitoring.(yml\|yaml)` |

The syntax of these files is described in the [Duke documentation](https://github.com/Unity-Technologies/duke/tree/master/docs).

### Inputs

| Parameter | Description | Required | Default |
| --------- | ----------- | -------- | ------- |
| `apply` | Apply resources (`true`) or dry-run only (`false`) | `false` | `false` |
| `duke_root_dir` | Location of monitoring config files (testing only) | `false` | |
| `download_artifact_name` | Name of artifact to download before running Duke | `false` | `""` |
| `download_artifact_path` | Path where to download the artifact | `false` | `.` |

### Outputs

None.

### Usage Examples

#### Basic Usage

```yaml
name: Duke

on:
  workflow_dispatch:
  push:
    branches:
      - main
    paths:
      - "monitoring.yaml"
      - "monitoring.yml"
      - "monitoring/**"
  pull_request:
    paths:
      - "monitoring.yaml"
      - "monitoring.yml"
      - "monitoring/**"

jobs:
  dry-run:
    uses: Unity-Technologies/github-actions-workflows/.github/workflows/duke.yml@main

  apply:
    if: github.event_name == 'workflow_dispatch' || github.ref == 'refs/heads/main'
    uses: Unity-Technologies/github-actions-workflows/.github/workflows/duke.yml@main
    with:
      apply: true
```

#### Advanced: Download Artifact Before Running Duke

```yaml
jobs:
  generate-monitoring-files:
    runs-on: [unity-linux-runner]
    steps:
      - uses: actions/checkout@v3

      - name: Generate monitoring files
        run: |
          <generation logic>

      - name: Upload monitoring assets
        uses: actions/upload-artifact@v4
        with:
          name: monitoring-folder
          path: monitoring

  duke:
    needs: generate-monitoring-files
    if: github.event_name == 'workflow_dispatch' || github.ref == 'refs/heads/main'
    uses: Unity-Technologies/github-actions-workflows/.github/workflows/duke.yml@main
    with:
      apply: true
      download_artifact_name: monitoring-folder
      download_artifact_path: monitoring
```

#### Best Practice: Using Duke + Duke Reviewer Together

```yaml
name: Duke

on:
  workflow_dispatch:
  push:
    branches:
      - main
    paths:
      - "monitoring.yaml"
      - "monitoring.yml"
      - "monitoring/**"
  pull_request:
    paths:
      - "monitoring.yaml"
      - "monitoring.yml"
      - "monitoring/**"

jobs:
  # AI-powered review for alerting and recording rules (PRs only)
  review:
    if: github.event_name == 'pull_request'
    uses: Unity-Technologies/github-actions-workflows/.github/workflows/duke-reviewer.yml@main

  # Validate monitoring configurations
  dry-run:
    uses: Unity-Technologies/github-actions-workflows/.github/workflows/duke.yml@main

  # Apply configurations (main branch or manual trigger only)
  apply:
    if: github.event_name == 'workflow_dispatch' || github.ref == 'refs/heads/main'
    uses: Unity-Technologies/github-actions-workflows/.github/workflows/duke.yml@main
    with:
      apply: true
```

#### Migrating from MZ Shared Jenkins Library

If migrating from the MZ Shared Jenkins Library, set `skip_monitoring` to `true` in your `Jenkinsfile`, then create `.github/workflows/duke.yml` using the best-practice example above. The Jenkins library is being deprecated.

### Network Requirements

Requires `runs-on: [unity-linux-runner]` since it connects to Grafana and Vault on the internal network.

---

## Duke Reviewer

Reusable workflow that provides AI-powered code review for Prometheus alerting and recording rules using an LLM. It analyzes changes to monitoring configuration files and posts AI-generated review comments directly on pull requests.

Workflow [source code](https://github.com/Unity-Technologies/github-actions-workflows/blob/main/.github/workflows/duke-reviewer.yml).

### Pre-requisites

- Operates on pull requests that modify monitoring files.
- By default, matches files with pattern `^monitoring/(alerts|recording_rules)/.*\.ya?ml$`.
- Requires access to Unity's internal LiteLLM API endpoint.

### Inputs

| Parameter | Description | Required | Default |
| --------- | ----------- | -------- | ------- |
| `monitoring_paths_pattern` | Regex pattern to match monitoring files | `false` | `^monitoring/(alerts\|recording_rules)/.*\.ya?ml$` |
| `provider` | LLM provider to use for the review | `false` | `gemini` |
| `model` | Model to use for the review | `false` | `gemini-2.5-flash` |
| `llm_url` | URL for the LLM API endpoint | `false` | `https://uai-litellm.internal.unity.com/v1` |
| `duke_reviewer_version` | Version of duke-reviewer to install | `false` | `latest` |

### Outputs

None.

### Usage Examples

#### Basic Usage

```yaml
name: Duke Reviewer

on:
  pull_request:
    paths:
      - "monitoring/alerts/**"
      - "monitoring/recording_rules/**"

jobs:
  review:
    uses: Unity-Technologies/github-actions-workflows/.github/workflows/duke-reviewer.yml@main
```

#### Custom File Pattern

```yaml
name: Duke Reviewer

on:
  pull_request:
    paths:
      - "prometheus/**"

jobs:
  review:
    uses: Unity-Technologies/github-actions-workflows/.github/workflows/duke-reviewer.yml@main
    with:
      monitoring_paths_pattern: "^prometheus/(alerts|rules)/.*\\.ya?ml$"
```

#### Using a Specific Model

```yaml
jobs:
  review:
    uses: Unity-Technologies/github-actions-workflows/.github/workflows/duke-reviewer.yml@main
    with:
      provider: "gemini"
      model: "gemini-2.5-pro"
```

### How It Works

1. **Detects changed files** -- Identifies which monitoring files were modified in the PR.
2. **Runs duke-reviewer** -- Analyzes changes using an LLM to identify potential issues.
3. **Posts PR comment** -- Automatically posts review findings as a comment with links to relevant files.

### Network Requirements

Requires `runs-on: [unity-linux-runner]` since it connects to Vault and LiteLLM API on the internal network.

---

## Dashboards As Code

Reusable workflow that generates and applies (or dry-runs) dashboards using Grafana's Foundation SDK Go library or pre-generated JSON manifests.

Workflow [source code](https://github.com/Unity-Technologies/github-actions-workflows/blob/main/.github/workflows/dashboards-as-code.yml).

### Pre-requisites

**For Go-based dashboards:**
- Reads and executes dashboard generation code from `./monitoring/dashboards/go/*.go`
- Writes rendered dashboards to `./monitoring/dashboards/go/resources/*.json`
- Commits `go.mod`, `go.sum`, and `resources/*.json` files modified by rendering commands

**For JSON dashboards:**
- Reads pre-generated dashboard manifests from `./monitoring/dashboards/json/*.json`
- Validates and uploads these manifests directly to Grafana
- JSON dashboards must use Kubernetes-style manifest format (see usage examples)

The syntax of Go dashboards is described in the [dashboards-as-code](https://github.com/Unity-Technologies/dashboards-as-code/tree/master/docs) project.

### Inputs

| parameter              | description                                                                           | required | default                          |
| ---------------------- | ------------------------------------------------------------------------------------- | -------- | -------------------------------- |
| apply                  | Boolean to decide if the resources should be applied (true) or only dry-run (false).  | `false`  | `false`                          |
| dashboards_dir_go      | For testing only. The location of Go dashboard generation code.                       | `false`  | `monitoring/dashboards/go`       |
| dashboards_dir_json    | For testing only. The location of pre-generated JSON dashboard manifests.             | `false`  | `monitoring/dashboards/json`     |
| grafanactl_version     | grafanactl version to install. Used to validate and upload rendered dashboards.       | `false`  | `0.1.8`                          |

### Outputs

None.

### Usage Examples

#### Go Dashboards Only

```yaml
name: Grafana Dashboards As Code

on:
  workflow_dispatch:
  push:
    branches:
      - main
    paths:
      - "monitoring/dashboards/go/**"
  pull_request:
    paths:
      - "monitoring/dashboards/go/**"

jobs:
  dry-run:
    uses: Unity-Technologies/github-actions-workflows/.github/workflows/dashboards-as-code.yml@main

  apply:
    # Runs only on a push into the main branch or by triggering the workflow manually
    if: github.event_name == 'workflow_dispatch' || github.ref == 'refs/heads/main'
    uses: Unity-Technologies/github-actions-workflows/.github/workflows/dashboards-as-code.yml@main
    with:
      apply: true
```

#### JSON Dashboards Only

```yaml
name: Grafana Dashboards As Code

on:
  workflow_dispatch:
  push:
    branches:
      - main
    paths:
      - "monitoring/dashboards/json/**"
  pull_request:
    paths:
      - "monitoring/dashboards/json/**"

jobs:
  dry-run:
    uses: Unity-Technologies/github-actions-workflows/.github/workflows/dashboards-as-code.yml@main

  apply:
    if: github.event_name == 'workflow_dispatch' || github.ref == 'refs/heads/main'
    uses: Unity-Technologies/github-actions-workflows/.github/workflows/dashboards-as-code.yml@main
    with:
      apply: true
```

#### Both Go and JSON Dashboards

```yaml
name: Grafana Dashboards As Code

on:
  workflow_dispatch:
  push:
    branches:
      - main
    paths:
      - "monitoring/dashboards/**"
  pull_request:
    paths:
      - "monitoring/dashboards/**"

jobs:
  dry-run:
    uses: Unity-Technologies/github-actions-workflows/.github/workflows/dashboards-as-code.yml@main

  apply:
    if: github.event_name == 'workflow_dispatch' || github.ref == 'refs/heads/main'
    uses: Unity-Technologies/github-actions-workflows/.github/workflows/dashboards-as-code.yml@main
    with:
      apply: true
```

### Network Requirements

Requires `runs-on: [unity-linux-runner]` since it connects to Grafana and Vault on the internal network.

---

## Test Alerts

Composite action to write and run unit tests for [Duke](https://github.com/Unity-Technologies/duke) alerts using [promtool](https://prometheus.io/docs/prometheus/latest/configuration/unit_testing_rules/). Place tests under `monitoring/alerts/tests/tests.yaml`. Only `custom` alerts are supported.

Action [source code](https://github.com/Unity-Technologies/github-actions-workflows/blob/main/actions/test-alerts/action.yml).

### Inputs

| parameter         | description       | required | default                                                   |
| ----------------- | ----------------- | -------- | --------------------------------------------------------- |
| promtool_image    | Promtool image    | `false`  | `gcr.io/unity-ads-common-prd/mz-duke-alert-tester:master` |
| working_directory | Working directory | `false`  | `.`                                                       |

### Outputs

None.

### Usage Examples

```yaml
name: Test alerts

on:
  workflow_dispatch:
  pull_request:
    paths:
      - "monitoring.yaml"
      - "monitoring.yml"
      - "monitoring/**"
  push:
    paths:
      - "monitoring.yaml"
      - "monitoring.yml"
      - "monitoring/**"

jobs:
  test-alerts:
    name: Test Alerts
    runs-on: [unity-linux-runner]
    permissions: write-all
    steps:
      - name: Checkout
        uses: actions/checkout@v3
      - name: Test Alerts
        uses: Unity-Technologies/github-actions-workflows/actions/test-alerts@main
```

### Notes

- In your tests, reference a file called `all_alerts.yaml` (auto-generated from all existing alerts). Add `monitoring/alerts/tests/all_alerts.yaml` to `.gitignore`.
- To run tests locally: `docker run -i --rm -v ${PWD}:/app gcr.io/unity-ads-common-prd/mz-duke-alert-tester:master`
- Best used for complex alerts where you need confidence that they fire at the right time.

---

## Send Event to Loki

Composite action that sends a log event to Loki. By default, it sends to the PRE Loki instance.

Action [source code](https://github.com/Unity-Technologies/github-actions-workflows/blob/main/actions/send-event-to-loki/action.yml).

### Pre-requisites

- If using the default Loki endpoint (PRE Loki), the runner instance must have access to the shared VPC.

### Inputs

| parameter         | description                                                                           | required | default                                                               |
| ----------------- | ------------------------------------------------------------------------------------- | -------- | --------------------------------------------------------------------- |
| loki_push_url     | The url of the Loki instance                                                          | `false`  | `https://ingest-us-central1.kronus.corp.unity3d.com/loki/api/v1/push` |
| name              | The value of the name field in Loki                                                   | `false`  | `github_actions`                                                      |
| event_type        | The type of event that was sent to Loki                                               | `true`   |                                                                       |
| service           | The name of the service associated with this event (e.g. the name of the application) | `true`   |                                                                       |
| environment       | The environment of the loki event                                                     | `false`  | `global`                                                              |
| log_line          | The log line to send to Loki                                                          | `true`   |                                                                       |

### Outputs

None.

### Usage Examples

```yaml
name: 'my pipeline'

on:
  push:
  - main

jobs:
  deploy_stg:
    name: Deploy Staging
    runs-on: [unity-linux-runner]
    permissions: write-all
    needs: build
    # optional, deploy only on main branch
    if: github.ref == 'refs/heads/master' || github.ref == 'refs/heads/main'
    # optional
    environment: staging
    # optional
    concurrency: staging-${{ github.ref }}
    steps:
      - name: Checkout
        uses: actions/checkout@v3
      - name: Deploy
        uses: Unity-Technologies/github-actions-workflows/actions/deploy-with-common-chart@main
        with:
          # required
          helm_env: stg
          gke_cluster: unity-ads-gke-stg-usc1
          gke_project: unity-ads-gke-stg
          helm_release: my-service
          service_account: ci-deploy@unity-ads-common-prd.iam.gserviceaccount.com
      - name: Send Deploy Event
        if: always()
        id: loki
        uses: Unity-Technologies/github-actions-workflows/actions/send-event-to-loki@main
        with:
          # required
          event_type: 'deployment ${{ (steps.deployment.outcome == 'success') && "completed" || "deleted" }}'
          service: 'my-service'
          log_line: "Deployed: my-service:${GITHUB_SHA:0:10}"
          environment: stg
          # optional with default values
          name: github_actions
          loki_push_url: 'https://ingest-us-central1.kronus.corp.unity3d.com/loki/api/v1/push'
```

### Notes

- Use `if: always()` to ensure the event is sent even if previous steps fail.
- Align `event_type` and `environment` values with [what's currently present in Loki](https://grafana.internal.unity3d.com/explore?orgId=1&left=%7B%22datasource%22:%22mz-loki-deploy-annotations-prd%22,%22queries%22:%5B%7B%22refId%22:%22A%22,%22expr%22:%22%7B%7D%22,%22queryType%22:%22range%22,%22editorMode%22:%22builder%22%7D%5D,%22range%22:%7B%22from%22:%22now-1h%22,%22to%22:%22now%22%7D%7D).
- If you have dashboards generated by Duke with deployment annotations enabled, use the same service name as in your monitoring file.

---


## Shared Workflow Stats (Internal Instrumentation)

Composite action that records usage stats for a workflow. Results are stored in BigQuery. This is used internally by shared workflows to track adoption.

Action [source code](https://github.com/Unity-Technologies/github-actions-workflows/blob/main/actions/shared-workflow-stats).

### Inputs

| parameter          | description                                                                                                                                   | required | default |
| ------------------ | --------------------------------------------------------------------------------------------------------------------------------------------- | -------- | ------- |
| shared_workflow_id | The ID of the shared workflow that is running, make sure this is a unique ID as it will be used to track the adoption of this shared workflow | `false`  |         |

### Outputs

None.

### Usage Example

```yaml
name: Example workflow

on:
  workflow_dispatch:
    inputs:

jobs:
  my_job:
    name: My Job
    runs-on: [unity-linux-runner]
    permissions:
      id-token: write # This is required for requesting the JWT token
      contents: read  # This is required for actions/checkout
    steps:
      - name: Record Shared Workflow Stats
        uses: Unity-Technologies/github-actions-workflows/actions/shared-workflow-stats@main
        with:
          shared_workflow_id: my-shared-workflow # This should be a unique name of your shared workflow
```
