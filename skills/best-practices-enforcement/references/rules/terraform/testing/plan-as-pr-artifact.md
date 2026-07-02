# Plan as PR Artifact

Two things must be true of every production Terraform change:

1. The **plan** the reviewer approved is the plan that gets **applied**.
2. The plan output is **visible in the PR** (not buried in a CI log).

The mechanism is: `terraform plan -out=plan.tfplan` produces a binary plan file. CI uploads it as a PR artifact and renders the human-readable summary in a PR comment. After review/approval, `terraform apply plan.tfplan` applies **that exact file** — no re-plan, no drift between approval and apply.

This is the workflow Atlantis, Spacelift, env0, and HCP Terraform all implement. If you're rolling your own, copy their shape.

Source: [GCP Terraform — Operations](https://docs.cloud.google.com/docs/terraform/best-practices/operations), [Atlantis docs](https://www.runatlantis.io/docs/).

---

## ✅ Good: The Pipeline Shape

```yaml
# .github/workflows/terraform-pr.yml
on:
  pull_request:
    paths: ['environments/prd/**']

jobs:
  plan:
    runs-on: ubuntu-latest
    permissions: { id-token: write, contents: read, pull-requests: write }
    steps:
      - uses: actions/checkout@v4
      - uses: google-github-actions/auth@v2
        with:
          workload_identity_provider: ${{ vars.WIF_PROVIDER }}
          service_account: ${{ vars.TF_CI_SA }}
      - uses: hashicorp/setup-terraform@v3

      - run: terraform init
      - run: terraform plan -out=plan.tfplan -input=false -no-color | tee plan.txt

      - uses: actions/upload-artifact@v4
        with:
          name: plan-${{ github.run_id }}
          path: plan.tfplan
          retention-days: 14

      - name: Post plan as PR comment
        uses: actions/github-script@v7
        with:
          script: |
            const fs = require('fs');
            const plan = fs.readFileSync('plan.txt', 'utf8');
            github.rest.issues.createComment({
              owner: context.repo.owner,
              repo: context.repo.repo,
              issue_number: context.issue.number,
              body: '```\n' + plan.slice(0, 60000) + '\n```'
            });

  apply:
    needs: plan
    runs-on: ubuntu-latest
    environment: production  # GitHub Environment with manual approval gate
    if: github.event.pull_request.merged == true
    steps:
      - uses: actions/checkout@v4
      - uses: actions/download-artifact@v4
        with:
          name: plan-${{ github.event.pull_request.number }}
      - run: terraform init
      - run: terraform apply -input=false plan.tfplan
```

Key properties of this shape:

- **`-out=plan.tfplan`** — produces the binary plan file (not just text output).
- **Artifact retention** ≥ time-to-merge — if a PR sits a week, the plan must still be on disk.
- **PR comment** with the rendered plan — reviewers see exactly what will change without digging into CI logs.
- **`apply plan.tfplan`** — applies the exact reviewed plan; cannot diverge from approval.
- **GitHub Environment gate** (or equivalent in your CI) — adds a manual approval step before apply.

---

## ❌ Bad: Re-Plan-Then-Apply

```yaml
# ❌ Bad: pipeline plans twice — once for review, once for apply
- run: terraform plan        # for PR review
# ... merge ...
- run: terraform apply -auto-approve  # second plan happens internally
```

Symptom: PR review shows "add 3 resources, change 1, destroy 0". By the time the merge runs apply, a teammate has applied something else; the second plan now shows "add 3, change 5, destroy 2". The apply proceeds because `-auto-approve` doesn't ask.

Always apply the **saved binary plan**. If state has drifted, `apply plan.tfplan` fails with `Saved plan is stale` — exactly the right behavior (force a fresh plan + re-review).

---

## What Goes in the PR Comment

Reviewers should not have to click through to CI to see the diff. Render at minimum:

- `terraform plan` output (truncated to the comment size limit if needed).
- A summary line: `Plan: 3 to add, 1 to change, 0 to destroy.`
- The root module path (when multiple roots are affected by one PR).
- A link to the full artifact for plans that exceed the comment limit.

Format hints:

- Use a fenced code block — markdown will render the colours otherwise inconsistently.
- Strip ANSI escape codes (`-no-color`) before posting.
- For very large plans, post just the summary + a link to the artifact.

---

## Multi-Root PRs

When one PR touches multiple root modules (e.g. `network/` + `workload/`), run one plan per root and post one comment per root:

```yaml
strategy:
  matrix:
    root:
      - environments/prd/00-network
      - environments/prd/20-workload
steps:
  - run: terraform -chdir=${{ matrix.root }} plan -out=plan.tfplan
  # ... upload + comment per root
```

Each comment makes it clear *which* root is changing. A blanket "here are 6 changes" comment hides cross-root issues.

---

## Apply Triggers

There are two reasonable patterns; pick one per repo and stick with it:

| Pattern | Trigger | Rollback |
|---|---|---|
| **Apply on merge** (recommended) | Merge to `main` triggers apply with the saved plan | Revert the merge commit + re-run pipeline |
| **Apply via PR comment** (Atlantis style) | Reviewer comments `atlantis apply` on the PR; merge happens after | Roll back via fresh PR + apply |

"Apply on merge" matches GitHub's mental model. "Apply via comment" matches Atlantis users' muscle memory. Don't mix.

---

## Drift Between Plan and Apply

If `apply plan.tfplan` fails with `Saved plan is stale`:

1. **Don't force.** There is no `--ignore-stale` flag, and good — the message means another change landed.
2. Re-plan in a fresh PR (or a re-run of the same PR after rebase).
3. Re-request review (the diff may be different now).

The discipline costs ~10 minutes per drift; the alternative — applying an out-of-date plan — costs incident response.

---

## Per-Environment Approval

The GitHub Environment (or equivalent) approval gate gives you per-target control:

```yaml
# In repo settings: Environments → production → Required reviewers
```

- `dev` / `stg` environments: auto-apply on merge.
- `prd` environment: require one or two human approvers before apply runs.

This is the cheapest possible "two-key launch" for prod.

---

## What About `terraform plan -refresh-only`?

`-refresh-only` mode produces a plan that only updates state to match reality (no resource changes). It's useful for drift detection, **not** for production change flow. Don't conflate the two.

See `meta/drift-detection-strategy.md` for the drift workflow.

---

## Anti-patterns

```yaml
# ❌ Bad: apply on every commit to a feature branch
on: push
jobs:
  apply:
    run: terraform apply -auto-approve
```

Bypasses review. Bypasses approval. Will eventually drop production.

```yaml
# ❌ Bad: don't save the plan file — re-plan on apply
- run: terraform plan
- run: terraform apply -auto-approve
```

The "second plan" is now what runs — the review was on a plan that no longer exists.

---

## Related Rules

- [Root Module Blast Radius](../modules/root-module-blast-radius.md) — multiple roots = multiple plans = multiple PR comments.
- [`terraform test` vs Terratest](terraform-test-vs-terratest.md) — runs *before* plan in the pipeline; saved plan is the gate to apply.
- [Workload Identity Federation](../gcp/workload-identity-federation.md) — the auth the apply step uses.

---

## References

- [GCP Terraform — Operations](https://docs.cloud.google.com/docs/terraform/best-practices/operations)
- [Atlantis — Custom Workflows](https://www.runatlantis.io/docs/custom-workflows.html)
- [Terraform — Saved Plans](https://developer.hashicorp.com/terraform/cli/commands/plan#_out_filename)

<!-- Cross-platform: see AGENTS.md in the repository root for Cursor, Claude Code, and Copilot paths. -->
