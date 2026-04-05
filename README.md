# ai-coding-rules

A curated, best-of-breed AI coding toolkit that combines top community skills with battle-tested rules and workflows. Works as a git submodule for any project, instantly supercharging your AI-assisted development.

Supports both **Cursor** and **Claude Code**.

## What's Inside

| Category | Count | Source |
|----------|-------|--------|
| **Skills** | 57 | obra/superpowers, anthropics/skills, mcr, Unity, custom |
| **Agents** | 9 | architect, code-reviewer, data-validator, and more |
| **Commands** | 12 | brainstorm, create-pr, fix-issue, council, and more |
| **Hooks** | 20+ | Quality, security, observability, ECC |
| **Cursor Rules** | 200+ | Custom (Scala, Python, Go, Java, PHP, JS/TS, Swift, Kotlin, Obj-C) |
| **Claude Rules** | 7 | Custom |
| **CLI Tool Guides** | 13 | curl, jq, yq, git, docker, kcat, kubectl, aws-cli, gcloud, helm, terraform, ripgrep, gh-cli |

## Quick Start

### Option A: Per-project setup (recommended if you also use work repos)

Cleanest separation -- your personal tools stay in personal projects, zero
chance of mixing with org repos.

```bash
# One-time: clone to your home directory
git clone https://github.com/nitayk/ai-coding-rules.git ~/ai-coding-rules

# Setup any personal project (copies skills + rules + agents + commands)
bash ~/ai-coding-rules/setup-project.sh ~/projects/my-app

# Restart Cursor -- done! 57 skills + 200+ rules in that project.
```

To update a project later:
```bash
cd ~/ai-coding-rules && git pull && bash update-community.sh
bash ~/ai-coding-rules/setup-project.sh ~/projects/my-app   # re-copies
```

### Option B: Global skills install (if all your projects are personal)

Installs skills globally so every Cursor project gets them. Rules still need
per-project setup (Cursor limitation -- rules can't live at user level on disk).

```bash
git clone https://github.com/nitayk/ai-coding-rules.git ~/ai-coding-rules

# Skills + agents + commands -> ~/.cursor/ (global)
bash ~/ai-coding-rules/install-global.sh

# Rules -> per project (Cursor requires this)
bash ~/ai-coding-rules/setup-project.sh ~/projects/my-app
```

> **Warning**: Global skills also appear in work/org projects.
> If your org repos already have `.cursor/skills/`, you'll get duplicates.

### Option C: Git submodule (team/open-source projects)

Version-pinned rules committed to the project repo:

```bash
git submodule add https://github.com/nitayk/ai-coding-rules.git .cursor/rules/shared
bash .cursor/rules/shared/install-cursor.sh
```

### What goes where (Cursor architecture)

| What | Global (`~/.cursor/`) | Project (`.cursor/`) | How |
|------|----------------------|---------------------|-----|
| **Skills** | `~/.cursor/skills/` | `.cursor/skills/` | Both work, project takes precedence |
| **Rules** (.mdc) | **Not supported** on disk (Settings UI only) | `.cursor/rules/` | Must be per-project |
| **Agents** | `~/.cursor/agents/` | `.cursor/agents/` | Both work |
| **Commands** | `~/.cursor/commands/` | `.cursor/commands/` | Both work |

Source: [Cursor Skills Docs](https://cursor.com/docs/context/skills), [Cursor Rules Docs](https://cursor.com/docs/context/rules)

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

## Cursor Rules System

The intelligent **Router** (`ROUTER.mdc`) auto-detects your intent and loads the right rules:

- **generic/** - Architecture, code quality, testing, performance, security, debugging, communication, agent behavior
- **backend/** - Scala, Python, Go, Java, PHP patterns
- **frontend/** - JavaScript/TypeScript, Vue, React, accessibility, performance, security
- **mobile/** - Swift, Kotlin, Objective-C, CocoaPods, Gradle
- **tools/** - CLI references for curl, jq, yq, git, docker, kcat, kubectl, aws-cli, gcloud, helm, terraform, ripgrep, gh-cli

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
bash update-community.sh          # fetch latest from obra/superpowers + anthropics/skills
git add -A && git commit -m "chore: update community skills"
```

### Re-apply to projects

```bash
# Per-project (Option A)
bash ~/ai-coding-rules/setup-project.sh ~/projects/my-app

# Or global skills (Option B)
bash ~/ai-coding-rules/install-global.sh
```

See [SOURCES.md](SOURCES.md) for full provenance tracking.

## Credits

Built on the shoulders of giants:

- [obra/superpowers](https://github.com/obra/superpowers) by Jesse Vincent - The autonomous dev workflow
- [anthropics/skills](https://github.com/anthropics/skills) by Anthropic - Official Claude skills
- [ironsource-mobile/mobile-cursor-rules](https://github.com/ironsource-mobile/mobile-cursor-rules) - Generic rules, agents, hooks
- [Agent Skills Standard](https://agentskills.io) - The open SKILL.md specification

## License

MIT License - see [LICENSE](LICENSE) for details.

Skills from external sources retain their original licenses:
- obra/superpowers: MIT License
- anthropics/skills: Apache 2.0 (example skills), source-available (document skills)
