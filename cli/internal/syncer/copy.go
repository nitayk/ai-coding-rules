package syncer

import (
	"path/filepath"

	"github.com/nitayk/ai-coding-rules/cli/internal/fsx"
)

// copyOrLink ports smart_copy for files: symlink when UseSymlinks, else copy
// (skipping identical files and never clobbering a non-symlink repo file unless
// --force).
func (r *runner) copyOrLink(source, dest, itemName string, executable bool) {
	if !fsx.Exists(source) || fsx.IsDir(source) {
		r.log.Error("Source file not found: %s", source)
		return
	}
	if r.o.UseSymlinks {
		r.createSymlink(source, dest, itemName)
		return
	}
	if fsx.Exists(dest) && !fsx.IsDir(dest) {
		if fsx.FilesIdentical(source, dest) {
			r.log.Verbosef("Skipping %s (already up to date)", itemName)
			return
		}
		if !fsx.IsSymlink(dest) && !r.o.Force {
			r.log.Warn("Skipping %s (repo-specific file exists, use --force to overwrite)", itemName)
			return
		}
		r.createBackup(dest)
	}
	if r.o.DryRun {
		r.log.Info("Would sync %s", itemName)
		return
	}
	if err := fsx.CopyFile(source, dest, executable); err != nil {
		r.log.Error("copy %s: %v", itemName, err)
		return
	}
	r.log.Success("Synced %s", itemName)
	r.log.Stats.Updated++
}

// createSymlink ports create_symlink: stores a relative symlink to source at
// dest, skipping when an existing symlink already points there and warning (not
// overwriting) when a non-symlink file occupies dest without --force.
func (r *runner) createSymlink(source, dest, itemName string) {
	if !fsx.LExists(source) {
		r.log.Error("Source not found: %s", source)
		return
	}
	destDir := filepath.Dir(dest)
	if !r.o.DryRun {
		_ = fsx.EnsureDir(destDir)
	}
	rel, err := fsx.RelSymlinkPath(source, destDir)
	if err != nil {
		r.log.Error("compute symlink path for %s: %v", itemName, err)
		return
	}
	if fsx.IsSymlink(dest) && fsx.SymlinkTargetsEqual(dest, rel) {
		r.log.Verbosef("Skipping %s (symlink already correct)", itemName)
		return
	}
	if fsx.Exists(dest) && !fsx.IsSymlink(dest) && !r.o.Force {
		r.log.Warn("Skipping %s (repo-specific file exists, use --force to overwrite)", itemName)
		return
	}
	if r.o.DryRun {
		r.log.Info("Would link %s → %s", itemName, rel)
		return
	}
	if err := fsx.ReplaceSymlink(rel, dest); err != nil {
		r.log.Error("link %s: %v", itemName, err)
		return
	}
	r.log.Success("Linked %s → %s", itemName, rel)
	r.log.Stats.Updated++
}

// copyDir ports smart_copy_dir with symlinks forced off (skills must be real
// directories). Skips when the directory's SKILL.md/README.md is identical, and
// won't clobber a repo-specific directory without --force.
func (r *runner) copyDir(source, dest, itemName string) {
	if !fsx.IsDir(source) {
		r.log.Error("Source directory not found: %s", source)
		return
	}
	if fsx.IsDir(dest) && !fsx.IsSymlink(dest) {
		mainFile := ""
		switch {
		case fsx.Exists(filepath.Join(source, "SKILL.md")):
			mainFile = "SKILL.md"
		case fsx.Exists(filepath.Join(source, "README.md")):
			mainFile = "README.md"
		}
		if mainFile != "" && fsx.Exists(filepath.Join(dest, mainFile)) &&
			fsx.FilesIdentical(filepath.Join(source, mainFile), filepath.Join(dest, mainFile)) {
			r.log.Verbosef("Skipping %s (already up to date)", itemName)
			return
		}
		if !r.o.Force {
			r.log.Warn("Skipping %s (repo-specific directory exists, use --force to overwrite)", itemName)
			return
		}
		r.createBackup(dest)
	}
	if r.o.DryRun {
		r.log.Info("Would sync %s", itemName)
		return
	}
	if err := fsx.CopyDir(source, dest); err != nil {
		r.log.Error("copy %s: %v", itemName, err)
		return
	}
	r.log.Success("Synced %s", itemName)
	r.log.Stats.Updated++
}

// createBackup ports create_backup (file-only; off unless --backup). Directory
// backups are silently skipped, matching the shell's `cp` (no -r) failure path.
func (r *runner) createBackup(file string) {
	if !r.o.Backup || r.o.DryRun {
		return
	}
	if !fsx.Exists(file) || fsx.IsDir(file) {
		return
	}
	_ = fsx.EnsureDir(r.backupDir)
	bf := filepath.Join(r.backupDir, filepath.Base(file)+".backup."+timestamp())
	if err := fsx.CopyFile(file, bf, false); err == nil {
		r.log.Verbosef("Backed up to: %s", bf)
	}
}
