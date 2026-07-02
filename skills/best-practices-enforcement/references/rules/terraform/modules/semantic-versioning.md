# Module Semantic Versioning

Shared Terraform modules are libraries, and libraries need SemVer. Without it, consumers either pin to a commit SHA (frozen forever) or to `latest` (breaks unpredictably). With it, consumers pin to `~> X.Y` and get bugfixes safely.

Source: [Spacelift — Terraform Module Versioning](https://spacelift.io/blog/terraform-module-versioning), [SemVer 2.0.0](https://semver.org/).

---

## What Counts as a Breaking Change

A **MAJOR** version bump is required when any of the following change in a way that forces a consumer to edit their HCL or accept a destructive plan:

| Change | MAJOR? |
|---|---|
| Remove an input variable | **Yes** |
| Rename an input variable | **Yes** (alias-then-remove) |
| Remove an output | **Yes** |
| Rename an output | **Yes** |
| Change an input variable's `type` (e.g. `string` → `list(string)`) | **Yes** |
| Make a previously-optional variable required (remove `default`) | **Yes** |
| Bump minimum `required_version` (Terraform or a provider) | **Yes** |
| Change resource addresses in a way that requires `moved {}` blocks consumers can't write | **Yes** |
| Change a resource type (`google_compute_instance` → `_template`) | **Yes** |

A **MINOR** bump covers additive changes — new optional variable, new output, support for a new sub-feature.

A **PATCH** bump covers bug fixes that don't change the public interface.

---

## Releasing: Git Tags Drive Everything

Terraform's git-source addressing uses git tags. Release = push a `vX.Y.Z` tag.

```bash
# ✅ Good: tag a release
git tag -a v1.4.0 -m "Add private cluster support"
git push origin v1.4.0
```

Consumers pin with:

```hcl
# ✅ Good: consumer pins by tag (NOT by commit SHA)
module "gke" {
  source = "git::https://github.com/example/terraform-google-gke-cluster.git?ref=v1.4.0"
  # ...
}
```

Never publish a release by moving a tag (`git tag -f`). It silently breaks anyone who already resolved that ref. If you shipped a broken release, yank it with a higher patch:

```bash
# ✅ Good: ship a fix at v1.4.1 instead of moving v1.4.0
git tag -a v1.4.1 -m "Fix regression in v1.4.0 cluster name validation"
git push origin v1.4.1
# (optionally delete the broken release page on GitHub — but never delete the tag)
```

---

## CHANGELOG Is Mandatory

A `CHANGELOG.md` at the module root, [Keep-a-Changelog](https://keepachangelog.com/) style:

```markdown
# Changelog

## [1.4.0] - 2026-05-27

### Added
- `enable_private_endpoint` variable (default `false`) for fully-private clusters.

### Changed
- `node_count` default raised from `1` to `3`.

## [1.3.1] - 2026-05-12

### Fixed
- Output `cluster_endpoint` now correctly returns the private endpoint when
  `enable_private_endpoint = true`.

## [1.3.0] - 2026-05-01

### Added
- Initial Workload Identity support.
```

The CHANGELOG **is the contract**. Update it in the same PR as the code change; reviewers will catch missing entries.

---

## Deprecation Path for Removed Variables

A removal is a MAJOR bump. To minimise pain:

1. **Minor release (Y.+1.0):** add the new variable, mark the old as deprecated in `description`. Have both work; emit a console warning via `precondition` if the deprecated one is used.

   ```hcl
   variable "node_count" {
     type        = number
     description = "DEPRECATED: use node_count_per_zone. Will be removed in 2.0."
     default     = null
   }

   variable "node_count_per_zone" {
     type        = number
     description = "Number of nodes per zone."
     default     = 3
   }
   ```

2. **Major release (next major):** remove the deprecated variable. Document the migration in the CHANGELOG.

This gives consumers at least one minor cycle to migrate without blocking on a major bump.

---

## Pinning Recommendations for Consumers

| Pin form | Use case |
|---|---|
| `?ref=v1.4.0` | **Default** — pin to an exact tag; bump deliberately. |
| `?ref=main` | **Never in production** — every `terraform init` may pull a different commit. |
| `?ref=<sha>` | Reproducibility for forensics; harder to upgrade later than `?ref=vX.Y.Z`. |
| Registry `version = "~> 1.4"` | Registry-published modules — equivalent to pessimistic git pinning. |

The registry form (HashiCorp's public registry or a private one) supports `~> X.Y` semantics directly. Git-source modules require exact tags; bumping = a PR that changes the `?ref=`.

---

## Release Automation

Manual `git tag` works for low-volume modules. For higher-volume:

- **release-please** (Google) — drives version + CHANGELOG from Conventional Commits.
- **semantic-release** (Node ecosystem) — same idea, plugin-heavy.
- **GitHub Releases via workflow** — generate notes from PR labels.

Pick one per module and stick with it. Mixing manual + automated releases produces an inconsistent CHANGELOG.

---

## Anti-patterns

```hcl
# ❌ Bad: silently rename an input — every consumer's next plan breaks
# v1.0: variable "node_count" { ... }
# v1.1: variable "nodes_per_pool" { ... }   # MAJOR change, marked as MINOR
```

```bash
# ❌ Bad: move a tag to "fix" the release
git tag -f v1.4.0
git push -f origin v1.4.0
```

```hcl
# ❌ Bad: consumer pins to branch
module "gke" {
  source = "git::https://...?ref=main"  # roulette every init
}
```

---

## Related Rules

- [Module Structure](module-structure.md) — what a release contains.
- [Version Constraints](../language/version-constraints.md) — how consumers pin.

---

## References

- [Spacelift — Terraform Module Versioning](https://spacelift.io/blog/terraform-module-versioning)
- [SemVer 2.0.0](https://semver.org/)
- [Keep a Changelog](https://keepachangelog.com/en/1.1.0/)

<!-- Cross-platform: see AGENTS.md in the repository root for Cursor, Claude Code, and Copilot paths. -->
