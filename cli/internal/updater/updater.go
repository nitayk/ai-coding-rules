// Package updater refreshes vendored community skills/agents/commands/hooks from
// upstream repos, porting update-community.sh. Upstream repos are shallow-cloned
// into a cache dir and their contents synced into the local checkout.
package updater

import (
	"os"
	"os/exec"
	"path/filepath"
	"strings"

	"github.com/nitayk/nitays-agent-toolkit/cli/internal/fsx"
	"github.com/nitayk/nitays-agent-toolkit/cli/internal/ui"
)

// defaultCacheDir returns a user-owned location for upstream clones. The shell
// script used a fixed /tmp path; a user cache dir avoids the predictable,
// world-writable /tmp path (symlink-swap hardening) and is cross-platform.
func defaultCacheDir() string {
	if dir, err := os.UserCacheDir(); err == nil {
		return filepath.Join(dir, "nitays-agent-toolkit-upstream")
	}
	return filepath.Join(os.TempDir(), "nitays-agent-toolkit-upstream")
}

// Options configures an update run.
type Options struct {
	Repo     string // local nitays-agent-toolkit checkout to update (default: cwd)
	CacheDir string // upstream clone cache (default: defaultCacheDir())
	DryRun   bool
	ShowDiff bool
	Log      *ui.Logger
}

type source struct {
	url  string
	name string
}

type item struct {
	srcRel string
	dstRel string
	kind   string // "skills-dirs" | "files" | "dir-copy"
}

var sources = []source{
	{"https://github.com/obra/superpowers.git", "superpowers"},
	{"https://github.com/anthropics/skills.git", "anthropics-skills"},
}

var superpowersItems = []item{
	{"skills", "skills", "skills-dirs"},
	{"agents", "agents", "files"},
	{"commands", "commands", "files"},
	{"hooks", "hooks", "files"},
}

var anthropicsItems = []item{
	{"skills/docx", "skills/docx", "dir-copy"},
	{"skills/pdf", "skills/pdf", "dir-copy"},
	{"skills/xlsx", "skills/xlsx", "dir-copy"},
	{"skills/pptx", "skills/pptx", "dir-copy"},
	{"skills/mcp-builder", "skills/mcp-builder", "dir-copy"},
	{"skills/skill-creator", "skills/skill-creator", "dir-copy"},
	{"skills/webapp-testing", "skills/webapp-testing", "dir-copy"},
	{"skills/frontend-design", "skills/frontend-design", "dir-copy"},
	{"skills/web-artifacts-builder", "skills/web-artifacts-builder", "dir-copy"},
	{"spec", "spec", "dir-copy"},
	{"template", "template", "dir-copy"},
}

type stats struct{ New, Updated, Unchanged int }

// Run clones/pulls the upstream repos and syncs their content into the checkout.
func Run(o Options) error {
	if o.CacheDir == "" {
		o.CacheDir = defaultCacheDir()
	}
	if o.Repo == "" {
		wd, err := os.Getwd()
		if err != nil {
			return err
		}
		o.Repo = wd
	}
	repo, err := filepath.Abs(o.Repo)
	if err != nil {
		return err
	}

	o.Log.Plain("")
	o.Log.Plain("==========================================")
	o.Log.Plain("  nitays-agent-toolkit: Update Community Sources")
	o.Log.Plain("==========================================")
	o.Log.Plain("")
	if o.DryRun {
		o.Log.Warn("DRY RUN MODE - no changes will be made")
		o.Log.Plain("")
	}

	for _, s := range sources {
		o.cloneOrPull(s)
	}
	o.Log.Plain("")

	st := &stats{}
	o.Log.Info("Syncing from obra/superpowers...")
	sp := filepath.Join(o.CacheDir, "superpowers")
	o.syncItems(sp, repo, superpowersItems, st)
	o.Log.Plain("")

	o.Log.Info("Syncing from anthropics/skills...")
	as := filepath.Join(o.CacheDir, "anthropics-skills")
	o.syncItems(as, repo, anthropicsItems, st)

	o.Log.Plain("")
	o.Log.Plain("==========================================")
	o.Log.Plain("  Summary")
	o.Log.Plain("==========================================")
	o.Log.Plain("  New:       %d", st.New)
	o.Log.Plain("  Updated:   %d", st.Updated)
	o.Log.Plain("  Unchanged: %d", st.Unchanged)
	o.Log.Plain("")

	switch {
	case o.DryRun:
		o.Log.Warn("Dry run complete. Run without --dry-run to apply.")
	case st.Updated > 0 || st.New > 0:
		o.Log.Success("Updates applied. Review with:")
		o.Log.Plain("  cd %s", repo)
		o.Log.Plain("  git diff")
	default:
		o.Log.Success("Everything is up to date.")
	}
	o.Log.Plain("")
	o.Log.Plain("Upstream cache: %s", o.CacheDir)
	o.Log.Plain("  (delete to force fresh clone: rm -rf %s)", o.CacheDir)
	return nil
}

func (o Options) cloneOrPull(s source) {
	dest := filepath.Join(o.CacheDir, s.name)
	if fsx.IsDir(filepath.Join(dest, ".git")) {
		o.Log.Info("Updating %s...", s.name)
		if err := git(dest, "fetch", "--depth", "1", "origin", "main"); err != nil {
			_ = git(dest, "fetch", "--depth", "1", "origin", "master")
		}
		_ = git(dest, "reset", "--hard", "FETCH_HEAD")
	} else {
		o.Log.Info("Cloning %s...", s.name)
		_ = fsx.EnsureDir(o.CacheDir)
		_ = git("", "clone", "--depth", "1", s.url, dest)
	}
	sha, _ := gitOut(dest, "rev-parse", "--short", "HEAD")
	when, _ := gitOut(dest, "log", "-1", "--format=%ci")
	date, _, _ := strings.Cut(strings.TrimSpace(when), " ")
	o.Log.Success("%s @ %s (%s)", s.name, strings.TrimSpace(sha), date)
}

func (o Options) syncItems(srcBase, dstBase string, items []item, st *stats) {
	for _, it := range items {
		src := filepath.Join(srcBase, it.srcRel)
		dst := filepath.Join(dstBase, it.dstRel)
		switch it.kind {
		case "skills-dirs":
			o.syncSkillsDirs(src, dst, st)
		case "files":
			o.syncFiles(src, dst, st)
		case "dir-copy":
			o.syncDir(src, dst, it.dstRel, st)
		}
	}
}

func (o Options) syncSkillsDirs(srcBase, dstBase string, st *stats) {
	entries, err := os.ReadDir(srcBase)
	if err != nil {
		return
	}
	for _, e := range entries {
		if !e.IsDir() {
			continue
		}
		skillDir := filepath.Join(srcBase, e.Name())
		if !fsx.Exists(filepath.Join(skillDir, "SKILL.md")) {
			continue
		}
		o.syncDir(skillDir, filepath.Join(dstBase, e.Name()), "skill: "+e.Name(), st)
	}
}

func (o Options) syncFiles(srcDir, dstDir string, st *stats) {
	entries, err := os.ReadDir(srcDir)
	if err != nil {
		return
	}
	for _, e := range entries {
		if e.IsDir() || e.Name() == "README.md" {
			continue
		}
		o.syncFile(filepath.Join(srcDir, e.Name()), filepath.Join(dstDir, e.Name()), e.Name(), st)
	}
}

func (o Options) syncDir(src, dst, label string, st *stats) {
	if !fsx.IsDir(dst) {
		if !o.DryRun {
			if err := fsx.CopyDir(src, dst); err != nil {
				o.Log.Error("copy %s: %v", label, err)
				return
			}
		}
		o.Log.Success("NEW: %s", label)
		st.New++
		return
	}
	if fsx.DirsIdentical(src, dst) {
		o.Log.Plain("  [skip] %s (unchanged)", label)
		st.Unchanged++
		return
	}
	if o.ShowDiff {
		o.printDiff(dst, src)
	}
	if !o.DryRun {
		if err := fsx.CopyDir(src, dst); err != nil {
			o.Log.Error("copy %s: %v", label, err)
			return
		}
	}
	o.Log.Success("UPDATED: %s", label)
	st.Updated++
}

func (o Options) syncFile(src, dst, label string, st *stats) {
	if !fsx.Exists(dst) {
		if !o.DryRun {
			if err := fsx.CopyFile(src, dst, false); err != nil {
				o.Log.Error("copy %s: %v", label, err)
				return
			}
		}
		o.Log.Success("NEW: %s", label)
		st.New++
		return
	}
	if fsx.FilesIdentical(src, dst) {
		o.Log.Plain("  [skip] %s (unchanged)", label)
		st.Unchanged++
		return
	}
	if o.ShowDiff {
		o.printDiff(dst, src)
	}
	if !o.DryRun {
		if err := fsx.CopyFile(src, dst, false); err != nil {
			o.Log.Error("copy %s: %v", label, err)
			return
		}
	}
	o.Log.Success("UPDATED: %s", label)
	st.Updated++
}

func (o Options) printDiff(oldPath, newPath string) {
	o.Log.Plain("")
	out, _ := exec.Command("diff", "-ru", oldPath, newPath).Output()
	o.Log.Plain("%s", string(out))
	o.Log.Plain("")
}

func git(dir string, args ...string) error {
	cmd := exec.Command("git", args...)
	if dir != "" {
		cmd.Dir = dir
	}
	return cmd.Run()
}

func gitOut(dir string, args ...string) (string, error) {
	cmd := exec.Command("git", args...)
	if dir != "" {
		cmd.Dir = dir
	}
	out, err := cmd.Output()
	return string(out), err
}
