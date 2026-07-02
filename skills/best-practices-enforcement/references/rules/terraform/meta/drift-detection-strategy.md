# Drift Detection Strategy

**Drift** is the difference between Terraform's state and what's actually deployed. It happens when someone clicks in the console, a script runs a CLI command, an autoscaler resizes something — anything that mutates infra outside the Terraform pipeline. Without active detection, drift accumulates silently until the next `terraform apply` blows up.

Source: [env0 — Drift detection tools 2026](https://www.env0.com/blog/8-terraform-drift-detection-tools-enterprise-teams-actually-use-in-2026).

---

## What Changed: driftctl Is in Maintenance

[driftctl](https://github.com/snyk/driftctl) was the OSS drift-detection standard from 2020-2023. Snyk acquired and then mothballed it — last meaningful release June 2023, with no plans to resume.

Migrating from driftctl is now table stakes. The replacement options below are all actively maintained as of 2026.

---

## The Three Tiers

### Tier 1: Baseline — Scheduled `terraform plan` Runs

The cheapest and most reliable drift detection is **scheduling `terraform plan -refresh-only` on a cron** and posting any non-empty result to Slack/PagerDuty.

```yaml
# .github/workflows/drift-detection.yml
on:
  schedule:
    - cron: '0 7 * * 1-5'  # weekday mornings

jobs:
  drift:
    runs-on: ubuntu-latest
    strategy:
      matrix:
        root:
          - environments/prd/00-network
          - environments/prd/10-data-platform
          - environments/prd/20-workload
    steps:
      - uses: actions/checkout@v4
      - uses: google-github-actions/auth@v2
        with:
          workload_identity_provider: ${{ vars.WIF_PROVIDER }}
          service_account: ${{ vars.TF_CI_SA }}
      - uses: hashicorp/setup-terraform@v3

      - run: terraform -chdir=${{ matrix.root }} init
      - id: plan
        run: |
          terraform -chdir=${{ matrix.root }} plan -refresh-only -detailed-exitcode -no-color > plan.txt 2>&1 || EXIT=$?
          echo "exit_code=${EXIT:-0}" >> $GITHUB_OUTPUT
        continue-on-error: true

      - name: Alert on drift
        if: steps.plan.outputs.exit_code == '2'
        run: |
          # exit code 2 = changes detected
          # post plan.txt to Slack with the root name
```

**`-detailed-exitcode`**: returns `0` for no changes, `1` for error, `2` for changes detected. The cron job alerts only on `2`.

**`-refresh-only`**: updates state to match reality without proposing infrastructure changes. Catches drift without proposing a destructive fix.

This baseline costs ~0 cloud spend (only API list calls), runs in minutes, and catches the vast majority of drift early.

### Tier 2: TACO Platforms (Managed)

A "TACO" (Terraform Automation and COllaboration) platform — Spacelift, env0, HCP Terraform Plus, Scalr — bundles drift detection with the rest of the deployment pipeline:

| Platform | Drift feature |
|---|---|
| **Spacelift** | Built-in drift detection per stack, scheduled scans, auto-remediation policies |
| **env0** | Drift detection per environment, configurable cadence |
| **HCP Terraform Plus** | Drift detection per workspace; tier-gated |
| **Scalr** | Drift detection + custom reconciliation hooks |

Trade-off: subscription cost, vendor lock-in for the rest of the pipeline, but no infrastructure to run yourself.

Use when:

- You're already on (or evaluating) a TACO platform — adding drift detection is a checkbox.
- The team has no capacity to run a self-hosted scheduler.

### Tier 3: Self-Hosted Tools (OSS)

| Tool | Notes |
|---|---|
| **[cloud-concierge](https://github.com/dragondrop-cloud/cloud-concierge)** | Active OSS successor; supports multi-cloud, generates Terraform from drifted resources for adoption |
| **[Cycloid InfraMap](https://github.com/cycloidio/inframap)** | Visualises state vs reality |
| Custom — `terraform plan -refresh-only` in a scheduler | The Tier 1 baseline, made fancier |

Use when:

- You want OSS and have the bandwidth to operate it.
- You need features no TACO offers (e.g. multi-cloud drift correlation).

**Do NOT pick:**

- **driftctl** — in maintenance, see above.
- **Hand-rolled `terraform show -json` diffing** — possible, but you'll spend weeks reproducing what cloud-concierge gives you for free.

---

## How to Triage Drift

When a drift alert fires:

1. **Identify what changed.** The plan output is usually clear: "X attribute changed from A to B".
2. **Find who/what changed it.** Check cloud audit logs (Cloud Audit Logs / CloudTrail) for the resource. Was it a human, a script, an autoscaler?
3. **Decide:**
   - **Accept the drift** — the change was correct. Update Terraform to match: `terraform apply -refresh-only` to bring state in line, then update HCL.
   - **Reject the drift** — the change was wrong. Re-apply Terraform to overwrite: `terraform apply`.
   - **Tolerate the drift** — the change is intentional but Terraform shouldn't manage that attribute. Move it to `lifecycle { ignore_changes = [...] }`.

```hcl
# ✅ Good: ignore an attribute that's managed elsewhere (e.g. by autoscaler)
resource "google_compute_instance_group_manager" "web" {
  # ...

  lifecycle {
    ignore_changes = [
      target_size,  # autoscaler manages this; don't fight it
    ]
  }
}
```

---

## Recurring Drift = Process Bug

If the same resource drifts every week:

- Someone has a habit of clicking in the console — disable console access for that role, or add the attribute to `ignore_changes`.
- An automation outside Terraform is writing to the resource — either bring it under Terraform's control, or `ignore_changes` the attribute it touches.
- The provider has a bug where a default keeps re-reading differently — file an issue; pin to a version that's stable.

Tolerating recurring drift erodes the team's trust in the pipeline. Fix the source.

---

## What `-refresh-only` Doesn't Catch

`terraform plan -refresh-only` walks every managed resource and reads its current state. It misses:

- **Untracked resources** — anything created outside Terraform entirely. cloud-concierge and the TACOs detect these; vanilla `plan` does not.
- **Resources Terraform doesn't read fully** — some providers fetch only a subset of attributes; rare, but happens.
- **Mid-flight changes** — drift that appears and disappears between cron runs.

For comprehensive coverage (including untracked resources), you need cloud-concierge or a TACO.

---

## Cadence

| Estate criticality | Cadence |
|---|---|
| Production | Daily, weekday mornings |
| Staging | Weekly |
| Dev | None (drift in dev is acceptable; don't alert-fatigue the team) |

Avoid hourly drift detection unless you have a specific compliance requirement. The cost (API calls + alert noise) outweighs the benefit.

---

## Related Rules

- [Plan as PR Artifact](../testing/plan-as-pr-artifact.md) — same `terraform plan`, different trigger (PR vs cron).
- [Secrets and State](../security/secrets-and-state.md) — drift detection requires read access to state; tighten the bucket IAM accordingly.
- [Root Module Blast Radius](../modules/root-module-blast-radius.md) — scheduled drift detection is per-root; smaller roots → faster, more targeted alerts.

---

## References

- [env0 — Drift detection tools enterprise teams actually use in 2026](https://www.env0.com/blog/8-terraform-drift-detection-tools-enterprise-teams-actually-use-in-2026)
- [cloud-concierge](https://github.com/dragondrop-cloud/cloud-concierge)
- [Terraform — `plan -refresh-only`](https://developer.hashicorp.com/terraform/cli/commands/plan#planning-modes)
- [driftctl (maintenance)](https://github.com/snyk/driftctl)

<!-- Cross-platform: see AGENTS.md in the repository root for deployment details. -->
