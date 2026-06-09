// Package cmd wires the cobra command tree. Each subcommand binds typed flags
// into an Options struct and delegates to an internal engine package; no
// business logic lives here.
package cmd

import (
	"fmt"
	"os"

	"github.com/spf13/cobra"
)

// verbose is the one persistent flag shared by every subcommand.
var verbose bool

func newRootCmd() *cobra.Command {
	root := &cobra.Command{
		Use:   "acr",
		Short: "ai-coding-rules installer/sync tooling",
		Long: `acr manages the ai-coding-rules shared submodule and the skills, agents,
commands, and hooks it deploys into Cursor and Claude Code projects.

It replaces the install.sh / sync-rules.sh / link-to-project.sh /
update-community.sh shell scripts with a single typed binary.`,
		SilenceUsage:  true,
		SilenceErrors: true,
	}
	root.PersistentFlags().BoolVarP(&verbose, "verbose", "v", false, "show detailed output")

	root.AddCommand(newInstallCmd())
	root.AddCommand(newSyncCmd())
	root.AddCommand(newLinkCmd())
	root.AddCommand(newUpdateCmd())
	return root
}

// Execute runs the root command and exits non-zero on error. The error is
// printed once here (commands set SilenceErrors) so wrapped error chains surface
// cleanly without cobra's usage dump.
func Execute() {
	if err := newRootCmd().Execute(); err != nil {
		fmt.Fprintf(os.Stderr, "\033[0;31m✗\033[0m %v\n", err)
		os.Exit(1)
	}
}
