# ai-coding-rules

A curated, best-of-breed AI coding toolkit that combines top community skills with battle-tested workflows. Works as a git submodule for any project, instantly supercharging your AI-assisted development.

Built for **Claude Code**.

## What's Inside

| Category | Count | Source |
|----------|-------|--------|
| **Skills** | 103 | obra/superpowers, anthropics/skills, mobile-agent-toolkit, custom |
| **Agents** | 20 | architect, code-reviewer, verifier, and more |
| **Commands** | 14 | create-pr, fix-issue, evolve, and more |
| **Hooks** | 20+ | Quality, security, observability, ECC |
| **Core rules** | 7 | Prose standards in `rules/*.md` (referenced from `CLAUDE.md`) |

## Quick Start

### Option A: Per-project setup (recommended if you also use work repos)

Cleanest separation -- your personal tools stay in personal projects, zero
chance of mixing with org repos.

The shell scripts were replaced by a single Go CLI, **`acr`**. Build it once:

```bash
# One-time: clone to your home directory and build the CLI
git clone https://github.com/nitayk/ai-coding-rules.git ~/ai-coding-rules
cd ~/ai-coding-rules && go build -o ~/.local/bin/acr ./cli   # ensure ~/.local/bin is on PATH
```

See [`cli/README.md`](cli/README.md) for full command docs.

```bash
# Link the checkout into a project and deploy skills/agents/commands/hooks
acr link ~/projects/my-app
cd ~/projects/my-app && acr sync          # add --copy to copy instead of symlink

# Restart Claude Code -- done! 103 skills deployed into that project's .claude/.
```

To update a project later:
```bash
cd ~/ai-coding-rules && git pull && acr update   # refresh community sources
cd ~/projects/my-app && acr sync                 # re-deploy
```

### Option B: Git submodule (team/open-source projects)

Version-pinned assets committed to the project repo. `acr install` adds the
submodule, syncs, and installs a post-merge hook that re-syncs after `git pull`:

```bash
git submodule add https://github.com/nitayk/ai-coding-rules.git .cursor/rules/shared
go build -o ~/.local/bin/acr ./.cursor/rules/shared/cli
acr install
```

> The checkout lives at `.cursor/rules/shared` on purpose: Claude Code auto-loads
> everything under `.claude/`, so a submodule there would blow up the context
> window. Claude ignores `.cursor/`, making it a safe home for the checkout.

### What goes where

`acr sync` deploys into the project's `.claude/` directory:

| What | Location | How |
|------|----------|-----|
| **Skills** | `.claude/skills/` | Copied (Claude Code doesn't index symlinked skill trees) |
| **Agents** | `.claude/agents/` | Symlinked by default (`--copy` to copy) |
| **Commands** | `.claude/commands/` | Symlinked by default (`--copy` to copy) |
| **Hooks** | `.claude/hooks/` + `.claude/hooks.json` | Merged |

## Skills Inventory

### Planning & Design
| Skill | Description |
|-------|-------------|
| `brainstorming` | Socratic design refinement before coding |
| `writing-plans` | Break work into 2-5 min bite-sized tasks |
| `executing-plans` | Batch execution with human checkpoints |
| `prd-generation` | PRD generation via structured conversation |
| `task-breakdown` | Break PRDs into parent tasks and sub-tasks |

### Development Workflows
| Skill | Description |
|-------|-------------|
| `tdd-workflow` | Red-Green-Refactor cycle |
| `test-driven-development` | RED-GREEN-REFACTOR with anti-patterns reference |
| `git-workflow` | Stable-state commit workflow for complex tasks |
| `pr-workflow` | Full PR lifecycle (pre-checks, monitoring, merge) |
| `create-pr` | Quick PR creation with template detection |
| `fix-issue` | Fix a GitHub issue end-to-end |
| `setup-local-dev` | Persistent dev server with pm2 |
| `finishing-a-development-branch` | Merge/PR/cleanup decision workflow |

### Code Quality
| Skill | Description |
|-------|-------------|
| `best-practices-enforcement` | Validates code against universal standards |
| `code-cleanup` | Three-phase cleanup (AI slop, dead code, anti-patterns) |
| `code-review-excellence` | Effective code review practices |
| `code-optimization` | Performance and efficiency optimization |
| `code-migration` | Code migration patterns |
| `requesting-code-review` | Pre-review checklist |
| `receiving-code-review` | Responding to feedback with rigor |
| `verification-before-completion` | Evidence before claims |
| `security-audit` | Security vulnerability scanning |

### Debugging & Testing
| Skill | Description |
|-------|-------------|
| `systematic-debugging` | 4-phase root cause process |
| `debug-workflow` | Log-Reproduce-Fix cycle |
| `webapp-testing` | Playwright-based web app testing |
| `test-until-pass` | Iterative test-fix loop |

### Multi-Agent & Parallel
| Skill | Description |
|-------|-------------|
| `dispatching-parallel-agents` | Concurrent subagent workflows |
| `subagent-driven-development` | Fresh subagent per task with two-stage review |
| `multi-agent-branching` | Feature-branch isolation for concurrent agents |
| `using-git-worktrees` | Parallel development branches |
| `mass-repo-orchestration` | Multi-repo batch operations |
| `council` | Multi-perspective decision making |

### Research & Knowledge
| Skill | Description |
|-------|-------------|
| `deep-research` | Multi-source research with citations |
| `search-first` | Research before coding |
| `onboard-developer` | Developer onboarding guide |
| `generate-docs` | Auto-generate documentation |
| `generate-changelog` | Generate changelogs from git history |
| `doc-coauthoring` | Collaborative document creation |
| `address-pr-feedback` | Systematic PR feedback handling |

### Frontend & Documents
| Skill | Description |
|-------|-------------|
| `frontend-design` | Production-grade frontend interfaces |
| `web-artifacts-builder` | Multi-component HTML artifacts |
| `agent-browser` | Browser automation skill |
| `docx` | Word document creation, editing, tracked changes |
| `pdf` | PDF extraction, creation, merge/split, forms |
| `xlsx` | Spreadsheets with formulas, formatting, analysis |
| `pptx` | PowerPoint creation and editing |
| `gdoc` | Google Docs integration |

### Meta & Tools
| Skill | Description |
|-------|-------------|
| `skill-creator` | Guide for creating effective skills |
| `writing-skills` | Create new skills following best practices |
| `mcp-builder` | Guide for building MCP servers |
| `session-memory` | Persistent context across sessions |
| `using-superpowers` | Introduction to the skills system |
| `agent-token-optimization` | LLM token cost optimization |
| `continuous-learning-v2` | Instinct-based learning system |
| `strategic-compact` | Context compaction at logical intervals |
| `prompt-optimizer` | Optimize LLM prompts |
| `repository-organization` | Restructure messy repos |

## Optional Power-Ups

These are full frameworks best used via their own install mechanisms:

- **[BMAD-METHOD](https://github.com/bmad-code-org/BMAD-METHOD)** (36k stars): `npx bmad-method install` - Full agile AI development with 12+ specialized agents
- **[wshobson/agents](https://github.com/wshobson/agents)** (28k stars): `/plugin marketplace add wshobson/agents` - 112 agents, 146 skills, 73 plugins
- **[obra/superpowers marketplace](https://github.com/obra/superpowers-marketplace)**: `/plugin marketplace add obra/superpowers-marketplace` - Plugin system for Claude Code

## MCP Configuration

See `mcp/example-config.json` for a ready-to-use configuration with public MCP servers:

- **context7** - Library documentation lookup
- **playwright** - Browser automation
- **puppeteer** - Browser testing
- **github** - GitHub API integration
- **filesystem**, **git**, **shell** - Local development tools

## Adding More Skills

Skills are just markdown files. You can add more from:

- [skills.sh](https://skills.sh/) - Browse 57k+ community skills
- [anthropics/skills](https://github.com/anthropics/skills) - Official Anthropic skills
- [bestskills.app](https://bestskills.app/) - Curated top-quality skills

Install with: `npx skills add owner/repo --skill "skill-name"`

## Updating

### Pull latest + update community sources

```bash
cd ~/ai-coding-rules
git pull
acr update                        # fetch latest from obra/superpowers + anthropics/skills
git add -A && git commit -m "chore: update community skills"
```

### Re-apply to projects

```bash
# Linked or submodule project
cd ~/projects/my-app && acr sync
```

See [SOURCES.md](SOURCES.md) for full provenance tracking.

## Credits

Built on the shoulders of giants:

- [obra/superpowers](https://github.com/obra/superpowers) by Jesse Vincent - The autonomous dev workflow
- [anthropics/skills](https://github.com/anthropics/skills) by Anthropic - Official Claude skills
- [ironsource-mobile/mobile-agent-toolkit](https://github.com/ironsource-mobile/mobile-agent-toolkit) (formerly mobile-cursor-rules) - Generic rules, agents, hooks
- [Agent Skills Standard](https://agentskills.io) - The open SKILL.md specification

## License

MIT License - see [LICENSE](LICENSE) for details.

Skills from external sources retain their original licenses:
- obra/superpowers: MIT License
- anthropics/skills: Apache 2.0 (example skills), source-available (document skills)
