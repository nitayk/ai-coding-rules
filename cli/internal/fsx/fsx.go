// Package fsx holds filesystem primitives shared by the subcommands:
// relative-symlink computation, content-equality checks, and copy helpers.
// Policy (force/dry-run/skip-if-correct) lives in the calling engines so these
// stay pure and testable.
package fsx

import (
	"bytes"
	"errors"
	"fmt"
	"io"
	"io/fs"
	"os"
	"path/filepath"
	"strings"
)

// RelSymlinkPath returns the symlink target to store at destDir pointing to
// source, as a path relative to destDir. Mirrors the shell scripts' use of
// python3 os.path.relpath(source_abs, dest_dir_abs).
func RelSymlinkPath(source, destDir string) (string, error) {
	srcAbs, err := filepath.Abs(source)
	if err != nil {
		return "", err
	}
	destAbs, err := filepath.Abs(destDir)
	if err != nil {
		return "", err
	}
	return filepath.Rel(destAbs, srcAbs)
}

// IsSymlink reports whether path is a symlink (not following it).
func IsSymlink(path string) bool {
	fi, err := os.Lstat(path)
	if err != nil {
		return false
	}
	return fi.Mode()&os.ModeSymlink != 0
}

// Exists reports whether path exists (following symlinks).
func Exists(path string) bool {
	_, err := os.Stat(path)
	return err == nil
}

// LExists reports whether path exists as a dir entry (not following symlinks,
// so a dangling symlink counts as existing — matching shell `[ -e ]` on links
// via `[ -L ]`).
func LExists(path string) bool {
	_, err := os.Lstat(path)
	return err == nil
}

// IsDir reports whether path is a directory (following symlinks).
func IsDir(path string) bool {
	fi, err := os.Stat(path)
	return err == nil && fi.IsDir()
}

// FilesIdentical reports whether both files exist and have identical contents.
// Equivalent to the scripts' diff -q / checksum comparison.
func FilesIdentical(a, b string) bool {
	da, err := os.ReadFile(a)
	if err != nil {
		return false
	}
	db, err := os.ReadFile(b)
	if err != nil {
		return false
	}
	return bytes.Equal(da, db)
}

// DirsIdentical reports whether two directory trees are byte-for-byte identical
// (regular files only), equivalent to `diff -rq`.
func DirsIdentical(a, b string) bool {
	am, err := fileMap(a)
	if err != nil {
		return false
	}
	bm, err := fileMap(b)
	if err != nil {
		return false
	}
	if len(am) != len(bm) {
		return false
	}
	for rel, pa := range am {
		pb, ok := bm[rel]
		if !ok || !FilesIdentical(pa, pb) {
			return false
		}
	}
	return true
}

func fileMap(root string) (map[string]string, error) {
	out := map[string]string{}
	err := filepath.Walk(root, func(p string, info os.FileInfo, err error) error {
		if err != nil {
			return err
		}
		if info.IsDir() {
			return nil
		}
		rel, err := filepath.Rel(root, p)
		if err != nil {
			return err
		}
		out[rel] = p
		return nil
	})
	return out, err
}

// EnsureDir creates dir and parents if missing.
func EnsureDir(dir string) error {
	return os.MkdirAll(dir, 0o755)
}

// CopyFile copies src to dst (creating parent dirs), optionally chmod +x.
func CopyFile(src, dst string, executable bool) error {
	if err := EnsureDir(filepath.Dir(dst)); err != nil {
		return err
	}
	in, err := os.Open(src)
	if err != nil {
		return err
	}
	defer in.Close()
	mode := os.FileMode(0o644)
	if executable {
		mode = 0o755
	}
	out, err := os.OpenFile(dst, os.O_WRONLY|os.O_CREATE|os.O_TRUNC, mode)
	if err != nil {
		return err
	}
	if _, err := io.Copy(out, in); err != nil {
		out.Close()
		return err
	}
	if err := out.Close(); err != nil {
		return err
	}
	return os.Chmod(dst, mode)
}

// CopyDir recursively copies srcDir to dstDir after removing any existing dst,
// matching the scripts' `rm -rf dst && cp -r src dst`. Symlinks inside the tree
// are recreated as symlinks.
func CopyDir(srcDir, dstDir string) error {
	if err := os.RemoveAll(dstDir); err != nil {
		return err
	}
	return filepath.Walk(srcDir, func(p string, info os.FileInfo, err error) error {
		if err != nil {
			return err
		}
		rel, err := filepath.Rel(srcDir, p)
		if err != nil {
			return err
		}
		target := filepath.Join(dstDir, rel)
		switch {
		case info.IsDir():
			return os.MkdirAll(target, info.Mode().Perm()|0o700)
		case info.Mode()&os.ModeSymlink != 0:
			link, err := os.Readlink(p)
			if err != nil {
				return err
			}
			// Refuse symlinks that point outside the source tree. Absolute or
			// ../-escaping links in copied (possibly upstream) content could
			// otherwise smuggle a pointer to e.g. ~/.ssh into the destination.
			if symlinkEscapes(srcDir, p, link) {
				return fmt.Errorf("symlink %s → %s escapes source tree; refusing to copy", p, link)
			}
			if err := EnsureDir(filepath.Dir(target)); err != nil {
				return err
			}
			return os.Symlink(link, target)
		default:
			return CopyFile(p, target, info.Mode()&0o111 != 0)
		}
	})
}

// symlinkEscapes reports whether the symlink at linkPath (inside srcDir) with
// the given target resolves to a location outside srcDir.
func symlinkEscapes(srcDir, linkPath, target string) bool {
	resolved := target
	if !filepath.IsAbs(resolved) {
		resolved = filepath.Join(filepath.Dir(linkPath), target)
	}
	resolvedAbs, err := filepath.Abs(resolved)
	if err != nil {
		return true
	}
	srcAbs, err := filepath.Abs(srcDir)
	if err != nil {
		return true
	}
	rel, err := filepath.Rel(srcAbs, resolvedAbs)
	if err != nil {
		return true
	}
	return rel == ".." || strings.HasPrefix(rel, ".."+string(filepath.Separator))
}

// FileContains reports whether the file exists and contains the given substring
// (fixed-string match, like `grep -qF`).
func FileContains(path, substr string) bool {
	data, err := os.ReadFile(path)
	if err != nil {
		return false
	}
	return bytes.Contains(data, []byte(substr))
}

// AppendString appends text to a file, creating it if needed.
func AppendString(path, text string) error {
	if err := EnsureDir(filepath.Dir(path)); err != nil {
		return err
	}
	f, err := os.OpenFile(path, os.O_APPEND|os.O_CREATE|os.O_WRONLY, 0o644)
	if err != nil {
		return err
	}
	if _, err := io.WriteString(f, text); err != nil {
		f.Close()
		return err
	}
	return f.Close()
}

// SymlinkTargetsEqual reports whether an existing symlink at dest already points
// at the same location as relTarget (both resolved relative to dest's dir).
func SymlinkTargetsEqual(dest, relTarget string) bool {
	cur, err := os.Readlink(dest)
	if err != nil {
		return false
	}
	if cur == relTarget {
		return true
	}
	destDir := filepath.Dir(dest)
	return filepath.Clean(filepath.Join(destDir, cur)) ==
		filepath.Clean(filepath.Join(destDir, relTarget))
}

// ReplaceSymlink atomically replaces dest with a symlink to target.
func ReplaceSymlink(target, dest string) error {
	if err := EnsureDir(filepath.Dir(dest)); err != nil {
		return err
	}
	if err := os.Remove(dest); err != nil && !errors.Is(err, fs.ErrNotExist) {
		return err
	}
	return os.Symlink(target, dest)
}

// WalkFiles returns every regular/symlink file under root matching keep, with
// paths relative to root. Directories are descended; keep decides inclusion.
func WalkFiles(root string, keep func(relPath string, info os.FileInfo) bool) ([]string, error) {
	var out []string
	err := filepath.Walk(root, func(p string, info os.FileInfo, err error) error {
		if err != nil {
			return err
		}
		if info.IsDir() {
			return nil
		}
		rel, err := filepath.Rel(root, p)
		if err != nil {
			return err
		}
		if keep(rel, info) {
			out = append(out, rel)
		}
		return nil
	})
	if err != nil {
		return nil, fmt.Errorf("walk %s: %w", root, err)
	}
	return out, nil
}
