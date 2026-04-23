---
name: review-as-author
description: "Google-style self code review from the CL author's perspective. Use before committing or pushing changes to self-check your own code. Triggers on: 'review-as-author', 'self review', 'pre-commit review', 'review my changes', 'check before commit'. Do NOT use for reviewing others' PRs (use review-as-reviewer), code cleanup without review intent (use code-cleanup), or general code review guidance (use code-review-excellence)."
---

# Google-Style Self Code Review (Author)

Self-review your own changes from the CL author's perspective before committing, using Google's Engineering Practices (https://google.github.io/eng-practices/review/developer/).

The goal: catch issues before a human reviewer sees them, write a clean CL description, and ensure the change is well-scoped.

## When to Use

**APPLY WHEN:**
- Self-reviewing your changes before `git commit`
- Checking if your change is ready for human review
- Verifying CL size and scope before pushing
- Improving your commit message quality

**DO NOT USE WHEN:**
- Reviewing someone else's PR (use `review-as-reviewer`)
- Cleaning up debug artifacts only (use `code-cleanup`)
- You need general code review guidance (use `code-review-excellence`)

## Workflow

### Step 1: Gather Changes

```bash
# Staged + unstaged changes
git diff
git diff --cached

# If no changes found, review the most recent commit
git diff HEAD~1

# Recent commit context
git log --oneline -5
```

### Step 2: Self-Review Against All Author Criteria

Evaluate your own changes as if you were the reviewer. Go through every section below. Read every line of the diff.

### Step 3: Report Findings

```
[SEVERITY] Category - file:line
Description of the issue
Suggested fix (if applicable)
```

Severity levels:
- **[MUST FIX]** - Must be fixed before commit. A reviewer would block on this.
- **[SHOULD FIX]** - A reviewer would likely flag this. Fix unless there's a compelling reason.
- **[Nit]** - Minor polish. Optional but shows craftsmanship.
- **[GOOD]** - Something done well. Acknowledge it.

### Step 4: Verdict

- **Ready to commit** - No blockers, change is well-scoped.
- **Almost ready** - Minor items to address, but close.
- **Not ready** - Has MUST FIX items or fundamental scope/design issues.

---

## Author Self-Review Criteria

### 1. CL Description Quality

A CL description is a permanent public record of WHAT changed and WHY.

**First line requirements:**
- Short summary of the specific action taken
- Complete sentence in imperative form: "Delete the FizzBuzz RPC", not "Deleting" or "Deleted"
- Should stand alone in `git log --oneline`

**Body requirements:**
- Context about the problem being solved
- Why this approach was chosen over alternatives
- Any limitations or known issues
- Supporting info: bug numbers, benchmarks, design doc links
- Enough context for future readers (external links may become inaccessible)

**Red flags in descriptions - flag these immediately:**
- "Fix bug" / "Fix build" / "Add patch"
- "Moving code from A to B"
- "Phase 1" / "Add convenience functions" / "misc changes"
- "WIP" in a commit meant for review
- Empty or single-word descriptions

**Self-check:** Read your first line. Would a teammate scanning `git log` understand what this change does?

### 2. CL Size Assessment

Small CLs are reviewed faster, more thoroughly, and with fewer bugs.

**What "small" means:**
- One self-contained change addressing a single concern
- ~100 lines is reasonable; 1000+ is almost always too large
- Includes related test code
- Functions independently after submission

**Self-check questions:**
- Can I describe this change in one sentence without using "and"?
- Would a reviewer need more than 15-20 minutes to review this?
- Am I mixing refactoring with feature work?
- Am I mixing style changes with logic changes?

**If your CL is too large, split it:**
- Separate refactoring from feature changes (refactoring first)
- Split by files needing different review focus
- Split by layers (API definition, service logic, data access)
- Split independent features into separate commits
- Use stacking: submit one small CL, begin dependent work immediately

**When large CLs are acceptable:**
- Complete file deletions (minimal review needed)
- Automated refactoring tool output (reviewer verifies intent, not every line)

### 3. Design Self-Check

Before asking a reviewer to look at design, check yourself:
- Does this change belong in this codebase, or should it be a library?
- Does it integrate well with the existing system architecture?
- Is now the right time for this change?
- Are the pieces interacting cleanly with the rest of the system?
- If a reviewer said "this shouldn't have happened at all" - would they have a point?

### 4. Functionality Self-Check

- Does the code actually do what you intended?
- Walk through the code mentally as a user would use it
- Check edge cases: empty inputs, null values, boundary conditions
- For parallel code: think about deadlocks, race conditions
- For UI changes: did you actually test it visually?

### 5. Complexity Self-Check

- Can a teammate understand this code quickly on first read?
- Will someone likely introduce bugs when modifying this code later?
- Are you over-engineering? Building for a future problem you don't have yet?
- "Solve the problem you have now, not the one you might have later"
- If you need a comment to explain what code does, the code is probably too complex

### 6. Tests Self-Check

- Did you add/update tests for every changed behavior?
- Do your tests actually fail when the code breaks? (Test the tests)
- Are your test names descriptive of the scenario and expectation?
- Are you testing behavior, not implementation details?
- Do tests have clear error messages that help debug failures?

### 7. Naming Self-Check

- Does every new name communicate its purpose?
- Would a teammate reading this for the first time understand each name?
- Are names consistent with existing codebase conventions?

### 8. Comments Self-Check

- Do your comments explain WHY, not WHAT?
- Remove comments that just restate the code
- Add comments where the reasoning behind a decision is non-obvious
- Are there workarounds or subtle constraints that need explanation?

### 9. Style & Consistency

- Does the code follow the project's style guide?
- Did you keep style changes separate from functional changes?
- When the style guide is silent, are you consistent with surrounding code?

### 10. Documentation

- If you changed build, test, or release processes, did you update docs?
- Are READMEs, API docs, or other relevant docs still accurate?

---

## Pre-Commit Checklist

Run through this final checklist before committing:

- [ ] Commit message has a clear imperative first line + context body
- [ ] Change is focused on a single concern
- [ ] No debug code left (console.log, print, debugger, TODO)
- [ ] No unused imports, variables, or dead code
- [ ] No hardcoded secrets, keys, or credentials
- [ ] Tests added/updated for changed behavior
- [ ] Tests pass locally
- [ ] No unrelated formatting or style changes mixed in
- [ ] Documentation updated if behavior changed
- [ ] You would be comfortable if a teammate reviewed this right now

---

## Handling Future Reviewer Comments

When you get review feedback:
- **Don't take it personally** - reviewers are critiquing code, not you
- **Fix the code first** - if a reviewer doesn't understand your code, clarify the code itself (not just the review comment). Future readers need the same clarity
- **Think collaboratively** - the reviewer may see things you missed. Consider their perspective genuinely
- **Never respond in anger** - review comments are a permanent record
- If you disagree, respond with reasoning about trade-offs, not defensiveness

## Gotchas / Common Pitfalls

- **"I'll clean it up later"** - You almost certainly won't. Fix it now.
- **Mixing refactoring with features** - Split them. Reviewers can't verify correctness when behavior changes are tangled with structural changes.
- **Testing only the happy path** - Edge cases are where bugs live.
- **Enormous diffs** - A reviewer seeing 500+ lines will skim. You'll get worse feedback on a large CL than thorough feedback on a small one.
- **Vague commit messages** - "Update code" tells a future developer nothing. They'll `git blame` your line, read that message, and curse you.
