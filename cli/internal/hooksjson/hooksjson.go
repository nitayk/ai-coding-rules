// Package hooksjson reproduces the jq pipelines in sync-rules.sh that merge,
// filter, and inject hooks configuration. It operates on decoded JSON
// (map[string]any) so callers can compare results semantically rather than
// byte-for-byte (Go's encoder and jq format differently, but the data matches).
package hooksjson

import (
	"encoding/json"
	"fmt"
	"os"
	"sort"
	"strings"
)

// Object is a decoded JSON object.
type Object = map[string]any

// Load reads and decodes a JSON file into an Object.
func Load(path string) (Object, error) {
	data, err := os.ReadFile(path)
	if err != nil {
		return nil, err
	}
	var obj Object
	if err := json.Unmarshal(data, &obj); err != nil {
		return nil, fmt.Errorf("invalid JSON %s: %w", path, err)
	}
	return obj, nil
}

// Write encodes obj to path with 2-space indentation and a trailing newline.
func Write(path string, obj Object) error {
	data, err := json.MarshalIndent(obj, "", "  ")
	if err != nil {
		return err
	}
	return os.WriteFile(path, append(data, '\n'), 0o644)
}

// Valid reports whether path contains valid JSON (absent file is treated as
// valid, matching validate_json).
func Valid(path string) bool {
	data, err := os.ReadFile(path)
	if err != nil {
		return true
	}
	return json.Valid(data)
}

// MergeReshape reproduces merge_hooks_json's jq reshape for the case where both
// a shared and repo hooks.json exist: it returns {version, hooks} where version
// falls back shared→repo→1 and each hook key concatenates shared+repo arrays
// with duplicate entries removed (first occurrence wins).
func MergeReshape(shared, repo Object) Object {
	version := firstNonNil(shared["version"], repo["version"], float64(1))
	sharedHooks := asObject(shared["hooks"])
	repoHooks := asObject(repo["hooks"])

	keys := unionKeys(sharedHooks, repoHooks)
	merged := Object{}
	for _, k := range keys {
		merged[k] = dedupeConcat(asSlice(sharedHooks[k]), asSlice(repoHooks[k]))
	}
	return Object{"version": version, "hooks": merged}
}

// FilterForTarget deletes the hook keys that do not apply to the given target,
// mirroring filter_hooks_json_for_target. Unknown targets are left untouched.
func FilterForTarget(obj Object, target string) {
	hooks := asObject(obj["hooks"])
	if hooks == nil {
		return
	}
	var drop []string
	switch target {
	case "cursor":
		drop = []string{"SessionStart", "PreToolUse", "PostToolUse", "PreCompact", "Stop"}
	case "claude":
		drop = []string{"postToolUse", "sessionStart", "stop"}
	default:
		return
	}
	for _, k := range drop {
		delete(hooks, k)
	}
	obj["hooks"] = hooks
}

// ResolvePluginRoot replaces "${CLAUDE_PLUGIN_ROOT}/hooks/" with hooksDir+"/" in
// every command string, matching the sed step in the claude branch.
func ResolvePluginRoot(obj Object, hooksDir string) {
	const token = "${CLAUDE_PLUGIN_ROOT}/hooks/"
	replacement := strings.TrimSuffix(hooksDir, "/") + "/"
	replaceInStrings(obj, func(s string) string {
		return strings.ReplaceAll(s, token, replacement)
	})
}

// HasPluginRoot reports whether any string in obj references CLAUDE_PLUGIN_ROOT.
func HasPluginRoot(obj Object) bool {
	found := false
	replaceInStrings(obj, func(s string) string {
		if strings.Contains(s, "CLAUDE_PLUGIN_ROOT") {
			found = true
		}
		return s
	})
	return found
}

// InjectHooks merges the hooks map of src into settings, concatenating arrays
// per key with duplicate entries removed (first occurrence wins). Other settings
// keys are preserved. Mirrors the settings.json jq merge.
func InjectHooks(settings, src Object) {
	existing := asObject(settings["hooks"])
	if existing == nil {
		existing = Object{}
	}
	incoming := asObject(src["hooks"])
	keys := unionKeys(existing, incoming)
	merged := Object{}
	for _, k := range keys {
		merged[k] = dedupeConcat(asSlice(existing[k]), asSlice(incoming[k]))
	}
	settings["hooks"] = merged
}

// --- helpers ---

func firstNonNil(vals ...any) any {
	for _, v := range vals {
		if v != nil {
			return v
		}
	}
	return nil
}

func asObject(v any) Object {
	if m, ok := v.(Object); ok {
		return m
	}
	return nil
}

func asSlice(v any) []any {
	if s, ok := v.([]any); ok {
		return s
	}
	return nil
}

// unionKeys returns the sorted union of keys, matching jq's `(keys + keys |
// unique)` which sorts.
func unionKeys(a, b Object) []string {
	set := map[string]bool{}
	for k := range a {
		set[k] = true
	}
	for k := range b {
		set[k] = true
	}
	out := make([]string, 0, len(set))
	for k := range set {
		out = append(out, k)
	}
	sort.Strings(out)
	return out
}

// dedupeConcat concatenates a+b and drops later entries equal to an earlier one
// (deep equality via canonical JSON), matching the jq reduce/index dedupe.
func dedupeConcat(a, b []any) []any {
	out := []any{}
	seen := map[string]bool{}
	for _, item := range append(append([]any{}, a...), b...) {
		key := canonical(item)
		if seen[key] {
			continue
		}
		seen[key] = true
		out = append(out, item)
	}
	return out
}

func canonical(v any) string {
	data, _ := json.Marshal(v)
	return string(data)
}

// replaceInStrings applies fn to every string value nested in v (objects,
// arrays, and scalars), in place.
func replaceInStrings(v any, fn func(string) string) {
	switch t := v.(type) {
	case Object:
		for k, val := range t {
			if s, ok := val.(string); ok {
				t[k] = fn(s)
			} else {
				replaceInStrings(val, fn)
			}
		}
	case []any:
		for i, val := range t {
			if s, ok := val.(string); ok {
				t[i] = fn(s)
			} else {
				replaceInStrings(val, fn)
			}
		}
	}
}
