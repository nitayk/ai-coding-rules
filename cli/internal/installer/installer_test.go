package installer

import (
	"io"
	"os"
	"path/filepath"
	"strings"
	"testing"

	"github.com/nitayk/ai-coding-rules/cli/internal/ui"
)

func quietLogger() *ui.Logger {
	return &ui.Logger{Out: io.Discard, Err: io.Discard}
}

// TestRunRejectsShellMetacharactersInFilters guards against the post-merge hook
// shell-injection vector: --skills / --no-skills values are interpolated into a
// generated shell script, so they must be rejected before any work happens.
func TestRunRejectsShellMetacharactersInFilters(t *testing.T) {
	cases := []struct {
		name           string
		skills, noSkip string
	}{
		{"backtick", "all`touch /tmp/x`", ""},
		{"dollar-paren", "x$(touch /tmp/x)", ""},
		{"semicolon", "a;b", ""},
		{"quote", `a"b`, ""},
		{"no-skills backtick", "defaults", "y`id`"},
	}
	for _, tc := range cases {
		tc := tc
		t.Run(tc.name, func(t *testing.T) {
			err := Run(Options{
				Target:         "cursor",
				SkillsFilter:   tc.skills,
				NoSkillsFilter: tc.noSkip,
				Log:            quietLogger(),
			})
			if err == nil {
				t.Fatalf("expected error for malicious filter %q/%q", tc.skills, tc.noSkip)
			}
			if !strings.Contains(err.Error(), "invalid characters") {
				t.Fatalf("expected an invalid-characters error, got: %v", err)
			}
		})
	}
}

func TestRunRejectsInvalidTarget(t *testing.T) {
	err := Run(Options{Target: "bogus", SkillsFilter: "defaults", Log: quietLogger()})
	if err == nil || !strings.Contains(err.Error(), "invalid --target") {
		t.Fatalf("expected invalid-target error, got: %v", err)
	}
}

func TestRunRejectsUnknownProfile(t *testing.T) {
	err := Run(Options{Target: "cursor", Profile: "weird", SkillsFilter: "defaults", Log: quietLogger()})
	if err == nil || !strings.Contains(err.Error(), "profile") {
		t.Fatalf("expected unknown-profile error, got: %v", err)
	}
}

// TestRunDryRunFreshConsumer covers the fresh-consumer dry-run: the submodule
// doesn't exist yet, so Run must preview every step (no error) and make no
// filesystem changes. Regression for the parity gap where it exited non-zero.
func TestRunDryRunFreshConsumer(t *testing.T) {
	repo := t.TempDir()
	if err := os.MkdirAll(filepath.Join(repo, ".git"), 0o755); err != nil {
		t.Fatal(err)
	}
	err := Run(Options{
		StartDir:     repo,
		Target:       "cursor",
		SkillsFilter: "defaults",
		DryRun:       true,
		Log:          quietLogger(),
	})
	if err != nil {
		t.Fatalf("dry-run on fresh consumer should not error, got: %v", err)
	}
	// Nothing beyond the .git dir we created should have been written.
	entries, _ := os.ReadDir(repo)
	for _, e := range entries {
		if e.Name() != ".git" {
			t.Fatalf("dry-run wrote unexpected entry: %s", e.Name())
		}
	}
}

func TestHookBlockUsesValidatedFilters(t *testing.T) {
	// With validated inputs, the generated hook references acr sync and the marker.
	o := Options{Target: "cursor,claude", SkillsFilter: "core,git"}
	block := o.hookBlock()
	if !strings.Contains(block, hookMarker) {
		t.Fatalf("hook block missing marker")
	}
	if !strings.Contains(block, "acr sync") {
		t.Fatalf("hook block should invoke acr sync")
	}
	if !strings.Contains(block, "--skills") {
		t.Fatalf("hook block should carry the skills filter")
	}
}
