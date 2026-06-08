package fsx

import (
	"os"
	"path/filepath"
	"testing"
)

func TestRelSymlinkPath(t *testing.T) {
	root := t.TempDir()
	source := filepath.Join(root, "src", "agents", "x.md")
	destDir := filepath.Join(root, "proj", ".cursor", "agents")
	rel, err := RelSymlinkPath(source, destDir)
	if err != nil {
		t.Fatal(err)
	}
	// Relative target must resolve back to the source.
	resolved := filepath.Clean(filepath.Join(destDir, rel))
	if resolved != source {
		t.Fatalf("rel %q resolves to %q, want %q", rel, resolved, source)
	}
}

func TestFilesIdentical(t *testing.T) {
	root := t.TempDir()
	a := filepath.Join(root, "a")
	b := filepath.Join(root, "b")
	c := filepath.Join(root, "c")
	_ = os.WriteFile(a, []byte("hello"), 0o644)
	_ = os.WriteFile(b, []byte("hello"), 0o644)
	_ = os.WriteFile(c, []byte("world"), 0o644)
	if !FilesIdentical(a, b) {
		t.Fatalf("a and b should be identical")
	}
	if FilesIdentical(a, c) {
		t.Fatalf("a and c should differ")
	}
	if FilesIdentical(a, filepath.Join(root, "missing")) {
		t.Fatalf("missing file should not be identical")
	}
}

func TestCopyDirAndDirsIdentical(t *testing.T) {
	root := t.TempDir()
	src := filepath.Join(root, "src")
	_ = os.MkdirAll(filepath.Join(src, "sub"), 0o755)
	_ = os.WriteFile(filepath.Join(src, "top.txt"), []byte("top"), 0o644)
	_ = os.WriteFile(filepath.Join(src, "sub", "inner.txt"), []byte("inner"), 0o644)

	dst := filepath.Join(root, "dst")
	if err := CopyDir(src, dst); err != nil {
		t.Fatal(err)
	}
	if !DirsIdentical(src, dst) {
		t.Fatalf("copied dir should be identical to source")
	}

	// CopyDir replaces an existing destination.
	_ = os.WriteFile(filepath.Join(dst, "stale.txt"), []byte("stale"), 0o644)
	if err := CopyDir(src, dst); err != nil {
		t.Fatal(err)
	}
	if Exists(filepath.Join(dst, "stale.txt")) {
		t.Fatalf("CopyDir should have removed stale file")
	}
}

func TestCopyDirRejectsEscapingSymlink(t *testing.T) {
	root := t.TempDir()
	src := filepath.Join(root, "src")
	_ = os.MkdirAll(src, 0o755)
	// An absolute symlink pointing outside the source tree must be refused.
	secret := filepath.Join(root, "secret.txt")
	_ = os.WriteFile(secret, []byte("s"), 0o644)
	if err := os.Symlink(secret, filepath.Join(src, "leak")); err != nil {
		t.Fatal(err)
	}
	if err := CopyDir(src, filepath.Join(root, "dst")); err == nil {
		t.Fatalf("expected CopyDir to refuse an escaping symlink")
	}
}

func TestCopyDirAllowsInTreeSymlink(t *testing.T) {
	root := t.TempDir()
	src := filepath.Join(root, "src")
	_ = os.MkdirAll(src, 0o755)
	_ = os.WriteFile(filepath.Join(src, "real.txt"), []byte("r"), 0o644)
	// A relative symlink that stays within the tree is fine.
	if err := os.Symlink("real.txt", filepath.Join(src, "alias")); err != nil {
		t.Fatal(err)
	}
	dst := filepath.Join(root, "dst")
	if err := CopyDir(src, dst); err != nil {
		t.Fatalf("in-tree symlink should be copied: %v", err)
	}
	if !IsSymlink(filepath.Join(dst, "alias")) {
		t.Fatalf("expected alias to be copied as a symlink")
	}
}

func TestFileContainsAndAppend(t *testing.T) {
	root := t.TempDir()
	gi := filepath.Join(root, ".gitignore")
	if FileContains(gi, "x") {
		t.Fatalf("missing file should not contain anything")
	}
	if err := AppendString(gi, "line-one\n"); err != nil {
		t.Fatal(err)
	}
	if err := AppendString(gi, "line-two\n"); err != nil {
		t.Fatal(err)
	}
	if !FileContains(gi, "line-one") || !FileContains(gi, "line-two") {
		t.Fatalf("appended lines not found")
	}
}

func TestSymlinkHelpers(t *testing.T) {
	root := t.TempDir()
	target := filepath.Join(root, "target.txt")
	_ = os.WriteFile(target, []byte("t"), 0o644)
	link := filepath.Join(root, "link")
	if err := ReplaceSymlink("target.txt", link); err != nil {
		t.Fatal(err)
	}
	if !IsSymlink(link) {
		t.Fatalf("expected a symlink")
	}
	if !SymlinkTargetsEqual(link, "target.txt") {
		t.Fatalf("symlink target should match")
	}
	if !SymlinkTargetsEqual(link, "./target.txt") {
		t.Fatalf("normalized symlink target should match")
	}
	// Replacing is idempotent and updates the target.
	if err := ReplaceSymlink("other.txt", link); err != nil {
		t.Fatal(err)
	}
	if SymlinkTargetsEqual(link, "target.txt") {
		t.Fatalf("symlink should now point elsewhere")
	}
}

func TestWalkFiles(t *testing.T) {
	root := t.TempDir()
	_ = os.MkdirAll(filepath.Join(root, "keep"), 0o755)
	_ = os.MkdirAll(filepath.Join(root, "skip"), 0o755)
	_ = os.WriteFile(filepath.Join(root, "a.sh"), []byte("x"), 0o644)
	_ = os.WriteFile(filepath.Join(root, "keep", "b.py"), []byte("x"), 0o644)
	_ = os.WriteFile(filepath.Join(root, "skip", "c.sh"), []byte("x"), 0o644)

	got, err := WalkFiles(root, func(rel string, info os.FileInfo) bool {
		return filepath.Dir(rel) != "skip"
	})
	if err != nil {
		t.Fatal(err)
	}
	if len(got) != 2 {
		t.Fatalf("expected 2 files, got %v", got)
	}
}
