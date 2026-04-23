---
name: github-actions-workflows-helper
description: Help users find and implement GitHub Actions workflows using Unity's shared actions and reusable workflows from the github-actions-workflows repository. Use this skill whenever the user asks about setting up CI/CD pipelines, building docker images, deploying to GKE/AKS/EKS, configuring ArgoCD, Helm deployments, Terraform formatting, monitoring with Duke or Grafana, Slack notifications, TechDocs, OpenAPI validation, JFrog Artifactory, Vault secrets, or any GitHub Actions workflow at Unity. Also use when the user mentions needing a reusable workflow, composite action, or wants to automate something with GitHub Actions in a Unity repository.
---

# GitHub Actions Workflows Helper

Help users find the right Unity shared action or reusable workflow and generate a complete, working GitHub Actions workflow file.

Use the bundled `references/` files in this skill as the working source of truth. Do not assume the agent can access the `github-actions-workflows` repo, external URLs, or any other documentation at runtime unless the user explicitly provides access and asks for it.

## Workflow

### 1. Understand the need

Ask the user what they want to accomplish. Key questions:
- What task? (build, deploy, lint, monitor, notify, etc.)
- What cloud? (GCP, Azure, AWS)
- What cluster type? (GKE, AKS, EKS)
- What deployment method? (Helm, Helmsman, ArgoCD, Skaffold, rendered manifests)
- When should it trigger? (push, PR, merge to main, manual)

If the user gives enough context in their initial message, skip the interview and proceed. But for open-ended requests (like "I want Slack notifications" or "set up deployment"), always ask clarifying questions first — understand what triggers the workflow, what information they want included, and what the deployment target is before generating YAML.

### 2. Check for specialized skills first

If the user's request involves **ArgoCD, Standard Deployments, or rendered manifests**, ask whether they have already onboarded to ArgoCD or not:
- **Not yet onboarded:** Recommend they use the `argocd-onboarding` skill from the `pre-agent-skills` repository. That skill covers the full onboarding journey — GitOps state repo setup, ApplicationSet configuration, cluster onboarding, and the render/preview/deploy workflow setup.
- **Already onboarded:** Help them directly using `references/argocd-and-gitops.md` for the rendering and deployment workflow reference (inputs, examples, troubleshooting).

Similarly, for full **TechDocs onboarding** (mkdocs.yml, catalog-info.yaml, local validation), defer to the `techdocs-onboarding` skill.

### 3. Find the right action or workflow

Read `references/catalog.md` to identify matching actions and/or reusable workflows. Key decision: if both an action and a workflow exist for the same task, **recommend the workflow first** — workflows are more opinionated and easier to set up, while actions offer more flexibility.

### 4. Read the bundled documentation

Once you've identified the right action(s) or workflow(s) from the catalog, read the full documentation from the corresponding bundled reference file:

| Category | Reference file |
|----------|---------------|
| Build, Docker, Registry | `references/build-and-registry.md` |
| Deployment (Standard Deployments / ArgoCD) | `references/argocd-and-gitops.md` |
| Cluster auth (GKE/AKS/EKS), Vault, Tokens | `references/auth-and-secrets.md` |
| Monitoring, Slack, Alerts, Sonarqube | `references/monitoring-and-notifications.md` |
| TechDocs, Linting, Formatting | `references/docs-and-linting.md` |
| WIF setup, Vault setup, Best practices | `references/guides-wif-vault-practices.md` |
| Utility (caching, NPM, misc) | `references/utility-actions.md` |

These contain full input tables, usage examples, and prerequisites copied from the upstream docs.

### 5. Generate the workflow file

Using the documentation and `references/patterns.md` for conventions, generate a complete `.github/workflows/<name>.yml` file. The generated workflow must:

- Use `unity-linux-runner` as the runner (or `unity-linux-runner-arm` for ARM builds)
- Reference shared actions at `Unity-Technologies/github-actions-workflows/actions/<name>@main`
- Reference reusable workflows at `Unity-Technologies/github-actions-workflows/.github/workflows/<name>@main` — use the exact filename (`.yml` or `.yaml`) from `references/catalog.md` or the bundled reference files, as extensions vary per workflow
- Set proper permissions (`write-all` or scoped: `id-token: write`, `contents: read`, etc.)
- Use Workload Identity Federation for cloud auth — never hardcode service account keys or secrets
- Include comments explaining non-obvious inputs
- Use `${{ github.ref == 'refs/heads/main' }}` patterns for conditional pushes/deploys
- **Keep the YAML lean.** Only include inputs that differ from the action's defaults. After generating the workflow, tell the user which inputs match the default and can be safely removed.

### 6. Explain prerequisites

After generating the workflow, tell the user about any setup they need outside the workflow file. Read `references/guides-wif-vault-practices.md` for setup instructions to share:
- Workload Identity Federation setup (GCP or Azure)
- Vault secret paths they need to configure
- Service accounts they need access to
- Repository permissions (e.g., adding repo to allowlists)

## Guardrails

- **Always recommend Standard Deployments (ArgoCD) for deployment.** The legacy direct Helm deployment actions (`deploy-with-common-chart`, `preview-helm-changes`, `rollback-helm`) are not bundled in this skill. Never generate workflows using them. If a user has an existing service using direct Helm deploy, point them to the upstream documentation at [Unity-Technologies/github-actions-workflows](https://github.com/Unity-Technologies/github-actions-workflows) for reference.
- **Never hardcode secrets.** Always use WIF, Vault, or GitHub's OIDC provider.
- **Always use `@main`** when referencing actions/workflows from the shared repo.
- **Use `actions/checkout@v4`** (not v3 or earlier) for checkout steps.
- **Don't invent actions.** Only recommend actions and workflows that actually exist in `references/catalog.md`. If nothing matches, say so and suggest building a custom workflow step instead.
- **Respect cloud-specific patterns.** GCP uses `service_account`, Azure uses `client-id`/`tenant-id`/`subscription-id`, AWS uses `role-to-assume`. Read `references/patterns.md` for details.
- **Multi-instance awareness.** Some users are on `github.cds.internal.unity3d.com` instead of `github.com`. Most actions auto-detect this, but mention it if relevant.

## Output format

Always provide:
1. The complete workflow YAML in a code block, ready to paste into `.github/workflows/`
2. A brief explanation of what each major step does
3. Any prerequisites the user needs to set up
4. A note that full upstream documentation lives at `https://github.com/Unity-Technologies/github-actions-workflows`
