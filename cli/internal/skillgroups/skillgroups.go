// Package skillgroups resolves --skills / --no-skills group selectors against
// config/skill-groups.yaml into a concrete set of skill or agent names.
//
// It reproduces the line-based YAML parsing in sync-rules.sh (no yq/python
// dependency): 2-space-indented keys ending in ":" are group names, and
// 4-space "- item" lines are members.
package skillgroups

import (
	"os"
	"path/filepath"
	"sort"
	"strings"
)

// Filter is the resolved selection. When All is true everything is allowed;
// otherwise only names in the set are allowed.
type Filter struct {
	All   bool
	items map[string]bool
}

// Allowed reports whether the given name is selected. The caller passes the
// bare name (skills: dir name; agents: file name without ".md").
func (f Filter) Allowed(name string) bool {
	if f.All {
		return true
	}
	return f.items[name]
}

// Names returns the selected names sorted (empty when All).
func (f Filter) Names() []string {
	out := make([]string, 0, len(f.items))
	for n := range f.items {
		out = append(out, n)
	}
	sort.Strings(out)
	return out
}

func setOf(names []string) Filter {
	m := make(map[string]bool, len(names))
	for _, n := range names {
		if n != "" {
			m[n] = true
		}
	}
	return Filter{items: m}
}

// ResolveSkills mirrors resolve_skill_filter. warnings carries non-fatal notes
// (unknown group / missing config) for the caller to surface.
func ResolveSkills(include, exclude, configPath, skillsDir string) (f Filter, warnings []string) {
	return resolve(include, exclude, configPath, "groups:", false, func() []string {
		return skillDirNames(skillsDir)
	})
}

// ResolveAgents mirrors resolve_agent_filter (parses the agent_groups: block,
// which terminates at the next top-level key).
func ResolveAgents(include, exclude, configPath, agentsDir string) (f Filter, warnings []string) {
	return resolve(include, exclude, configPath, "agent_groups:", true, func() []string {
		return agentFileNames(agentsDir)
	})
}

// resolve is the shared engine for both skill and agent filters.
//   - sectionHeader: the top-level key whose block holds the group→members map.
//   - sectionTerminates: agent_groups stops at the next top-level key; groups
//     runs to EOF (it is the final section), matching the shell behavior.
//   - enumerateAll: lists every candidate on disk for the "all" expansion.
func resolve(include, exclude, configPath, sectionHeader string, sectionTerminates bool, enumerateAll func() []string) (Filter, []string) {
	var warnings []string

	if include == "all" && exclude == "" {
		return Filter{All: true}, warnings
	}

	data, err := os.ReadFile(configPath)
	if err != nil {
		warnings = append(warnings, "Skill groups config not found: "+configPath+" — syncing all")
		return Filter{All: true}, warnings
	}
	lines := strings.Split(string(data), "\n")

	if include == "defaults" {
		defaultsVal := scalarValue(lines, "defaults:")
		if exclude == "" {
			if auto := scalarValue(lines, "exclude_from_defaults:"); auto != "" {
				exclude = auto
			}
		}
		if defaultsVal == "" || defaultsVal == "all" {
			if exclude == "" {
				return Filter{All: true}, warnings
			}
			include = "all"
		} else {
			include = defaultsVal
		}
	}

	include = strings.ReplaceAll(include, " ", "")
	exclude = strings.ReplaceAll(exclude, " ", "")
	if containsCSV(include, "all") {
		include = "all"
	}

	var all []string
	if include == "all" {
		all = enumerateAll()
	} else {
		incGroups := splitCSV(include)
		known := knownGroupNames(lines)
		for _, g := range incGroups {
			if !known[g] {
				warnings = append(warnings, "Unknown skill group: '"+g+"' (see config/skill-groups.yaml)")
			}
		}
		all = membersForGroups(lines, sectionHeader, sectionTerminates, incGroups)
	}

	if exclude != "" {
		excGroups := splitCSV(exclude)
		excludeSet := setOf(membersForGroups(lines, sectionHeader, sectionTerminates, excGroups))
		filtered := all[:0:0]
		for _, s := range all {
			if !excludeSet.items[s] {
				filtered = append(filtered, s)
			}
		}
		all = filtered
	}

	return setOf(dedupeSorted(all)), warnings
}

// scalarValue returns the value of a top-level "key: value" line (first match).
func scalarValue(lines []string, key string) string {
	for _, ln := range lines {
		if strings.HasPrefix(ln, key) {
			return strings.TrimSpace(strings.TrimPrefix(ln, key))
		}
	}
	return ""
}

// knownGroupNames collects every 2-space-indented key ending in ":" across the
// whole file (used only for the unknown-group warning, matching the shell).
func knownGroupNames(lines []string) map[string]bool {
	out := map[string]bool{}
	for _, ln := range lines {
		if name, ok := groupKey(ln); ok {
			out[name] = true
		}
	}
	return out
}

// membersForGroups walks the given section and returns members of any group in
// want, preserving discovery order (dedupe happens later).
func membersForGroups(lines []string, sectionHeader string, sectionTerminates bool, want []string) []string {
	wantSet := map[string]bool{}
	for _, g := range want {
		wantSet[g] = true
	}
	var out []string
	inSection := false
	current := ""
	for _, ln := range lines {
		trimmed := strings.TrimSpace(ln)
		if strings.HasPrefix(trimmed, "#") || trimmed == "" {
			continue
		}
		if ln == sectionHeader {
			inSection = true
			continue
		}
		if sectionTerminates && inSection && isTopLevelKey(ln) {
			inSection = false
			continue
		}
		if !inSection {
			continue
		}
		if name, ok := groupKey(ln); ok {
			current = name
			continue
		}
		if item, ok := listItem(ln); ok && current != "" {
			if wantSet[current] {
				out = append(out, item)
			}
		}
	}
	return out
}

// groupKey matches "  name:" (exactly two leading spaces, lowercase start).
func groupKey(ln string) (string, bool) {
	if len(ln) < 3 || ln[0] != ' ' || ln[1] != ' ' || ln[2] == ' ' {
		return "", false
	}
	if !(ln[2] >= 'a' && ln[2] <= 'z') {
		return "", false
	}
	if !strings.HasSuffix(ln, ":") {
		return "", false
	}
	return strings.TrimSuffix(strings.TrimSpace(ln), ":"), true
}

// listItem matches "    - item" (four leading spaces, dash, space).
func listItem(ln string) (string, bool) {
	if !strings.HasPrefix(ln, "    - ") {
		return "", false
	}
	return strings.TrimSpace(strings.TrimPrefix(strings.TrimSpace(ln), "- ")), true
}

// isTopLevelKey matches a line starting with a lowercase letter at column 0.
func isTopLevelKey(ln string) bool {
	return len(ln) > 0 && ln[0] >= 'a' && ln[0] <= 'z'
}

func splitCSV(s string) []string {
	if s == "" {
		return nil
	}
	parts := strings.Split(s, ",")
	out := parts[:0]
	for _, p := range parts {
		if p != "" {
			out = append(out, p)
		}
	}
	return out
}

func containsCSV(csv, want string) bool {
	for _, p := range strings.Split(csv, ",") {
		if p == want {
			return true
		}
	}
	return false
}

func dedupeSorted(in []string) []string {
	seen := map[string]bool{}
	var out []string
	for _, s := range in {
		if s != "" && !seen[s] {
			seen[s] = true
			out = append(out, s)
		}
	}
	sort.Strings(out)
	return out
}

// skillDirNames lists immediate subdirectories of dir that contain a SKILL.md.
func skillDirNames(dir string) []string {
	entries, err := os.ReadDir(dir)
	if err != nil {
		return nil
	}
	var out []string
	for _, e := range entries {
		if e.IsDir() {
			if _, err := os.Stat(filepath.Join(dir, e.Name(), "SKILL.md")); err == nil {
				out = append(out, e.Name())
			}
		}
	}
	return out
}

// agentFileNames lists *.md files in dir (without extension), excluding README
// and UPDATE — matching resolve_agent_filter's enumeration.
func agentFileNames(dir string) []string {
	entries, err := os.ReadDir(dir)
	if err != nil {
		return nil
	}
	var out []string
	for _, e := range entries {
		if e.IsDir() || !strings.HasSuffix(e.Name(), ".md") {
			continue
		}
		base := strings.TrimSuffix(e.Name(), ".md")
		if base == "README" || base == "UPDATE" {
			continue
		}
		out = append(out, base)
	}
	return out
}
