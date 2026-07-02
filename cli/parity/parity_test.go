// Package parity asserts that the acr binary produces the same filesystem
// effects as the original shell scripts. It runs the real *.sh (baseline) and
// acr (candidate) against identical fixtures in separate temp repos and diffs
// the resulting trees: symlink targets (resolved), file contents, JSON
// (semantically), and .gitignore ignore patterns.
//
// These tests are the gate that must pass before any .sh is deleted. They skip
// gracefully when bash/jq/python3/git or the scripts are unavailable.
package parity

import (
	"encoding/json"
	"os"
	"os/exec"
	"path/filepath"
	"reflect"
	"runtime"
	"sort"
	"strings"
	"testing"
)

var (
	repoRoot string // worktree root that holds (or held) the .sh scripts
	acrBin   string // built acr binary (empty when scripts are absent)
)

func TestMain(m *testing.M) {
	// Resolve paths relative to THIS test file, not by climbing the filesystem
	// for sync-rules.sh — climbing wrongly escapes into a parent checkout once
	// the scripts are deleted here. cliDir is the module under test; repoRoot is
	// its parent (the worktree root where the original scripts live).
	cliDir := moduleDir()
	repoRoot = filepath.Dir(cliDir)

	// If the original scripts are gone (deleted post-migration), there is no
	// baseline to diff against: skip the whole package cleanly. Recover the
	// scripts from git history to re-run parity.
	if _, err := os.Stat(filepath.Join(repoRoot, "sync-rules.sh")); err != nil {
		repoRoot = ""
		os.Exit(m.Run())
	}

	bin := filepath.Join(os.TempDir(), "acr-parity-bin")
	build := exec.Command("go", "build", "-o", bin, ".")
	build.Dir = cliDir
	if out, err := build.CombinedOutput(); err != nil {
		println("failed to build acr:", string(out))
		os.Exit(1)
	}
	acrBin = bin
	code := m.Run()
	_ = os.Remove(bin)
	os.Exit(code)
}

// moduleDir returns the cli/ directory (parent of this parity package),
// resolved from the test file's own path so it is independent of cwd and of
// any parent checkout.
func moduleDir() string {
	_, file, _, _ := runtime.Caller(0) // .../cli/parity/parity_test.go
	return filepath.Dir(filepath.Dir(file))
}

func requireTools(t *testing.T) {
	t.Helper()
	if repoRoot == "" {
		t.Skip("original shell scripts not present (deleted post-migration); recover from git history to run parity")
	}
	for _, tool := range []string{"bash", "jq", "python3", "git"} {
		if _, err := exec.LookPath(tool); err != nil {
			t.Skipf("%s not available", tool)
		}
	}
}

const skillGroupsYAML = `defaults: all
exclude_from_defaults: scala

agent_groups:
  core:
    - arch

groups:
  core:
    - alpha
  scala:
    - scala-thing
`

const hooksJSON = `{
  "hooks": {
    "SessionStart": [
      {
        "matcher": "startup",
        "hooks": [
          {"type": "command", "command": "${CLAUDE_PLUGIN_ROOT}/hooks/session-start.sh", "async": false}
        ]
      }
    ]
  }
}
`

// buildSource creates a minimal nitays-agent-toolkit checkout fixture and copies the
// real sync-rules.sh into it so the bash baseline runs the actual script.
func buildSource(t *testing.T) string {
	t.Helper()
	src := t.TempDir()
	write := func(rel, content string) {
		p := filepath.Join(src, rel)
		if err := os.MkdirAll(filepath.Dir(p), 0o755); err != nil {
			t.Fatal(err)
		}
		if err := os.WriteFile(p, []byte(content), 0o644); err != nil {
			t.Fatal(err)
		}
	}
	write("config/skill-groups.yaml", skillGroupsYAML)
	write("skills/alpha/SKILL.md", "# alpha\n")
	write("skills/beta/SKILL.md", "# beta\n")
	write("skills/scala-thing/SKILL.md", "# scala\n")
	write("agents/arch.md", "# arch agent\n")
	write("agents/README.md", "# readme\n")
	write("commands/cmd1.md", "# command one\n")
	write("commands/README.md", "# readme\n")
	write("hooks/session-start", "#!/bin/bash\necho start\n")
	write("hooks/session-start.sh", "#!/bin/bash\necho start\n")
	write("hooks/quality/fmt.sh", "#!/bin/bash\necho fmt\n")
	write("hooks/ecc-hooks/skip.sh", "#!/bin/bash\necho skip\n")
	write("hooks/hooks.json", hooksJSON)

	// Copy the real sync-rules.sh so SCRIPT_DIR resolves to this fixture.
	data, err := os.ReadFile(filepath.Join(repoRoot, "sync-rules.sh"))
	if err != nil {
		t.Fatal(err)
	}
	if err := os.WriteFile(filepath.Join(src, "sync-rules.sh"), data, 0o755); err != nil {
		t.Fatal(err)
	}
	return src
}

func runBashSync(t *testing.T, src, repo string, args ...string) {
	t.Helper()
	full := append([]string{filepath.Join(src, "sync-rules.sh")}, args...)
	cmd := exec.Command("bash", full...)
	cmd.Dir = repo
	cmd.Env = append(os.Environ(), "REPO_ROOT="+repo, "NO_COLOR=1")
	if out, err := cmd.CombinedOutput(); err != nil {
		t.Fatalf("bash sync failed: %v\n%s", err, out)
	}
}

func runAcrSync(t *testing.T, src, repo string, args ...string) {
	t.Helper()
	full := append([]string{"sync", "--repo-root", repo, "--source", src}, args...)
	cmd := exec.Command(acrBin, full...)
	cmd.Dir = repo
	cmd.Env = append(os.Environ(), "NO_COLOR=1")
	if out, err := cmd.CombinedOutput(); err != nil {
		t.Fatalf("acr sync failed: %v\n%s", err, out)
	}
}

// entry captures the comparable shape of a tree node.
type entry struct {
	kind string // "dir" | "symlink" | "file"
}

func scanTree(t *testing.T, root string) map[string]entry {
	t.Helper()
	out := map[string]entry{}
	err := filepath.Walk(root, func(p string, info os.FileInfo, err error) error {
		if err != nil {
			return err
		}
		rel, err := filepath.Rel(root, p)
		if err != nil {
			return err
		}
		if rel == "." {
			return nil
		}
		switch {
		case info.Mode()&os.ModeSymlink != 0:
			out[rel] = entry{kind: "symlink"}
		case info.IsDir():
			out[rel] = entry{kind: "dir"}
		default:
			out[rel] = entry{kind: "file"}
		}
		return nil
	})
	if err != nil {
		t.Fatalf("scan %s: %v", root, err)
	}
	return out
}

// compareTrees asserts the two repos have identical effects.
func compareTrees(t *testing.T, bashRepo, goRepo string) {
	t.Helper()
	bash := scanTree(t, bashRepo)
	go_ := scanTree(t, goRepo)

	for rel := range bash {
		if _, ok := go_[rel]; !ok {
			t.Errorf("entry present in bash but missing in go: %s (%s)", rel, bash[rel].kind)
		}
	}
	for rel := range go_ {
		if _, ok := bash[rel]; !ok {
			t.Errorf("entry present in go but missing in bash: %s (%s)", rel, go_[rel].kind)
		}
	}

	for rel, be := range bash {
		ge, ok := go_[rel]
		if !ok {
			continue
		}
		if be.kind != ge.kind {
			t.Errorf("%s: kind mismatch bash=%s go=%s", rel, be.kind, ge.kind)
			continue
		}
		bp := filepath.Join(bashRepo, rel)
		gp := filepath.Join(goRepo, rel)
		switch be.kind {
		case "symlink":
			compareSymlink(t, rel, bp, gp)
		case "file":
			compareFile(t, rel, bp, gp)
		}
	}
}

func compareSymlink(t *testing.T, rel, bp, gp string) {
	t.Helper()
	br, err1 := filepath.EvalSymlinks(bp)
	gr, err2 := filepath.EvalSymlinks(gp)
	if err1 != nil || err2 != nil {
		t.Errorf("%s: could not resolve symlinks (bash=%v go=%v)", rel, err1, err2)
		return
	}
	if br != gr {
		t.Errorf("%s: symlink resolves differently\n bash -> %s\n go   -> %s", rel, br, gr)
	}
}

func compareFile(t *testing.T, rel, bp, gp string) {
	t.Helper()
	base := filepath.Base(rel)
	switch {
	case base == ".gitignore":
		if b, g := ignoreLines(t, bp), ignoreLines(t, gp); !reflect.DeepEqual(b, g) {
			t.Errorf("%s: ignore patterns differ\n bash=%v\n go  =%v", rel, b, g)
		}
	case strings.HasSuffix(base, ".json"):
		if b, g := loadJSON(t, bp), loadJSON(t, gp); !reflect.DeepEqual(b, g) {
			t.Errorf("%s: JSON differs\n bash=%v\n go  =%v", rel, b, g)
		}
	default:
		bb, _ := os.ReadFile(bp)
		gb, _ := os.ReadFile(gp)
		if string(bb) != string(gb) {
			t.Errorf("%s: file contents differ\n bash=%q\n go  =%q", rel, bb, gb)
		}
	}
}

// ignoreLines returns the sorted set of functional (non-comment, non-blank)
// .gitignore lines — the patterns that matter, ignoring comment wording.
func ignoreLines(t *testing.T, path string) []string {
	t.Helper()
	data, err := os.ReadFile(path)
	if err != nil {
		t.Fatalf("read %s: %v", path, err)
	}
	var out []string
	for _, ln := range strings.Split(string(data), "\n") {
		ln = strings.TrimSpace(ln)
		if ln == "" || strings.HasPrefix(ln, "#") {
			continue
		}
		out = append(out, ln)
	}
	sort.Strings(out)
	return out
}

func loadJSON(t *testing.T, path string) any {
	t.Helper()
	data, err := os.ReadFile(path)
	if err != nil {
		t.Fatalf("read %s: %v", path, err)
	}
	var v any
	if err := json.Unmarshal(data, &v); err != nil {
		t.Fatalf("parse %s: %v", path, err)
	}
	return v
}

// --- scenarios ---

func TestSyncParity(t *testing.T) {
	requireTools(t)
	scenarios := []struct {
		name string
		args []string
	}{
		{"claude_symlink", []string{"--target", "claude", "--force"}},
		{"claude_copy", []string{"--target", "claude", "--force", "--copy"}},
		{"skills_all", []string{"--target", "claude", "--force", "--skills", "all"}},
		{"skills_core", []string{"--target", "claude", "--force", "--skills", "core"}},
	}
	for _, sc := range scenarios {
		sc := sc
		t.Run(sc.name, func(t *testing.T) {
			src := buildSource(t)
			bashRepo := t.TempDir()
			goRepo := t.TempDir()
			runBashSync(t, src, bashRepo, sc.args...)
			runAcrSync(t, src, goRepo, sc.args...)
			compareTrees(t, bashRepo, goRepo)
		})
	}
}

func TestLinkParity(t *testing.T) {
	requireTools(t)
	// The "source" is the checkout being linked into projects; copy the real
	// link-to-project.sh so the bash baseline runs it with SCRIPT_DIR == source.
	src := t.TempDir()
	data, err := os.ReadFile(filepath.Join(repoRoot, "link-to-project.sh"))
	if err != nil {
		t.Fatal(err)
	}
	if err := os.WriteFile(filepath.Join(src, "link-to-project.sh"), data, 0o755); err != nil {
		t.Fatal(err)
	}

	bashProj := t.TempDir()
	goProj := t.TempDir()

	bash := exec.Command("bash", filepath.Join(src, "link-to-project.sh"), bashProj)
	bash.Env = append(os.Environ(), "NO_COLOR=1")
	if out, err := bash.CombinedOutput(); err != nil {
		t.Fatalf("bash link failed: %v\n%s", err, out)
	}
	acr := exec.Command(acrBin, "link", goProj, "--source", src)
	acr.Env = append(os.Environ(), "NO_COLOR=1")
	if out, err := acr.CombinedOutput(); err != nil {
		t.Fatalf("acr link failed: %v\n%s", err, out)
	}
	// Both create the .cursor/rules/shared symlink to src.
	compareTrees(t, bashProj, goProj)
}

// TestInstallFromRepoParity exercises the RUNNING_FROM_REPO fast path: invoked
// inside an nitays-agent-toolkit checkout, install just runs a sync (no submodule, no
// hook). Symlinks here are repo-relative, so they are compared by raw target.
func TestInstallFromRepoParity(t *testing.T) {
	requireTools(t)
	bashRepo := buildRepoFixture(t)
	goRepo := buildRepoFixture(t)

	bash := exec.Command("bash", filepath.Join(bashRepo, "install.sh"), "--target", "claude")
	bash.Dir = bashRepo
	bash.Env = append(os.Environ(), "NO_COLOR=1")
	if out, err := bash.CombinedOutput(); err != nil {
		t.Fatalf("bash install failed: %v\n%s", err, out)
	}
	acr := exec.Command(acrBin, "install", "--target", "claude")
	acr.Dir = goRepo
	acr.Env = append(os.Environ(), "NO_COLOR=1")
	if out, err := acr.CombinedOutput(); err != nil {
		t.Fatalf("acr install failed: %v\n%s", err, out)
	}

	// Compare only the generated artifacts; symlinks are repo-relative so match
	// on the raw target string.
	keep := func(rel string) bool {
		top := strings.SplitN(rel, string(filepath.Separator), 2)[0]
		return top == ".claude" || rel == ".gitignore"
	}
	compareGenerated(t, bashRepo, goRepo, keep)
}

func buildRepoFixture(t *testing.T) string {
	t.Helper()
	src := buildSource(t)
	// Promote the fixture into a full checkout: add install.sh and a git dir so
	// detect_repo_root / RUNNING_FROM_REPO succeed.
	data, err := os.ReadFile(filepath.Join(repoRoot, "install.sh"))
	if err != nil {
		t.Fatal(err)
	}
	if err := os.WriteFile(filepath.Join(src, "install.sh"), data, 0o755); err != nil {
		t.Fatal(err)
	}
	init := exec.Command("git", "init", "-q")
	init.Dir = src
	if out, err := init.CombinedOutput(); err != nil {
		t.Fatalf("git init: %v\n%s", err, out)
	}
	return src
}

// compareGenerated compares a filtered set of entries, matching symlinks on
// their raw (repo-relative) target rather than resolved absolute path.
func compareGenerated(t *testing.T, bashRepo, goRepo string, keep func(rel string) bool) {
	t.Helper()
	bash := filterKeys(scanTree(t, bashRepo), keep)
	go_ := filterKeys(scanTree(t, goRepo), keep)

	for rel, be := range bash {
		ge, ok := go_[rel]
		if !ok {
			t.Errorf("generated entry in bash missing in go: %s (%s)", rel, be.kind)
			continue
		}
		if be.kind != ge.kind {
			t.Errorf("%s: kind mismatch bash=%s go=%s", rel, be.kind, ge.kind)
			continue
		}
		bp, gp := filepath.Join(bashRepo, rel), filepath.Join(goRepo, rel)
		switch be.kind {
		case "symlink":
			// Repo-relative symlinks: compare the target resolved relative to
			// each repo root (the raw string can differ harmlessly when bash
			// mixes macOS /var and /private/var path forms).
			bt := resolvedRelToRepo(t, bashRepo, bp)
			gt := resolvedRelToRepo(t, goRepo, gp)
			if bt != gt {
				t.Errorf("%s: symlink resolves differently bash=%q go=%q", rel, bt, gt)
			}
		case "file":
			compareFile(t, rel, bp, gp)
		}
	}
	for rel := range go_ {
		if _, ok := bash[rel]; !ok {
			t.Errorf("generated entry in go missing in bash: %s (%s)", rel, go_[rel].kind)
		}
	}
}

// resolvedRelToRepo resolves a symlink and returns its real target relative to
// the repo's real root, so two repos at different temp paths compare equal.
func resolvedRelToRepo(t *testing.T, repo, link string) string {
	t.Helper()
	realRepo, err := filepath.EvalSymlinks(repo)
	if err != nil {
		t.Fatalf("resolve repo %s: %v", repo, err)
	}
	realTarget, err := filepath.EvalSymlinks(link)
	if err != nil {
		t.Fatalf("resolve link %s: %v", link, err)
	}
	rel, err := filepath.Rel(realRepo, realTarget)
	if err != nil {
		t.Fatalf("rel %s %s: %v", realRepo, realTarget, err)
	}
	return rel
}

func filterKeys(m map[string]entry, keep func(string) bool) map[string]entry {
	out := map[string]entry{}
	for k, v := range m {
		if keep(k) {
			out[k] = v
		}
	}
	return out
}

func TestSyncDryRunMakesNoChanges(t *testing.T) {
	requireTools(t)
	src := buildSource(t)
	bashRepo := t.TempDir()
	goRepo := t.TempDir()
	runBashSync(t, src, bashRepo, "--target", "claude", "--force", "--dry-run")
	runAcrSync(t, src, goRepo, "--target", "claude", "--force", "--dry-run")
	if e := scanTree(t, bashRepo); len(e) != 0 {
		t.Errorf("bash dry-run created entries: %v", e)
	}
	if e := scanTree(t, goRepo); len(e) != 0 {
		t.Errorf("acr dry-run created entries: %v", e)
	}
}
