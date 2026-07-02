package syncer

const (
	gitignoreMarkerBegin = "# --- ai-coding-rules managed (auto; do not remove) ---"
	gitignoreMarkerEnd   = "# --- end ai-coding-rules managed ---"
)

// managedGitignoreBlock is appended to .gitignore. The ignore patterns
// (.agents/, *-workspace/) match the shell script exactly; the regenerate hint
// comment points at `acr` instead of the removed install.sh (intentional
// post-migration update — parity is asserted on the patterns, not comments).
const managedGitignoreBlock = "\n" +
	gitignoreMarkerBegin + "\n" +
	"# Regenerate managed skills: acr install\n" +
	".agents/\n" +
	"# Skill-creator / eval scratch dirs (not real skills)\n" +
	".claude/skills/*-workspace/\n" +
	gitignoreMarkerEnd + "\n"

// activeContextTemplate seeds a fresh memory dir (matches sync-rules.sh).
const activeContextTemplate = `# Active Context
## Current Focus
(No active task)

## Recent Decisions
- Setup complete

## Scratchpad
Use this space for temporary notes.
`

// eccGitignoreBlock matches the ECC session/hook-log paths appended verbatim.
const eccGitignoreBlock = `
# ECC: agent sessions + hook logs
.claude/sessions/
.claude/hooks/logs/
`

// capitalize upper-cases the first byte (ASCII), matching the shell's
// "${item_type^}" used for log headers (skill -> Skill).
func capitalize(s string) string {
	if s == "" {
		return s
	}
	b := []byte(s)
	if b[0] >= 'a' && b[0] <= 'z' {
		b[0] -= 'a' - 'A'
	}
	return string(b)
}
