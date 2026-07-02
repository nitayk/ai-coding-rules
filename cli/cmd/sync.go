package cmd

import (
	"fmt"
	"os"
	"path/filepath"

	"github.com/nitayk/nitays-agent-toolkit/cli/internal/fsx"
	"github.com/nitayk/nitays-agent-toolkit/cli/internal/syncer"
	"github.com/nitayk/nitays-agent-toolkit/cli/internal/ui"
	"github.com/spf13/cobra"
)

func newSyncCmd() *cobra.Command {
	var (
		target    string
		skills    string
		noSkills  string
		useCopy   bool
		dryRun    bool
		force     bool
		backup    bool
		repoRoot  string
		sourceDir string
	)
	cmd := &cobra.Command{
		Use:   "sync",
		Short: "Sync skills/agents/commands/hooks into a project",
		Long: `Sync deploys skills, agents, commands, and hooks from an nitays-agent-toolkit
checkout into a consumer repo's Claude Code (.claude/) directories.

Skills are always copied (Claude doesn't index symlinked skill trees);
agents, commands, and hooks are symlinked by default (use --copy to copy).
The submodule always lives at .cursor/rules/shared — a Claude-safe location
(Claude Code ignores .cursor/), never under .claude/rules/, which would explode
Claude Code's context.`,
		Example: `  acr sync                          # from a consumer repo
  acr sync --skills core,git        # Only core + git skill groups
  acr sync --no-skills scala        # All skills except the scala group
  acr sync --dry-run                # Preview changes`,
		Args: cobra.NoArgs,
		RunE: func(c *cobra.Command, args []string) error {
			root, script, err := resolveSyncDirs(repoRoot, sourceDir)
			if err != nil {
				return err
			}
			targets, err := syncer.ParseTargets(target)
			if err != nil {
				return err
			}
			return syncer.Run(syncer.Options{
				RepoRoot:       root,
				ScriptDir:      script,
				Targets:        targets,
				SkillsFilter:   skills,
				NoSkillsFilter: noSkills,
				UseSymlinks:    !useCopy,
				DryRun:         dryRun,
				Force:          force,
				Backup:         backup,
				Log:            ui.New(verbose),
			})
		},
	}
	cmd.Flags().StringVar(&target, "target", "claude", "deploy target (only claude is supported)")
	cmd.Flags().StringVar(&skills, "skills", "defaults", "comma-separated skill groups to sync, or 'all'")
	cmd.Flags().StringVar(&noSkills, "no-skills", "", "comma-separated skill groups to exclude")
	cmd.Flags().BoolVar(&useCopy, "copy", false, "copy files instead of symlinking")
	cmd.Flags().BoolVar(&dryRun, "dry-run", false, "show what would be done without making changes")
	cmd.Flags().BoolVarP(&force, "force", "f", false, "overwrite managed files when they differ")
	cmd.Flags().BoolVar(&backup, "backup", false, "create backups before overwriting")
	cmd.Flags().StringVar(&repoRoot, "repo-root", "", "consumer repo to sync into (default: detected)")
	cmd.Flags().StringVar(&sourceDir, "source", "", "nitays-agent-toolkit content dir (default: detected)")
	return cmd
}

// resolveSyncDirs determines the consumer repo root and the nitays-agent-toolkit
// content dir. Explicit flags win; otherwise it detects dev mode (cwd is the
// checkout) vs consumer mode (submodule at .cursor/rules/shared).
func resolveSyncDirs(repoRoot, sourceDir string) (root, script string, err error) {
	wd, err := os.Getwd()
	if err != nil {
		return "", "", err
	}
	root = repoRoot
	if root == "" {
		root = wd
	}
	if sourceDir != "" {
		return root, sourceDir, nil
	}
	// Dev mode: cwd is the nitays-agent-toolkit checkout.
	if fsx.IsDir(filepath.Join(root, "skills")) && fsx.Exists(filepath.Join(root, "config", "skill-groups.yaml")) {
		return root, root, nil
	}
	// Consumer mode: submodule at .cursor/rules/shared.
	sub := filepath.Join(root, ".cursor", "rules", "shared")
	if fsx.IsDir(filepath.Join(sub, "skills")) {
		return root, sub, nil
	}
	return "", "", fmt.Errorf("could not locate nitays-agent-toolkit content; pass --source (and --repo-root), or run from the checkout or a repo with the submodule at .cursor/rules/shared")
}
