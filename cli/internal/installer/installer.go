// Package installer ports install.sh: it detects the consumer repo root,
// reconciles the .cursor/rules/shared submodule, runs a sync, and installs a
// post-merge hook so syncs happen automatically after `git pull`.
//
// When invoked from inside the ai-coding-rules checkout itself, it skips the
// submodule/hook steps and just runs a sync in-process (matching the shell's
// RUNNING_FROM_REPO fast path).
package installer

import (
	"fmt"
	"os"
	"os/exec"
	"path/filepath"
	"regexp"
	"strings"

	"github.com/nitayk/ai-coding-rules/cli/internal/fsx"
	"github.com/nitayk/ai-coding-rules/cli/internal/syncer"
	"github.com/nitayk/ai-coding-rules/cli/internal/ui"
)

const submodulePath = ".cursor/rules/shared"

// filterPattern constrains skill-group selectors. They are interpolated into
// the generated post-merge hook script, so they must not contain shell
// metacharacters (backticks, $(), quotes) — only group names, commas, and the
// handful of separators a group name may legitimately use.
var filterPattern = regexp.MustCompile(`^[A-Za-z0-9 ,_.\-]*$`)

// Options configures an install run.
type Options struct {
	StartDir       string // where repo-root detection begins (default: cwd)
	Target         string // "cursor" | "claude" | comma-separated
	SkillsFilter   string
	NoSkillsFilter string
	Profile        string
	UseSymlinks    bool
	DryRun         bool
	Log            *ui.Logger
}

// Run performs the full install workflow.
func Run(o Options) error {
	if o.Profile != "" && o.Profile != "generic" {
		return fmt.Errorf("unknown profile %q; only 'generic' is supported", o.Profile)
	}
	targets, err := syncer.ParseTargets(o.Target)
	if err != nil {
		return err
	}
	if !filterPattern.MatchString(o.SkillsFilter) {
		return fmt.Errorf("--skills %q contains invalid characters (allowed: letters, digits, comma, space, . _ -)", o.SkillsFilter)
	}
	if !filterPattern.MatchString(o.NoSkillsFilter) {
		return fmt.Errorf("--no-skills %q contains invalid characters (allowed: letters, digits, comma, space, . _ -)", o.NoSkillsFilter)
	}

	start := o.StartDir
	if start == "" {
		wd, err := os.Getwd()
		if err != nil {
			return err
		}
		start = wd
	}
	repoRoot, ok := detectRepoRoot(start)
	if !ok {
		return fmt.Errorf("not in a git repository; run this from your project root")
	}
	o.Log.Info("Detected repository root: %s", repoRoot)

	if o.DryRun {
		o.Log.Info("DRY RUN MODE - No changes will be made")
		o.Log.Plain("")
	}

	o.migrateLegacyClaudeSubmodule(repoRoot)
	o.removeStaleClaudeRules(repoRoot)

	// Fast path: running from the ai-coding-rules checkout itself.
	if runningFromRepo(repoRoot) {
		o.Log.Info("Running from ai-coding-rules repo itself — syncing directly...")
		return o.runSync(repoRoot, repoRoot, targets)
	}

	o.Log.Info("Step 1: Checking submodule...")
	subAbs := filepath.Join(repoRoot, submodulePath)
	if !submoduleInitialized(subAbs) {
		o.Log.Warn("Submodule not found at %s", submodulePath)
		if err := o.addSubmodule(repoRoot); err != nil {
			return err
		}
	} else {
		o.Log.Success("Submodule exists")
	}

	o.Log.Plain("")
	o.Log.Info("Step 2: Updating submodule...")
	o.updateSubmodule(repoRoot)

	o.Log.Plain("")
	o.Log.Info("Step 3: Running sync...")
	if !fsx.IsDir(filepath.Join(subAbs, "skills")) {
		// On a fresh consumer the submodule was only *previewed* (dry-run), so
		// there is nothing to sync yet — preview the step rather than erroring.
		if o.DryRun {
			o.Log.Info("Would run sync (after submodule is added)")
		} else {
			return fmt.Errorf("submodule not initialized correctly: %s missing skills/", submodulePath)
		}
	} else if err := o.runSync(repoRoot, subAbs, targets); err != nil {
		return err
	}

	o.Log.Plain("")
	o.Log.Info("Step 4: Installing post-merge hook...")
	o.installPostMergeHook(repoRoot)

	o.summary()
	return nil
}

// detectRepoRoot walks up from start looking for a .git directory.
func detectRepoRoot(start string) (string, bool) {
	dir, err := filepath.Abs(start)
	if err != nil {
		return "", false
	}
	for {
		if fsx.IsDir(filepath.Join(dir, ".git")) {
			return dir, true
		}
		parent := filepath.Dir(dir)
		if parent == dir {
			return "", false
		}
		dir = parent
	}
}

// runningFromRepo reports whether repoRoot is an ai-coding-rules checkout
// (carries the source content directories), matching RUNNING_FROM_REPO.
func runningFromRepo(repoRoot string) bool {
	return fsx.IsDir(filepath.Join(repoRoot, "skills")) &&
		fsx.IsDir(filepath.Join(repoRoot, "agents"))
}

func submoduleInitialized(subAbs string) bool {
	return fsx.IsDir(subAbs) && fsx.LExists(filepath.Join(subAbs, ".git"))
}

// runSync invokes the sync engine in-process for the configured targets.
func (o Options) runSync(repoRoot, scriptDir string, targets []string) error {
	return syncer.Run(syncer.Options{
		RepoRoot:       repoRoot,
		ScriptDir:      scriptDir,
		Targets:        targets,
		SkillsFilter:   o.SkillsFilter,
		NoSkillsFilter: o.NoSkillsFilter,
		UseSymlinks:    o.UseSymlinks,
		DryRun:         o.DryRun,
		Force:          true, // install always syncs with --force
		Log:            o.Log,
	})
}

func (o Options) migrateLegacyClaudeSubmodule(repoRoot string) {
	legacy := filepath.Join(repoRoot, ".claude/rules/shared")
	if !fsx.IsDir(legacy) || !fsx.LExists(filepath.Join(legacy, ".git")) {
		return
	}
	o.Log.Warn("Found submodule at .claude/rules/shared (causes Claude Code context explosion)")
	if o.DryRun {
		o.Log.Info("Would remove legacy submodule at .claude/rules/shared")
		return
	}
	o.Log.Info("Migrating to %s...", submodulePath)
	_ = git(repoRoot, "submodule", "deinit", "-f", ".claude/rules/shared")
	_ = git(repoRoot, "rm", "-f", ".claude/rules/shared")
	_ = os.RemoveAll(filepath.Join(repoRoot, ".git/modules/.claude/rules/shared"))
	_ = os.RemoveAll(legacy)
	rulesDir := filepath.Join(repoRoot, ".claude/rules")
	if entries, err := os.ReadDir(rulesDir); err == nil && len(entries) == 0 {
		_ = os.Remove(rulesDir)
	}
	o.Log.Success("Removed legacy submodule at .claude/rules/shared")
}

func (o Options) removeStaleClaudeRules(repoRoot string) {
	rules := filepath.Join(repoRoot, ".claude/rules")
	if !fsx.IsDir(rules) || fsx.LExists(filepath.Join(rules, ".git")) {
		return
	}
	o.Log.Warn("Found stale .claude/rules/ (loaded as context automatically)")
	if o.DryRun {
		o.Log.Info("Would remove stale .claude/rules/ directory")
		return
	}
	_ = os.RemoveAll(rules)
	o.Log.Success("Removed stale .claude/rules/ directory")
}

func (o Options) addSubmodule(repoRoot string) error {
	url := submoduleURL(repoRoot)
	if o.DryRun {
		o.Log.Info("Would add submodule: %s → %s", url, submodulePath)
		return nil
	}
	o.Log.Info("Adding submodule...")
	_ = fsx.EnsureDir(filepath.Dir(filepath.Join(repoRoot, submodulePath)))
	if git(repoRoot, "submodule", "add", url, submodulePath) == nil {
		o.Log.Success("Submodule added")
		return nil
	}
	// Retry over HTTPS if the SSH form failed.
	if strings.HasPrefix(url, "git@") {
		https := sshToHTTPS(url)
		o.Log.Warn("SSH clone failed, retrying with HTTPS...")
		if git(repoRoot, "submodule", "add", https, submodulePath) == nil {
			o.Log.Success("Submodule added")
			return nil
		}
	}
	return fmt.Errorf("failed to add submodule; add it manually: git submodule add %s %s",
		"https://github.com/nitayk/ai-coding-rules.git", submodulePath)
}

func (o Options) updateSubmodule(repoRoot string) {
	if o.DryRun {
		o.Log.Info("Would update submodule: git submodule update --remote %s", submodulePath)
		return
	}
	subAbs := filepath.Join(repoRoot, submodulePath)
	if !fsx.LExists(filepath.Join(subAbs, ".git")) {
		o.Log.Info("Initializing submodule...")
		_ = git(repoRoot, "submodule", "update", "--init", "--recursive", submodulePath)
	}
	// Discard tracked edits so the remote update applies cleanly.
	if out, _ := gitOut(subAbs, "status", "--porcelain"); strings.TrimSpace(out) != "" {
		o.Log.Warn("Submodule has local changes; discarding tracked edits (git reset --hard)")
		_ = git(subAbs, "reset", "--hard", "-q", "HEAD")
	}
	if err := git(repoRoot, "submodule", "update", "--remote", submodulePath); err != nil {
		o.Log.Warn("Failed to update submodule (may be pinned to a specific commit)")
		o.Log.Info("Continuing with current submodule state...")
		return
	}
	o.Log.Success("Submodule updated")
}

// installPostMergeHook writes (or appends to) the repo's post-merge hook so a
// sync runs whenever the submodule reference changes after a pull. The hook
// invokes `acr sync` — the deliberate post-migration replacement for the old
// `bash sync-rules.sh` call.
func (o Options) installPostMergeHook(repoRoot string) {
	if o.DryRun {
		o.Log.Info("Would install post-merge hook to run sync after git pull")
		return
	}
	hooksDir := gitHooksDir(repoRoot)
	postMerge := filepath.Join(hooksDir, "post-merge")
	_ = fsx.EnsureDir(hooksDir)

	if fsx.Exists(postMerge) {
		if fsx.FileContains(postMerge, hookMarker) {
			o.Log.Success("Post-merge hook already installed")
			return
		}
		_ = fsx.AppendString(postMerge, "\n"+o.hookBlock())
		_ = os.Chmod(postMerge, 0o755)
		o.Log.Success("Appended sync to existing post-merge hook")
		return
	}
	content := "#!/usr/bin/env bash\n" +
		"# Post-merge hook: sync ai-coding-rules when submodule reference changes\n" +
		"# Installed by acr install\n\n" +
		"cd \"$(git rev-parse --show-toplevel)\" || exit 0\n" +
		o.hookBlock()
	_ = os.WriteFile(postMerge, []byte(content), 0o755)
	o.Log.Success("Post-merge hook installed")
}

const hookMarker = "ai-coding-rules: sync after pull"

func (o Options) hookBlock() string {
	args := fmt.Sprintf("--force --target %q", o.Target)
	if o.SkillsFilter != "" && o.SkillsFilter != "defaults" {
		args += fmt.Sprintf(" --skills %q", o.SkillsFilter)
	}
	if o.NoSkillsFilter != "" {
		args += fmt.Sprintf(" --no-skills %q", o.NoSkillsFilter)
	}
	return fmt.Sprintf(`# --- %s (only when submodule changed) ---
cd "$(git rev-parse --show-toplevel)" 2>/dev/null || exit 0
if [ -d "%s" ] && \
   ! git diff --quiet HEAD^1 HEAD -- "%s" 2>/dev/null; then
  git submodule update --init "%s" 2>/dev/null || true
  acr sync %s 2>/dev/null || true
fi
`, hookMarker, submodulePath, submodulePath, submodulePath, args)
}

func (o Options) summary() {
	o.Log.Plain("")
	o.Log.Success("Setup complete!")
	o.Log.Plain("")
	o.Log.Info("What was done:")
	o.Log.Plain("  1. Submodule checked/added at %s", submodulePath)
	o.Log.Plain("  2. Submodule updated to latest")
	o.Log.Plain("  3. Files synced (target: %s, --force)", o.Target)
	o.Log.Plain("  4. Post-merge hook installed (runs sync after git pull)")
	if o.UseSymlinks {
		o.Log.Plain("     → Using symlinks (automatic updates)")
	} else {
		o.Log.Plain("     → Using file copying")
	}
	o.Log.Plain("")
	o.Log.Info("To update later: acr install")
}

// --- git helpers ---

func submoduleURL(repoRoot string) string {
	out, err := gitOut(repoRoot, "remote", "get-url", "origin")
	const ssh = "git@github.com:nitayk/ai-coding-rules.git"
	const https = "https://github.com/nitayk/ai-coding-rules.git"
	if err == nil && strings.Contains(out, "git@") {
		return ssh
	}
	return https
}

func sshToHTTPS(url string) string {
	return strings.Replace(url, "git@github.com:", "https://github.com/", 1)
}

func gitHooksDir(repoRoot string) string {
	out, err := gitOut(repoRoot, "rev-parse", "--git-common-dir")
	common := strings.TrimSpace(out)
	if err != nil || common == "" {
		common = ".git"
	}
	if !filepath.IsAbs(common) {
		common = filepath.Join(repoRoot, common)
	}
	return filepath.Join(common, "hooks")
}

func git(dir string, args ...string) error {
	cmd := exec.Command("git", args...)
	cmd.Dir = dir
	return cmd.Run()
}

func gitOut(dir string, args ...string) (string, error) {
	cmd := exec.Command("git", args...)
	cmd.Dir = dir
	out, err := cmd.Output()
	return string(out), err
}
