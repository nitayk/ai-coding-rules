package cmd

import (
	"github.com/nitayk/ai-coding-rules/cli/internal/installer"
	"github.com/nitayk/ai-coding-rules/cli/internal/ui"
	"github.com/spf13/cobra"
)

func newInstallCmd() *cobra.Command {
	var (
		target   string
		skills   string
		noSkills string
		profile  string
		useCopy  bool
		dryRun   bool
	)
	cmd := &cobra.Command{
		Use:   "install",
		Short: "Set up the submodule, sync, and install the post-merge hook",
		Long: `Install is the one-shot setup for a consumer repo. It reconciles the
.cursor/rules/shared submodule, runs a Claude Code sync, and installs a
post-merge git hook so syncs happen automatically after 'git pull'.

Run from inside the ai-coding-rules checkout itself, it skips the submodule and
hook steps and just runs a sync.

Note: the submodule always lives at .cursor/rules/shared — a Claude-safe
location (Claude Code ignores .cursor/), never under .claude/rules/, which would
explode Claude Code's context.`,
		Example: `  acr install                        # set up + sync Claude Code
  acr install --dry-run              # Preview changes`,
		Args: cobra.NoArgs,
		RunE: func(c *cobra.Command, args []string) error {
			return installer.Run(installer.Options{
				Target:         target,
				SkillsFilter:   skills,
				NoSkillsFilter: noSkills,
				Profile:        profile,
				UseSymlinks:    !useCopy,
				DryRun:         dryRun,
				Log:            ui.New(verbose),
			})
		},
	}
	cmd.Flags().StringVar(&target, "target", "claude", "deploy target (only claude is supported)")
	cmd.Flags().StringVar(&skills, "skills", "defaults", "comma-separated skill groups to sync, or 'all'")
	cmd.Flags().StringVar(&noSkills, "no-skills", "", "comma-separated skill groups to exclude")
	cmd.Flags().StringVar(&profile, "profile", "", "only 'generic' is supported (default)")
	cmd.Flags().BoolVar(&useCopy, "copy", false, "copy files instead of symlinking")
	cmd.Flags().BoolVar(&dryRun, "dry-run", false, "show what would be done without making changes")
	return cmd
}
