# `govulncheck` in CI

`govulncheck` (from the Go team) reports known vulnerabilities in the modules
**and the specific symbols** your binary actually reaches. It's listed as one
of the six security best practices for Go projects.

Source: [Go Security Best Practices](https://go.dev/doc/security/best-practices).

---

## Make it a required gate, not advisory

If a vulnerability is reachable from your code, the build should fail. If you
only "log and continue", `govulncheck` adds noise and protects nothing.

```yaml
# ✅ Good: required job in CI
- name: govulncheck
  run: |
    go install golang.org/x/vuln/cmd/govulncheck@latest
    govulncheck ./...
```

Non-zero exit means a **reachable** vulnerability — i.e. the vulnerable symbol
is actually called from your code, not just present in `go.mod`. That signal
is high quality; honor it.

---

## Pair it with the other four Go security gates

`govulncheck` is one of a set. Run them together so an incident isn't blocked
on debating which one to wire up first.

```yaml
- run: go vet ./...
- run: go test -race ./...
- run: go test -fuzz=. -fuzztime=30s ./...  # on targeted packages
- run: govulncheck ./...
```

`go vet` catches stdlib-flagged bugs, `-race` catches data races,
`-fuzz` finds edge cases, `govulncheck` catches known CVEs. None of them
substitute for the others.

---

## Pin a version; don't auto-update silently

A "latest" install in CI means a new govulncheck release can break your build
without a code change.

```yaml
# ✅ Good: explicit version
- run: go install golang.org/x/vuln/cmd/govulncheck@v1.1.4

# ❌ Bad: implicit latest
- run: go install golang.org/x/vuln/cmd/govulncheck@latest
```

Bump the pin like any other dependency.

---

## Triage workflow when it fails

When `govulncheck` reports a finding:

1. **Read the call stack it prints.** It shows exactly *how* your code reaches
   the vulnerable symbol — you don't need to guess. If the only callers are
   under `_test.go`, it's still a real signal for test infra but lower urgency.
2. **Check `go.mod`.** Often the fix is `go get module@fixed-version`.
3. **If no fix exists upstream**, document the exception (issue link, why
   accepted) and use `// govulncheck:ignore` style comments only if your team
   has agreed on a suppression policy. Prefer "vendor a patch" over silent
   suppression for production services.
4. **Re-run after the upgrade** to confirm the call stack is gone.

---

## Don't run it on `vendor/` if you don't ship `vendor/`

`govulncheck` defaults to scanning your module graph. If your repo has a
`vendor/` directory only for offline builds, scan the module graph (the
default), not the vendored copies — they may diverge from `go.sum`.

---

## Run it locally too — not only in CI

A pre-PR local run avoids the "PR-bounced-by-CI" loop:

```bash
# ✅ Good: same command as CI
govulncheck ./...

# Optional: only print symbols (faster, less noisy)
govulncheck -mode=symbol ./...
```

Wire it into your repo's `make ci` / `make lint` target so it's one keystroke.

---

## What `govulncheck` does NOT cover

- **Container/base-image CVEs** — use Trivy/Grype on the image.
- **JS or other non-Go dependencies** — separate scanners.
- **Logic bugs you wrote** — that's `go vet`, lint, code review.
- **Vulnerabilities in private modules** without public advisories — they
  simply aren't in the Go vulnerability DB.

---

## Related rules

- [Mocking and Integration](../testing/mocking-and-integration.md) — fuzz testing pairs with govulncheck for security coverage.
- [Go Production Patterns](../meta/go-production-patterns.md) — production readiness checklist.

---

## References

- [Go Security Best Practices](https://go.dev/doc/security/best-practices)
- [govulncheck command](https://pkg.go.dev/golang.org/x/vuln/cmd/govulncheck)
- [Go Vulnerability Database](https://pkg.go.dev/vuln/)

<!-- Cross-platform: see AGENTS.md in the repository root for deployment details. -->
