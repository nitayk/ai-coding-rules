package skillgroups

import (
	"os"
	"path/filepath"
	"reflect"
	"testing"
)

const sampleConfig = `# comment
defaults: all
exclude_from_defaults: scala

agent_groups:
  core:
    - architect
    - reviewer
  golang:
    - go-reviewer

rule_groups:
  # none

groups:
  core:
    - brainstorming
    - planning
  git:
    - git-workflow
  scala:
    - scala-upgrade
    - scala-testing
`

// writeFixture creates a config file and a skills/agents tree on disk.
func writeFixture(t *testing.T, skills, agents []string) (cfg, skillsDir, agentsDir string) {
	t.Helper()
	root := t.TempDir()
	cfg = filepath.Join(root, "skill-groups.yaml")
	if err := os.WriteFile(cfg, []byte(sampleConfig), 0o644); err != nil {
		t.Fatal(err)
	}
	skillsDir = filepath.Join(root, "skills")
	for _, s := range skills {
		d := filepath.Join(skillsDir, s)
		if err := os.MkdirAll(d, 0o755); err != nil {
			t.Fatal(err)
		}
		if err := os.WriteFile(filepath.Join(d, "SKILL.md"), []byte("x"), 0o644); err != nil {
			t.Fatal(err)
		}
	}
	agentsDir = filepath.Join(root, "agents")
	_ = os.MkdirAll(agentsDir, 0o755)
	for _, a := range agents {
		if err := os.WriteFile(filepath.Join(agentsDir, a+".md"), []byte("x"), 0o644); err != nil {
			t.Fatal(err)
		}
	}
	return cfg, skillsDir, agentsDir
}

func TestResolveSkills_AllShortcut(t *testing.T) {
	f, warns := ResolveSkills("all", "", "/nonexistent", "/nonexistent")
	if !f.All {
		t.Fatalf("expected All=true")
	}
	if len(warns) != 0 {
		t.Fatalf("unexpected warnings: %v", warns)
	}
}

func TestResolveSkills_MissingConfig(t *testing.T) {
	f, warns := ResolveSkills("defaults", "", "/nonexistent.yaml", "/nonexistent")
	if !f.All {
		t.Fatalf("missing config should fall back to all")
	}
	if len(warns) == 0 {
		t.Fatalf("expected a warning about missing config")
	}
}

func TestResolveSkills_DefaultsExcludesScala(t *testing.T) {
	// defaults: all, exclude_from_defaults: scala -> all on-disk skills minus the
	// scala group members.
	cfg, skillsDir, _ := writeFixture(t,
		[]string{"brainstorming", "planning", "git-workflow", "scala-upgrade", "scala-testing", "loner"}, nil)
	f, warns := ResolveSkills("defaults", "", cfg, skillsDir)
	if len(warns) != 0 {
		t.Fatalf("unexpected warnings: %v", warns)
	}
	if f.All {
		t.Fatalf("expected a concrete set, got All")
	}
	got := f.Names()
	want := []string{"brainstorming", "git-workflow", "loner", "planning"}
	if !reflect.DeepEqual(got, want) {
		t.Fatalf("defaults set mismatch\n got: %v\nwant: %v", got, want)
	}
	if f.Allowed("scala-upgrade") {
		t.Fatalf("scala-upgrade should be excluded by default")
	}
	if !f.Allowed("loner") {
		t.Fatalf("ungrouped skill present on disk should be allowed under defaults")
	}
}

func TestResolveSkills_SpecificGroups(t *testing.T) {
	cfg, skillsDir, _ := writeFixture(t, []string{"brainstorming", "planning", "git-workflow"}, nil)
	f, _ := ResolveSkills("core,git", "", cfg, skillsDir)
	got := f.Names()
	want := []string{"brainstorming", "git-workflow", "planning"}
	if !reflect.DeepEqual(got, want) {
		t.Fatalf("group set mismatch\n got: %v\nwant: %v", got, want)
	}
}

func TestResolveSkills_UnknownGroupWarns(t *testing.T) {
	cfg, skillsDir, _ := writeFixture(t, []string{"brainstorming"}, nil)
	_, warns := ResolveSkills("core,bogus", "", cfg, skillsDir)
	if len(warns) == 0 {
		t.Fatalf("expected unknown-group warning")
	}
}

func TestResolveSkills_ExplicitExclude(t *testing.T) {
	cfg, skillsDir, _ := writeFixture(t, []string{"brainstorming", "planning", "git-workflow"}, nil)
	f, _ := ResolveSkills("core,git", "git", cfg, skillsDir)
	if f.Allowed("git-workflow") {
		t.Fatalf("git-workflow should be excluded")
	}
	if !f.Allowed("brainstorming") {
		t.Fatalf("brainstorming should remain")
	}
}

func TestResolveAgents_DefaultsAllNoScalaGroup(t *testing.T) {
	// There is no scala agent group, so defaults (exclude scala) keeps every
	// on-disk agent except README/UPDATE.
	cfg, _, agentsDir := writeFixture(t, nil, []string{"architect", "reviewer", "go-reviewer", "README", "UPDATE"})
	f, _ := ResolveAgents("defaults", "", cfg, agentsDir)
	got := f.Names()
	want := []string{"architect", "go-reviewer", "reviewer"}
	if !reflect.DeepEqual(got, want) {
		t.Fatalf("agent defaults mismatch\n got: %v\nwant: %v", got, want)
	}
}

func TestResolveAgents_SpecificGroupStopsAtNextSection(t *testing.T) {
	// agent_groups terminates at the next top-level key (rule_groups:), so the
	// "core" entries under groups: must not leak into agent resolution.
	cfg, _, agentsDir := writeFixture(t, nil, []string{"architect", "reviewer", "go-reviewer"})
	f, _ := ResolveAgents("core", "", cfg, agentsDir)
	got := f.Names()
	want := []string{"architect", "reviewer"}
	if !reflect.DeepEqual(got, want) {
		t.Fatalf("agent core group mismatch\n got: %v\nwant: %v", got, want)
	}
}
