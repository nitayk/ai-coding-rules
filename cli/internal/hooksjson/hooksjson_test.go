package hooksjson

import (
	"encoding/json"
	"reflect"
	"testing"
)

func obj(jsonStr string) Object {
	var o Object
	if err := json.Unmarshal([]byte(jsonStr), &o); err != nil {
		panic(err)
	}
	return o
}

func TestMergeReshape_DedupesAndAddsVersion(t *testing.T) {
	shared := obj(`{"hooks":{"A":[{"x":1}]}}`)
	repo := obj(`{"hooks":{"A":[{"x":1}],"B":[{"y":2}]}}`)
	got := MergeReshape(shared, repo)

	if got["version"] != float64(1) {
		t.Fatalf("expected version 1, got %v", got["version"])
	}
	hooks := got["hooks"].(Object)
	if a := hooks["A"].([]any); len(a) != 1 {
		t.Fatalf("expected A deduped to 1 entry, got %d", len(a))
	}
	if b := hooks["B"].([]any); len(b) != 1 {
		t.Fatalf("expected B with 1 entry, got %d", len(b))
	}
}

func TestMergeReshape_KeepsExistingVersion(t *testing.T) {
	shared := obj(`{"version":3,"hooks":{}}`)
	repo := obj(`{"hooks":{}}`)
	if got := MergeReshape(shared, repo); got["version"] != float64(3) {
		t.Fatalf("expected version 3, got %v", got["version"])
	}
}

func TestFilterForTarget_Cursor(t *testing.T) {
	o := obj(`{"hooks":{"SessionStart":[1],"PreToolUse":[2],"keepMe":[3]}}`)
	FilterForTarget(o, "cursor")
	hooks := o["hooks"].(Object)
	if _, ok := hooks["SessionStart"]; ok {
		t.Fatalf("SessionStart should be filtered for cursor")
	}
	if _, ok := hooks["PreToolUse"]; ok {
		t.Fatalf("PreToolUse should be filtered for cursor")
	}
	if _, ok := hooks["keepMe"]; !ok {
		t.Fatalf("unrelated key should be preserved")
	}
}

func TestFilterForTarget_Claude(t *testing.T) {
	o := obj(`{"hooks":{"SessionStart":[1],"sessionStart":[2],"stop":[3]}}`)
	FilterForTarget(o, "claude")
	hooks := o["hooks"].(Object)
	if _, ok := hooks["SessionStart"]; !ok {
		t.Fatalf("PascalCase SessionStart should survive claude filter")
	}
	if _, ok := hooks["sessionStart"]; ok {
		t.Fatalf("camelCase sessionStart should be filtered for claude")
	}
	if _, ok := hooks["stop"]; ok {
		t.Fatalf("stop should be filtered for claude")
	}
}

func TestResolvePluginRoot(t *testing.T) {
	o := obj(`{"hooks":{"SessionStart":[{"hooks":[{"command":"${CLAUDE_PLUGIN_ROOT}/hooks/session-start.sh"}]}]}}`)
	if !HasPluginRoot(o) {
		t.Fatalf("expected HasPluginRoot true")
	}
	ResolvePluginRoot(o, ".claude/hooks")
	if HasPluginRoot(o) {
		t.Fatalf("plugin root should be resolved away")
	}
	got := o["hooks"].(Object)["SessionStart"].([]any)[0].(Object)["hooks"].([]any)[0].(Object)["command"]
	if got != ".claude/hooks/session-start.sh" {
		t.Fatalf("unexpected resolved command: %v", got)
	}
}

func TestInjectHooks_MergesPreservingOtherKeys(t *testing.T) {
	settings := obj(`{"permissions":{"deny":["x"]},"hooks":{"A":[{"a":1}]}}`)
	src := obj(`{"hooks":{"A":[{"a":1}],"B":[{"b":2}]}}`)
	InjectHooks(settings, src)

	if !reflect.DeepEqual(settings["permissions"], obj(`{"permissions":{"deny":["x"]}}`)["permissions"]) {
		t.Fatalf("permissions should be preserved: %v", settings["permissions"])
	}
	hooks := settings["hooks"].(Object)
	if len(hooks["A"].([]any)) != 1 {
		t.Fatalf("A should dedupe to 1 entry")
	}
	if len(hooks["B"].([]any)) != 1 {
		t.Fatalf("B should be injected")
	}
}

func TestInjectHooks_NoExistingHooks(t *testing.T) {
	settings := obj(`{"model":"opus"}`)
	src := obj(`{"hooks":{"A":[{"a":1}]}}`)
	InjectHooks(settings, src)
	if settings["model"] != "opus" {
		t.Fatalf("unrelated settings key dropped")
	}
	if _, ok := settings["hooks"].(Object)["A"]; !ok {
		t.Fatalf("hooks not injected")
	}
}
