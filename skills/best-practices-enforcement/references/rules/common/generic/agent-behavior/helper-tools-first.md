# Helper Tools First

**Purpose**: Build narrowly scoped tools and scripts rather than attempting huge end-to-end automation immediately. Small tools compound into leverage.

## Triggers

**APPLY WHEN:** User asks for automation, repetitive task could be scripted, or considering complex multi-step automation.
**SKIP WHEN:** One-off manual task, or automation scope is already well-defined.

## Core Directive

**Start with small, focused tools.** People report good leverage from asking agents to build narrowly scoped tools/scripts. Avoid attempting huge end-to-end automation in one go.

## Rules

### 1. Narrow Scope First

**DO**: Build a script or tool that does one thing well.
- Parse one file format
- Transform one data shape
- Run one verification step

**STOP**: Designing a full pipeline before the first step works.

### 2. Compose Over Monolith

**DO**: Chain small tools. Output of one becomes input of another.
**STOP**: Building a single script that tries to do everything.

### 3. Validate Before Expanding

**DO**: Run and verify the small tool works before adding scope.
**STOP**: Adding features before the core works.

### 4. When to Expand

Expand scope only when:
- The narrow tool is proven useful
- User explicitly requests more
- The next step is clearly defined

## Related

- `critical-rules.md` - No temporary files; tools with permanent value are allowed
- `/code-cleanup` - Clean up agent-generated code

<!-- Cross-platform: see AGENTS.md in the repository root for deployment details. -->
