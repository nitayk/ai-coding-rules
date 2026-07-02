package syncer

import (
	"os"
	"path/filepath"
	"sort"
	"strings"

	"github.com/nitayk/ai-coding-rules/cli/internal/fsx"
	"github.com/nitayk/ai-coding-rules/cli/internal/hooksjson"
)

// syncHooks copies hook scripts and reconciles hooks.json for a target.
func (r *runner) syncHooks(target string, tp targetPaths) {
	hooksSrc := filepath.Join(r.o.ScriptDir, "hooks")
	if !fsx.IsDir(hooksSrc) {
		return
	}
	r.log.Plain("")
	r.log.Info("Syncing hooks for %s...", target)
	if !r.o.DryRun {
		_ = fsx.EnsureDir(filepath.Join(r.o.RepoRoot, tp.hooksDir))
	}

	rels, err := fsx.WalkFiles(hooksSrc, keepHookFile)
	if err != nil {
		r.log.Error("walk hooks: %v", err)
	}
	sort.Strings(rels)
	for _, rel := range rels {
		hookFile := filepath.Join(hooksSrc, rel)
		dest := filepath.Join(r.o.RepoRoot, tp.hooksDir, rel)
		r.copyOrLink(hookFile, dest, "hook: "+rel, true)
	}

	r.syncHooksJSON(target, tp)

	r.log.Plain("")
	r.log.Info("Hooks synced for %s", target)
}

// keepHookFile mirrors the find filter: *.sh/*.py/*.js/*.cmd or a bare
// "session-start", excluding anything under an ecc-hooks/ directory.
func keepHookFile(rel string, info os.FileInfo) bool {
	for _, seg := range strings.Split(rel, string(filepath.Separator)) {
		if seg == "ecc-hooks" {
			return false
		}
	}
	switch filepath.Ext(rel) {
	case ".sh", ".py", ".js", ".cmd":
		return true
	}
	return filepath.Base(rel) == "session-start"
}

// syncHooksJSON reconciles the shared hooks.json with the consumer's, then
// filters per target. For Claude it resolves ${CLAUDE_PLUGIN_ROOT}, injects the
// hooks into settings.json, and removes the standalone hooks.json.
func (r *runner) syncHooksJSON(target string, tp targetPaths) {
	shared := filepath.Join(r.o.ScriptDir, "hooks", "hooks.json")
	repoJSON := filepath.Join(r.o.RepoRoot, tp.hooksJSON)
	if !fsx.Exists(shared) {
		return
	}
	if !hooksjson.Valid(shared) {
		r.log.Error("Shared hooks.json is invalid")
		return
	}
	repoExists := fsx.Exists(repoJSON) && !fsx.IsDir(repoJSON)
	if repoExists && !hooksjson.Valid(repoJSON) {
		r.log.Error("Repo hooks.json is invalid")
		return
	}
	repoDifferent := repoExists && !fsx.FilesIdentical(shared, repoJSON)

	if repoDifferent {
		r.createBackup(repoJSON)
	}

	// Dry-run performs no filesystem changes for hooks.json (matches the shell,
	// which guards the filter/inject block on !DRY_RUN).
	if r.o.DryRun {
		r.log.Verbosef("Would sync hooks.json for %s", target)
		return
	}

	// Determine the output object. With symlinks and no diverging repo file the
	// shell symlinks then dereferences to a copy of shared; the copy path with no
	// repo file likewise copies shared; only two diverging files trigger a merge.
	var obj hooksjson.Object
	if (r.o.UseSymlinks && !repoDifferent) || !repoExists {
		obj, _ = hooksjson.Load(shared)
	} else {
		sharedObj, _ := hooksjson.Load(shared)
		repoObj, _ := hooksjson.Load(repoJSON)
		obj = hooksjson.MergeReshape(sharedObj, repoObj)
	}
	if obj == nil {
		r.log.Error("could not load hooks.json")
		return
	}

	hooksjson.FilterForTarget(obj, target)

	if target != "claude" {
		if err := hooksjson.Write(repoJSON, obj); err != nil {
			r.log.Error("write hooks.json: %v", err)
			return
		}
		r.log.Stats.Updated++
		return
	}

	// Claude: resolve plugin root, inject into settings.json, drop hooks.json.
	if hooksjson.HasPluginRoot(obj) {
		hooksjson.ResolvePluginRoot(obj, tp.hooksDir)
		r.log.Verbosef("Resolved ${CLAUDE_PLUGIN_ROOT}/hooks/ → %s/ in hooks.json", tp.hooksDir)
	}
	settingsPath := filepath.Join(r.o.RepoRoot, ".claude", "settings.json")
	if fsx.Exists(settingsPath) {
		settings, err := hooksjson.Load(settingsPath)
		if err != nil {
			r.log.Error("parse settings.json: %v", err)
			return
		}
		hooksjson.InjectHooks(settings, obj)
		if err := hooksjson.Write(settingsPath, settings); err != nil {
			r.log.Error("write settings.json: %v", err)
			return
		}
		r.log.Success("Injected hooks into .claude/settings.json")
	} else {
		_ = fsx.EnsureDir(filepath.Dir(settingsPath))
		if err := hooksjson.Write(settingsPath, hooksjson.Object{"hooks": obj["hooks"]}); err != nil {
			r.log.Error("create settings.json: %v", err)
			return
		}
		r.log.Success("Created .claude/settings.json with hooks")
	}
	if fsx.Exists(repoJSON) {
		_ = os.Remove(repoJSON)
	}
	r.log.Verbosef("Removed redundant %s (hooks live in settings.json)", tp.hooksJSON)
}
