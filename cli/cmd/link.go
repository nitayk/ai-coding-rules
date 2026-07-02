package cmd

import (
	"github.com/nitayk/nitays-agent-toolkit/cli/internal/linker"
	"github.com/nitayk/nitays-agent-toolkit/cli/internal/ui"
	"github.com/spf13/cobra"
)

func newLinkCmd() *cobra.Command {
	var (
		dryRun bool
		source string
	)
	cmd := &cobra.Command{
		Use:   "link <project-dir>",
		Short: "Symlink this nitays-agent-toolkit checkout into a project",
		Long: `Link creates a symlink from a project's .cursor/rules/shared to this
nitays-agent-toolkit checkout, instead of using a git submodule. One clone, many
projects; update once, all projects benefit.

The submodule/checkout lives at .cursor/rules/shared — a Claude-safe location
(Claude Code ignores .cursor/), which avoids exploding Claude Code's context.

After linking, run 'acr sync' from within the project to deploy skills/agents/
commands/hooks into .claude/.`,
		Example: `  acr link ~/projects/my-app             # link into .cursor/rules/shared
  acr link .                             # Current directory`,
		Args: cobra.ExactArgs(1),
		RunE: func(c *cobra.Command, args []string) error {
			// An empty Source makes linker.Run default to the current directory.
			return linker.Run(linker.Options{
				Source:     source,
				ProjectDir: args[0],
				DryRun:     dryRun,
				Log:        ui.New(verbose),
			})
		},
	}
	cmd.Flags().BoolVar(&dryRun, "dry-run", false, "show what would be done without making changes")
	cmd.Flags().StringVar(&source, "source", "", "path to the nitays-agent-toolkit checkout (default: current directory)")
	return cmd
}
