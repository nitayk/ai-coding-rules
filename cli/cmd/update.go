package cmd

import (
	"github.com/nitayk/nitays-agent-toolkit/cli/internal/ui"
	"github.com/nitayk/nitays-agent-toolkit/cli/internal/updater"
	"github.com/spf13/cobra"
)

func newUpdateCmd() *cobra.Command {
	var (
		dryRun   bool
		showDiff bool
		repo     string
	)
	cmd := &cobra.Command{
		Use:   "update",
		Short: "Update vendored community skills from upstream",
		Long: `Update refreshes community skills, agents, commands, and hooks from upstream
sources into this checkout:

  obra/superpowers   -> skills/, agents/, commands/, hooks/
  anthropics/skills  -> skills/, spec/, template/

After running, review changes with 'git diff' and commit.`,
		Args: cobra.NoArgs,
		RunE: func(c *cobra.Command, args []string) error {
			return updater.Run(updater.Options{
				Repo:     repo,
				DryRun:   dryRun,
				ShowDiff: showDiff,
				Log:      ui.New(verbose),
			})
		},
	}
	cmd.Flags().BoolVar(&dryRun, "dry-run", false, "show what would change without applying")
	cmd.Flags().BoolVar(&showDiff, "diff", false, "show diffs before applying changes")
	cmd.Flags().StringVar(&repo, "repo", "", "nitays-agent-toolkit checkout to update (default: current directory)")
	return cmd
}
