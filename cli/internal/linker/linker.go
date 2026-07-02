// Package linker symlinks an ai-coding-rules checkout into a consumer project,
// porting link-to-project.sh. One clone, many projects.
package linker

import (
	"fmt"
	"os"
	"path/filepath"

	"github.com/nitayk/ai-coding-rules/cli/internal/fsx"
	"github.com/nitayk/ai-coding-rules/cli/internal/ui"
)

// Options configures a link run.
type Options struct {
	// Source is the absolute path to the ai-coding-rules checkout to link from
	// (the shell script used its own location, SCRIPT_DIR).
	Source string
	// ProjectDir is the consumer project to link into ("." allowed).
	ProjectDir string
	DryRun     bool
	Log        *ui.Logger
}

// Run links the source into the project for the selected targets.
func Run(o Options) error {
	if o.ProjectDir == "" {
		return fmt.Errorf("please provide a project directory")
	}
	projAbs, err := filepath.Abs(o.ProjectDir)
	if err != nil || !fsx.IsDir(projAbs) {
		return fmt.Errorf("directory %q does not exist", o.ProjectDir)
	}
	src := o.Source
	if src == "" {
		if src, err = os.Getwd(); err != nil {
			return err
		}
	}
	src, err = filepath.Abs(src)
	if err != nil {
		return err
	}

	o.Log.Plain("Linking ai-coding-rules into: %s", projAbs)
	o.Log.Plain("Source: %s", src)
	o.Log.Plain("")

	// The submodule/checkout always lives at .cursor/rules/shared — a
	// Claude-safe location (Claude Code ignores .cursor/), which avoids
	// exploding Claude Code's context under .claude/.
	o.linkOne(projAbs, src, ".cursor/rules/shared", "install via: acr sync")

	o.Log.Plain("")
	o.Log.Plain("Done! Remember to add to .gitignore if needed:")
	o.Log.Plain("  .cursor/rules/shared  # symlink to global ai-coding-rules")
	return nil
}

// linkOne creates one symlink target, preserving the script's skip/warn cases:
// an existing symlink is reported and left alone; an existing real directory is
// a warning (manual removal required); otherwise the symlink is created.
func (o Options) linkOne(projAbs, src, rel, next string) {
	target := filepath.Join(projAbs, rel)
	switch {
	case fsx.IsSymlink(target):
		cur, _ := os.Readlink(target)
		o.Log.Warn("[skip] %s already linked -> %s", rel, cur)
	case fsx.IsDir(target):
		o.Log.Warn("[warn] %s exists as a directory (not a symlink).", rel)
		o.Log.Plain("       Remove it first if you want to link: rm -rf %s", target)
	default:
		if o.DryRun {
			o.Log.Info("Would link %s -> %s", rel, src)
		} else {
			if err := fsx.EnsureDir(filepath.Dir(target)); err != nil {
				o.Log.Error("failed to create %s: %v", filepath.Dir(target), err)
				return
			}
			if err := os.Symlink(src, target); err != nil {
				o.Log.Error("failed to link %s: %v", rel, err)
				return
			}
			o.Log.Success("[ok] Linked %s -> %s", rel, src)
		}
	}
	o.Log.Plain("")
	o.Log.Plain("Next: cd %s && %s", projAbs, next)
}
