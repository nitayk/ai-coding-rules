package cmd

import (
	"github.com/nitayk/ai-coding-rules/cli/internal/linker"
	"github.com/nitayk/ai-coding-rules/cli/internal/ui"
	"github.com/spf13/cobra"
)

func newLinkCmd() *cobra.Command {
	var (
		claude bool
		both   bool
		cursor bool
		dryRun bool
		source string
	)
	cmd := &cobra.Command{
		Use:   "link <project-dir>",
		Short: "Symlink this ai-coding-rules checkout into a project",
		Long: `Link creates a symlink from a project's .cursor/rules/shared (and/or
.claude/rules/shared) to this ai-coding-rules checkout, instead of using a git
submodule. One clone, many projects; update once, all projects benefit.

After linking, run 'acr sync' from within the project to deploy skills/agents/
commands/hooks.`,
		Example: `  acr link ~/projects/my-app             # Cursor only (default)
  acr link ~/projects/my-app --both      # Cursor + Claude Code
  acr link .                             # Current directory`,
		Args: cobra.ExactArgs(1),
		RunE: func(c *cobra.Command, args []string) error {
			// Default is cursor-only; --claude flips to claude-only; --both does both;
			// --cursor forces cursor-only. Mirrors link-to-project.sh's flag handling.
			setCursor, setClaude := true, false
			switch {
			case both:
				setCursor, setClaude = true, true
			case claude:
				setCursor, setClaude = false, true
			case cursor:
				setCursor, setClaude = true, false
			}
			// An empty Source makes linker.Run default to the current directory.
			return linker.Run(linker.Options{
				Source:     source,
				ProjectDir: args[0],
				Cursor:     setCursor,
				Claude:     setClaude,
				DryRun:     dryRun,
				Log:        ui.New(verbose),
			})
		},
	}
	cmd.Flags().BoolVar(&claude, "claude", false, "link .claude/rules/shared only")
	cmd.Flags().BoolVar(&both, "both", false, "link both Cursor and Claude Code")
	cmd.Flags().BoolVar(&cursor, "cursor", false, "link .cursor/rules/shared only (default)")
	cmd.Flags().BoolVar(&dryRun, "dry-run", false, "show what would be done without making changes")
	cmd.Flags().StringVar(&source, "source", "", "path to the ai-coding-rules checkout (default: current directory)")
	return cmd
}
