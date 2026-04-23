---
name: review-as-reviewer
description: "Google-style code review from the reviewer's perspective. Use when reviewing someone else's PR, pull request, or code changes. Triggers on: 'review-as-reviewer', 'review this PR', 'review this pull request', 'code review', 'review their changes'. Do NOT use for self-reviewing your own code before commit (use review-as-author), code cleanup (use code-cleanup), or general review methodology guidance (use code-review-excellence)."
---

# Google-Style Code Review (Reviewer)

Review code changes from the reviewer's perspective using Google's Engineering Practices (https://google.github.io/eng-practices/review/reviewer/). Provides structured, actionable feedback that improves code health while respecting the author's effort.

## When to Use

**APPLY WHEN:**
- Reviewing someone else's PR or code changes
- Performing a formal code review on a pull request
- Reviewing a teammate's branch before merge

**DO NOT USE WHEN:**
- Self-reviewing your own changes before commit (use `review-as-author`)
- Cleaning up code without review intent (use `code-cleanup`)
- Learning general review methodology (use `code-review-excellence`)

## Workflow

### Step 1: Gather the Changes

```bash
# If reviewing a PR
gh pr diff <PR_NUMBER>
gh pr view <PR_NUMBER>

# If reviewing a branch
git diff main...<branch>

# If reviewing recent commits
git diff HEAD~N
```

Also read the PR description / commit messages to understand the author's intent.

### Step 2: Three-Pass Review (Navigate the CL)

Follow Google's three-step review process:

**Pass 1 - Broad Assessment:**
- Read the CL description. Does this change make sense at all?
- If the change shouldn't have happened, respond immediately and courteously: "Looks like you put some good work into this, thanks! However, [reason this approach won't work]."
- Check: Is the scope appropriate? Is now the right time?

**Pass 2 - Examine Primary Components:**
- Identify the file(s) with the main logical changes
- Review these first -- they give context for everything else
- If you find a major design problem, send feedback immediately. Don't wait to finish the full review. The author may be building on top of this.

**Pass 3 - Complete Review:**
- Go through all remaining files systematically
- Consider reading tests before implementation to understand intended behavior
- Check every line of human-written code

### Step 3: Report Findings

```
[SEVERITY] Category - file:line
Description of the issue
Suggested fix or direction (if helpful)
```

Severity levels:
- **[MUST FIX]** - Blocks approval. Code health would degrade if merged as-is.
- **[SHOULD FIX]** - Strong recommendation. Would improve the change meaningfully.
- **[Nit]** - Minor polish. Prefix with "Nit:" so the author knows it's optional.
- **[FYI]** - For the author's future reference. No action needed on this CL.
- **[GOOD]** - Positive callout. Acknowledge good work.

### Step 4: Verdict

- **LGTM** - Approve. The change improves code health.
- **LGTM with comments** - Approve, but author should consider the Nits. Use when confident the author will address them, or when comments are truly optional.
- **Request Changes** - Has MUST FIX items. Cannot merge as-is.

---

## The Standard of Code Review

The fundamental principle: **approve once the change definitely improves overall code health of the system, even if it isn't perfect.**

- There is no "perfect" code -- there is only better code
- Do not require the author to polish every tiny piece before approval
- Pursue continuous improvement, not perfection
- A CL that worsens overall code health must NEVER be approved (except emergencies)
- Codebases degrade through small decreases in health over time -- reviewers are the guardrail

**Decision-making priority (in order):**
1. Technical facts and data supersede opinions and personal preferences
2. Style guides are authoritative for style matters; unstated preferences should remain consistent with existing codebase patterns or defer to author choice
3. Software design is principle-based, not preference-based; when equally valid approaches exist, accept the author's choice
4. When no rule applies, request consistency with current codebase without worsening health

## What to Look For

### Design
- Is the overall design well-thought-out?
- Do the pieces interact cleanly with the rest of the system?
- Does this change belong here, or in a library?
- Does it integrate well with the system architecture?
- Is now the right time for this change?

### Functionality
- Does the code do what the author intended?
- Is the behavior good for users (end-users AND future developers)?
- Check edge cases, concurrency issues, potential bugs through code reading
- For parallel code: think about deadlocks, race conditions
- For UI changes: if possible, try the change. If not, think carefully about user impact
- Validation is most important for user-facing changes

### Complexity
Check at every level -- individual lines, functions, classes:
- Can the code be understood quickly by readers?
- Will developers likely introduce bugs when trying to call or modify this code?
- Watch for over-engineering: code more generic than needed, speculative features
- "Solve the problem you have now, not the one you might have in the future"

### Tests
- Are there appropriate unit, integration, or end-to-end tests?
- Are the tests correct and meaningful (not just testing themselves)?
- Will the tests actually fail when the code breaks?
- Do tests have clear, useful error messages?
- Tests are code too -- review them with the same rigor

### Naming
- Does every name communicate purpose adequately?
- Long enough to convey meaning, short enough to be readable?

### Comments
- Do comments explain WHY, not WHAT?
- Are comments reserved for information the code cannot express (reasoning behind decisions)?
- Flag unnecessary comments that restate obvious code
- Flag missing comments where reasoning is non-obvious

### Style & Consistency
- Does the code follow the project's style guide?
- Are style changes separated from functional changes? (If not, suggest splitting)
- Style guide rules are authoritative; unstated style is a consistency judgment

### Documentation
- If the change affects build, test, or release processes, is documentation updated?
- Are READMEs, API docs, or other relevant docs still accurate?

### Context
- Look at the change in the context of the broader file and system
- Don't accept changes that degrade the code health of surrounding code
- A few added lines may look fine in the diff but create confusion in the full file

### Good Things
- Acknowledge well-crafted code, clean solutions, thorough tests
- Don't only point out problems -- reinforcement of good patterns matters
- If you learned something from the code, tell the author

---

## Writing Effective Review Comments

### Be Kind
- Comment on the **code**, never the **developer**
- Bad: "Why did you use threads here? You clearly don't understand concurrency."
- Good: "The concurrency model here adds complexity without a clear performance benefit. This would be simpler as single-threaded."

### Explain Your Reasoning
- Don't just say "change this" -- explain why
- Reference best practices, principles, or concrete risks
- This educates the author and helps them make better decisions on future CLs

### Balance Directing vs. Problem-Identifying
- The author is responsible for the fix, not you
- Point out the problem and let them solve it -- they know the code better
- Provide direct guidance when it clearly helps and when author might struggle
- Letting authors problem-solve builds their skills

### Label Severity Clearly
- **"Nit:"** - minor, optional
- **"Optional:"** or **"Consider:"** - non-mandatory suggestion
- **"FYI:"** - for future reference, no action needed now
- Without a prefix, the author may assume every comment is mandatory -- causing unnecessary friction

### Don't Accept Explanations as Fixes
- If the author explains the code in a review comment, ask them to clarify the code itself (rename, restructure, add a code comment)
- "Explanations written only in the code review tool are not helpful to future code readers"
- Code comments are acceptable only when supplementing clarity, not justifying complexity

---

## Speed of Code Reviews

Optimize for **team velocity**, not individual speed.

- Respond shortly after receiving a review if not in focused work
- Maximum response time: **one business day** (first thing next morning)
- Multiple review rounds should happen within a single day when needed
- Don't interrupt deep coding to review -- respond at natural break points (task completion, lunch, meetings)
- Individual response speed matters more than total process duration -- quick responses reduce frustration even if the overall review takes longer

**When overwhelmed:**
- Indicate when you'll complete the full review
- Suggest alternative reviewers
- Provide initial broad comments so the author can start addressing them

**LGTM with comments is acceptable when:**
- You're confident the author will address remaining comments
- Remaining comments are minor (typos, import ordering, small style nits)
- This avoids unnecessary round-trip delays, especially across time zones

**For oversized CLs:**
- Ask the author to split into smaller, sequential CLs
- If truly unsplittable, provide design-level feedback first to unblock the author
- Never compromise review quality for speed -- strict reviews create long-term velocity

---

## Handling Pushback

When the author disagrees with your feedback:

1. **Consider their perspective** -- they may understand the code better than you
2. **Evaluate arguments on code health merits**, not personal preference
3. **Acknowledge when they're correct** -- change your mind when warranted
4. **When you're right, persist politely** -- show you understand their position but explain why yours matters: "I hear what you're saying, I just don't agree because [reason]"
5. **Tone matters more than strictness** -- most perceived harshness comes from tone, not standards

**"I'll clean it up later":**
- This rarely happens. Cleanup likelihood drops sharply after the CL merges
- Insist on fixing now unless it's a genuine emergency
- For pre-existing issues exposed by the change: author should file a bug and assign to themselves

**Conflict resolution escalation:**
1. Seek consensus through discussion
2. Move to face-to-face or video call
3. Involve the team for broader input
4. Escalate to tech lead if needed

**Never let a CL sit because reviewer and author can't agree.**

---

## CL Size Assessment (Reviewer Perspective)

If the CL is too large:
- You have discretion to **reject solely for being too large**
- Suggest specific splitting strategies to the author
- If unsplittable and time-constrained, provide design-level feedback first

A well-scoped CL:
- Addresses a single concern
- ~100 lines is reasonable; 1000+ is usually too large
- Includes related test code
- Does not mix refactoring with feature work

---

## Red Flags Checklist

Automatically flag if any of these are present:
- Code harder to read than necessary
- Duplicated logic that could be shared
- Names that don't communicate intent
- Missing error handling at system boundaries
- Security vulnerabilities (injection, XSS, auth bypass, hardcoded secrets)
- Performance issues (unnecessary allocations, N+1 queries, missing indexes)
- Missing or inadequate tests for changed logic
- Breaking changes without migration path
- TODO/FIXME without tracking issues
- Dead code, unused imports/variables
- Style changes mixed with logic changes in the same CL

## Gotchas / Common Pitfalls

- **Don't nitpick when there are real issues**: If there are MUST FIX items, focus energy there. A wall of Nits obscures critical feedback.
- **Review the diff, not the whole file**: Stay focused on what changed, but use surrounding context to judge impact.
- **Don't conflate preferences with standards**: Use "Nit:" for preferences. Reserve MUST FIX for things that would actually degrade code health.
- **Check test quality, not just existence**: Tests that don't assert meaningful behavior give false confidence.
- **Don't rubber-stamp large CLs**: Skimming a 500-line diff helps nobody. Ask the author to split it.
- **Acknowledge good work**: Reviews that only find problems are demoralizing. A quick "[GOOD] Clean abstraction here" costs nothing and reinforces good patterns.
- **Mentoring through reviews**: Code review is one of the best teaching tools. Share knowledge about languages, frameworks, and design principles -- but label educational comments as "Nit:" or "FYI:" so they don't block the CL.
