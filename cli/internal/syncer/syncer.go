// Package syncer ports sync-rules.sh: it deploys skills, agents, commands, and
// hooks from an nitays-agent-toolkit checkout into a consumer repo's Claude Code
// directories, with skill-group filtering, symlink-or-copy modes, hooks.json
// merging, and Claude isolation.
//
// Parity contract: identical filesystem effects (paths, symlink targets, file
// contents, JSON semantics, .gitignore patterns). Log wording may differ.
package syncer

import (
	"fmt"
	"os"
	"path/filepath"
	"sort"
	"strings"
	"time"

	"github.com/nitayk/nitays-agent-toolkit/cli/internal/fsx"
	"github.com/nitayk/nitays-agent-toolkit/cli/internal/hooksjson"
	"github.com/nitayk/nitays-agent-toolkit/cli/internal/skillgroups"
	"github.com/nitayk/nitays-agent-toolkit/cli/internal/ui"
)

// Options configures a sync run.
type Options struct {
	RepoRoot       string   // consumer repo to sync into
	ScriptDir      string   // nitays-agent-toolkit content dir (holds skills/agents/commands/hooks/config)
	Targets        []string // always ["claude"] — Claude Code is the only deploy target
	SkillsFilter   string   // "defaults" | "all" | csv of groups
	NoSkillsFilter string   // csv of groups to exclude
	UseSymlinks    bool
	DryRun         bool
	Force          bool
	Backup         bool
	Log            *ui.Logger
}

// targetPaths holds the Claude Code destination layout (resolve_target_paths).
type targetPaths struct {
	skillsDest   string
	agentsDest   string
	commandsDest string
	memoryDir    string
	hooksDir     string
	hooksJSON    string
}

type runner struct {
	o         Options
	log       *ui.Logger
	skills    skillgroups.Filter
	agents    skillgroups.Filter
	backupDir string
}

// Run executes the sync for all configured targets.
func Run(o Options) error {
	r := &runner{o: o, log: o.Log}

	if o.DryRun {
		r.log.Info("DRY RUN MODE - No changes will be made")
		r.log.Plain("")
	}
	r.log.Info("Setting up nitays-agent-toolkit...")
	r.log.Verbosef("Repo root: %s", o.RepoRoot)
	r.log.Verbosef("Script dir: %s", o.ScriptDir)

	if err := r.validateSubmodule(); err != nil {
		return err
	}
	if err := r.validateTargets(); err != nil {
		return err
	}

	r.backupDir = filepath.Join(o.RepoRoot, ".claude", ".setup-backup-"+timestamp())
	if o.Backup && !o.DryRun {
		_ = fsx.EnsureDir(r.backupDir)
	}

	r.ensureManagedGitignore()
	r.migrateDeprecatedPaths()
	r.resolveFilters()

	for _, target := range o.Targets {
		tp := resolveTargetPaths(target)
		r.log.Plain("")
		r.log.Info("=== Syncing for target: %s ===", target)

		if !o.DryRun {
			_ = fsx.EnsureDir(filepath.Join(o.RepoRoot, ".claude"))
			for _, d := range []string{tp.skillsDest, tp.agentsDest, tp.commandsDest} {
				_ = fsx.EnsureDir(filepath.Join(o.RepoRoot, d))
			}
		}

		r.syncSkills(tp)
		r.syncMarkdownDir(filepath.Join(o.ScriptDir, "agents"), filepath.Join(o.RepoRoot, tp.agentsDest), "agent")
		r.syncMarkdownDir(filepath.Join(o.ScriptDir, "commands"), filepath.Join(o.RepoRoot, tp.commandsDest), "command")
		r.setupMemory(target, tp)
		r.syncHooks(target, tp)
		r.ensureClaudeIsolation()
	}

	r.summary()
	return nil
}

// ParseTargets validates a --target value. Claude Code is the only supported
// deploy target; anything else (including the retired "cursor" target) is
// rejected. It is the single authoritative parser used by the cobra layer and
// the installer so validation cannot diverge across entry points.
func ParseTargets(target string) ([]string, error) {
	var out []string
	for _, p := range strings.Split(target, ",") {
		p = strings.TrimSpace(p)
		if p == "" {
			continue
		}
		if p != "claude" {
			return nil, fmt.Errorf("invalid --target %q (only claude is supported)", p)
		}
		out = append(out, p)
	}
	if len(out) == 0 {
		return nil, fmt.Errorf("invalid --target: only claude is supported")
	}
	return out, nil
}

func (r *runner) validateSubmodule() error {
	sd := filepath.ToSlash(r.o.ScriptDir)
	// The submodule always lives at .cursor/rules/shared — a Claude-safe
	// location (Claude Code ignores .cursor/), which avoids the context
	// explosion that would happen under .claude/.
	if !strings.HasSuffix(sd, "/.cursor/rules/shared") {
		return nil
	}
	if !fsx.IsDir(filepath.Join(sd, "skills")) &&
		!fsx.IsDir(filepath.Join(sd, "agents")) &&
		!fsx.IsDir(filepath.Join(sd, "commands")) {
		return fmt.Errorf("submodule appears uninitialized: %s/{skills,agents,commands} not found — run: git submodule update --init --recursive .cursor/rules/shared", sd)
	}
	return nil
}

func (r *runner) validateTargets() error {
	if len(r.o.Targets) == 0 {
		return fmt.Errorf("invalid --target: only claude is supported")
	}
	for _, t := range r.o.Targets {
		if t != "claude" {
			return fmt.Errorf("invalid --target: %q (only claude is supported)", t)
		}
	}
	return nil
}

func (r *runner) resolveFilters() {
	cfg := filepath.Join(r.o.ScriptDir, "config", "skill-groups.yaml")
	var warns []string
	r.skills, warns = skillgroups.ResolveSkills(r.o.SkillsFilter, r.o.NoSkillsFilter, cfg, filepath.Join(r.o.ScriptDir, "skills"))
	for _, w := range warns {
		r.log.Warn("%s", w)
	}
	if !r.skills.All {
		r.log.Info("Skill filter: %d skills selected (groups: %s%s)", len(r.skills.Names()), r.o.SkillsFilter, excludeNote(r.o.NoSkillsFilter))
	} else {
		r.log.Verbosef("Skills: syncing all (no filter)")
	}

	r.agents, warns = skillgroups.ResolveAgents(r.o.SkillsFilter, r.o.NoSkillsFilter, cfg, filepath.Join(r.o.ScriptDir, "agents"))
	for _, w := range warns {
		r.log.Warn("%s", w)
	}
	if !r.agents.All {
		r.log.Info("Agent filter: %d agents selected (matching skill groups)", len(r.agents.Names()))
	} else {
		r.log.Verbosef("Agents: syncing all (no filter)")
	}
}

func excludeNote(no string) string {
	if no == "" {
		return ""
	}
	return ", excluding: " + no
}

// syncSkills copies skill directories (skills are always copied, never
// symlinked) applying the skill filter, then removes managed skills excluded by
// the filter.
func (r *runner) syncSkills(tp targetPaths) {
	source := filepath.Join(r.o.ScriptDir, "skills")
	dest := filepath.Join(r.o.RepoRoot, tp.skillsDest)
	if !fsx.IsDir(source) {
		r.log.Verbosef("Skills directory not found (OK if running from the repo itself)")
		return
	}
	r.log.Plain("")
	r.log.Info("Syncing Skills...")
	if !r.o.DryRun {
		_ = fsx.EnsureDir(dest)
	}

	for _, name := range sortedSkillDirs(source) {
		if !r.skills.Allowed(name) {
			r.log.Verbosef("Skipped skill (not in selected groups): %s", name)
			continue
		}
		r.copyDir(filepath.Join(source, name), filepath.Join(dest, name), "skill: "+name)
	}

	removed := 0
	for _, name := range sortedSkillDirs(dest) {
		if fsx.Exists(filepath.Join(source, name, "SKILL.md")) && !r.skills.Allowed(name) {
			if r.o.DryRun {
				r.log.Info("Would remove excluded skill: %s", name)
			} else {
				_ = os.RemoveAll(filepath.Join(dest, name))
				r.log.Verbosef("Removed excluded skill: %s", name)
			}
			removed++
		}
	}
	r.log.Plain("")
	r.log.Info("Skills synced (copied)")
	if removed > 0 {
		r.log.Info("Removed %d excluded skill(s) from prior install", removed)
	}
}

// syncMarkdownDir handles agents/commands: symlink (default) or copy each *.md
// except README.md, applying the agent filter for agents, then removing managed
// agents excluded by the filter.
func (r *runner) syncMarkdownDir(source, dest, itemType string) {
	if !fsx.IsDir(source) {
		r.log.Verbosef("%ss directory not found (OK if running from the repo itself)", capitalize(itemType))
		return
	}
	r.log.Plain("")
	r.log.Info("Syncing %ss...", capitalize(itemType))
	if !r.o.DryRun {
		_ = fsx.EnsureDir(dest)
	}

	for _, name := range sortedMarkdown(source) {
		if name == "README.md" {
			continue
		}
		if itemType == "agent" && !r.agents.Allowed(strings.TrimSuffix(name, ".md")) {
			r.log.Verbosef("Skipped agent (not in selected groups): %s", strings.TrimSuffix(name, ".md"))
			continue
		}
		r.copyOrLink(filepath.Join(source, name), filepath.Join(dest, name), itemType+": "+name, false)
	}

	if itemType == "agent" {
		removed := 0
		for _, name := range sortedMarkdown(dest) {
			if name == "README.md" {
				continue
			}
			if fsx.Exists(filepath.Join(source, name)) && !r.agents.Allowed(strings.TrimSuffix(name, ".md")) {
				if r.o.DryRun {
					r.log.Info("Would remove excluded agent: %s", strings.TrimSuffix(name, ".md"))
				} else {
					_ = os.Remove(filepath.Join(dest, name))
					r.log.Verbosef("Removed excluded agent: %s", strings.TrimSuffix(name, ".md"))
				}
				removed++
			}
		}
		if removed > 0 {
			r.log.Info("Removed %d excluded agent(s) from prior install", removed)
		}
	}

	if r.o.UseSymlinks {
		r.log.Info("%ss linked (using symlinks - automatic updates)", capitalize(itemType))
	} else {
		r.log.Info("%ss synced (copied)", capitalize(itemType))
	}
}

func (r *runner) setupMemory(target string, tp targetPaths) {
	r.log.Plain("")
	r.log.Info("Setting up local memory for %s...", target)
	memFull := filepath.Join(r.o.RepoRoot, tp.memoryDir)
	if r.o.DryRun {
		r.log.Info("Would create memory dir: %s", memFull)
		return
	}
	_ = fsx.EnsureDir(memFull)
	ctx := filepath.Join(memFull, "active_context.md")
	if !fsx.Exists(ctx) {
		_ = os.WriteFile(ctx, []byte(activeContextTemplate), 0o644)
		r.log.Success("Created private memory: %s/active_context.md", tp.memoryDir)
	}
	gi := filepath.Join(r.o.RepoRoot, ".gitignore")
	if !fsx.Exists(gi) {
		_ = fsx.AppendString(gi, "")
	}
	if !fsx.FileContains(gi, tp.memoryDir+"/") {
		_ = fsx.AppendString(gi, fmt.Sprintf("\n# Agent Memory (Private State)\n%s/\n", tp.memoryDir))
		r.log.Success("Added %s/ to .gitignore", tp.memoryDir)
	}
	if !fsx.FileContains(gi, "# ECC: agent sessions + hook logs") {
		_ = fsx.AppendString(gi, eccGitignoreBlock)
		r.log.Success("Added ECC session/hook log paths to .gitignore")
	}
}

func (r *runner) ensureManagedGitignore() {
	gi := filepath.Join(r.o.RepoRoot, ".gitignore")
	if r.o.DryRun {
		if !fsx.Exists(gi) || !fsx.FileContains(gi, gitignoreMarkerBegin) {
			r.log.Info("Would ensure .gitignore has managed entries (.agents/, skill *-workspace/)")
		}
		return
	}
	if fsx.Exists(gi) && fsx.FileContains(gi, gitignoreMarkerBegin) {
		r.log.Verbosef(".gitignore already contains nitays-agent-toolkit managed block")
		return
	}
	if !fsx.Exists(gi) {
		_ = os.WriteFile(gi, []byte{}, 0o644)
		r.log.Success("Created .gitignore at repo root")
	}
	_ = fsx.AppendString(gi, managedGitignoreBlock)
	r.log.Success("Appended managed paths to .gitignore (.agents/, *-workspace/)")
}

func (r *runner) migrateDeprecatedPaths() {
	if r.o.DryRun {
		r.log.Verbosef("Would migrate deprecated symlinks under .agents/skills / .claude/skills (if present)")
		return
	}
	root := r.o.RepoRoot
	for _, p := range []string{".agents/skills", ".claude/skills"} {
		full := filepath.Join(root, p)
		if fsx.IsSymlink(full) {
			r.log.Info("Removing deprecated %s symlink (skills must be copied directories)", p)
			_ = os.Remove(full)
		}
	}
}

func (r *runner) ensureClaudeIsolation() {
	settingsPath := filepath.Join(r.o.RepoRoot, ".claude", "settings.json")
	deny := []any{"Read(./.cursor/**)", "Read(./.agent-rules/**)"}
	allow := []any{
		"Bash(rm -rf .claude/skills/*)", "Bash(rm -rf .claude/agents/*)",
		"Bash(rm -rf .claude/hooks/*)", "Bash(rm -rf .agents/skills/*)",
		"Bash(rm .claude/*)", "Bash(rm .agents/*)",
	}
	if r.o.DryRun {
		r.log.Info("Would ensure Claude isolation: permissions.deny + allow in %s", settingsPath)
		return
	}
	_ = fsx.EnsureDir(filepath.Join(r.o.RepoRoot, ".claude"))

	if !fsx.Exists(settingsPath) {
		obj := hooksjson.Object{"permissions": hooksjson.Object{"deny": deny, "allow": allow}}
		if err := hooksjson.Write(settingsPath, obj); err != nil {
			r.log.Error("write %s: %v", settingsPath, err)
			return
		}
		r.log.Success("Created .claude/settings.json with permissions (deny + allow)")
		return
	}
	obj, err := hooksjson.Load(settingsPath)
	if err != nil {
		r.log.Error("could not parse %s: %v", settingsPath, err)
		return
	}
	perms, _ := obj["permissions"].(hooksjson.Object)
	if perms == nil {
		perms = hooksjson.Object{}
	}
	if d, ok := perms["deny"].([]any); !ok || len(d) == 0 {
		perms["deny"] = deny
		obj["permissions"] = perms
		if err := hooksjson.Write(settingsPath, obj); err != nil {
			r.log.Error("write %s: %v", settingsPath, err)
			return
		}
		r.log.Success("Added permissions.deny to .claude/settings.json (Claude isolation)")
	} else {
		r.log.Verbosef("permissions.deny already present in .claude/settings.json")
	}
	if _, ok := perms["allow"]; !ok {
		perms["allow"] = allow
		obj["permissions"] = perms
		if err := hooksjson.Write(settingsPath, obj); err != nil {
			r.log.Error("write %s: %v", settingsPath, err)
			return
		}
		r.log.Success("Added permissions.allow to .claude/settings.json (managed path cleanup)")
	} else {
		r.log.Verbosef("permissions.allow already present in .claude/settings.json")
	}
}

func (r *runner) summary() {
	r.log.Plain("")
	if r.o.DryRun {
		r.log.Info("DRY RUN COMPLETE - No changes were made")
	} else {
		r.log.Success("Setup complete!")
	}
	r.log.Plain("")
	r.log.Info("Summary:")
	r.log.Plain("  Copied/Updated: %d", r.log.Stats.Updated)
	r.log.Plain("  Skipped: %d", r.log.Stats.Skipped)
	if r.log.Stats.Errors > 0 {
		r.log.Plain("  Errors: %d", r.log.Stats.Errors)
	}
	r.log.Plain("")
	r.log.Info("Synced to (target: %s):", strings.Join(r.o.Targets, ","))
	for _, t := range r.o.Targets {
		tp := resolveTargetPaths(t)
		r.log.Plain("  [%s] skills: %s, agents: %s, commands: %s", t, tp.skillsDest, tp.agentsDest, tp.commandsDest)
	}
}

func resolveTargetPaths(t string) targetPaths {
	if t == "claude" {
		return targetPaths{
			skillsDest:   ".claude/skills",
			agentsDest:   ".claude/agents",
			commandsDest: ".claude/commands",
			memoryDir:    ".claude/memory",
			hooksDir:     ".claude/hooks",
			hooksJSON:    ".claude/hooks.json",
		}
	}
	return targetPaths{}
}

// --- ordering helpers (sorted for deterministic output; effects are
// order-independent but determinism eases testing) ---

func sortedSkillDirs(dir string) []string {
	entries, err := os.ReadDir(dir)
	if err != nil {
		return nil
	}
	var out []string
	for _, e := range entries {
		if e.IsDir() && fsx.Exists(filepath.Join(dir, e.Name(), "SKILL.md")) {
			out = append(out, e.Name())
		}
	}
	sort.Strings(out)
	return out
}

func sortedMarkdown(dir string) []string {
	entries, err := os.ReadDir(dir)
	if err != nil {
		return nil
	}
	var out []string
	for _, e := range entries {
		if !e.IsDir() && strings.HasSuffix(e.Name(), ".md") {
			out = append(out, e.Name())
		}
	}
	sort.Strings(out)
	return out
}

func timestamp() string { return time.Now().Format("20060102_150405") }
