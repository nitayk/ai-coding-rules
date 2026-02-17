# ai-coding-rules

A curated, best-of-breed AI coding toolkit that combines top community skills with battle-tested rules and workflows. Works as a git submodule for any project, instantly supercharging your AI-assisted development.

Supports both **Cursor** and **Claude Code**.

## What's Inside

| Category | Count | Source |
|----------|-------|--------|
| **Skills** | 34 | obra/superpowers, anthropics/skills, custom |
| **Agents** | 1 | obra/superpowers |
| **Commands** | 3 | obra/superpowers |
| **Hooks** | 2 | obra/superpowers |
| **Cursor Rules** | 200+ | Custom (Scala, Python, Go, Java, PHP, JS/TS, Swift, Kotlin, Obj-C) |
| **Claude Rules** | 7 | Custom |
| **CLI Tool Guides** | 8 | Custom (curl, jq, git, docker, kcat, kubectl, aws-cli, gh-cli) |

## Quick Start

### Option A: Per-project setup (recommended if you also use work repos)

Cleanest separation -- your personal tools stay in personal projects, zero
chance of mixing with org repos.

```bash
# One-time: clone to your home directory
git clone https://github.com/nitayk/ai-coding-rules.git ~/ai-coding-rules

# Setup any personal project (copies skills + rules + agents + commands)
bash ~/ai-coding-rules/setup-project.sh ~/projects/my-app

# Restart Cursor -- done! 34 skills + 200+ rules in that project.
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

### Development Workflow (from [obra/superpowers](https://github.com/obra/superpowers) - 53k stars)

| Skill | Description |
|-------|-------------|
| `brainstorming` | Socratic design refinement before coding |
| `test-driven-development` | RED-GREEN-REFACTOR cycle with anti-patterns reference |
| `systematic-debugging` | 4-phase root cause process |
| `verification-before-completion` | Evidence before claims |
| `executing-plans` | Batch execution with human checkpoints |
| `subagent-driven-development` | Fresh subagent per task with two-stage review |
| `writing-plans` | Break work into 2-5 min bite-sized tasks |
| `dispatching-parallel-agents` | Concurrent subagent workflows |
| `requesting-code-review` | Pre-review checklist |
| `receiving-code-review` | Responding to feedback with rigor |
| `using-git-worktrees` | Parallel development branches |
| `finishing-a-development-branch` | Merge/PR/cleanup decision workflow |
| `using-superpowers` | Introduction to the skills system |
| `writing-skills` | Create new skills following best practices |

### Document and Design (from [anthropics/skills](https://github.com/anthropics/skills) - 70k stars)

| Skill | Description |
|-------|-------------|
| `docx` | Word document creation, editing, tracked changes |
| `pdf` | PDF extraction, creation, merge/split, forms |
| `xlsx` | Spreadsheets with formulas, formatting, analysis |
| `pptx` | PowerPoint creation and editing |
| `mcp-builder` | Guide for building MCP servers |
| `skill-creator` | Guide for creating effective skills |
| `webapp-testing` | Playwright-based web app testing |
| `frontend-design` | Frontend design patterns |
| `web-artifacts-builder` | Web artifact creation |

### Custom Skills (original, not available elsewhere)

| Skill | Description |
|-------|-------------|
| `session-memory` | Persistent context across sessions |
| `git-workflow` | Stable-state commit workflow for complex tasks |
| `pr-workflow` | Full PR lifecycle (pre-checks, monitoring, merge) |
| `prd-generation` | PRD generation via structured conversation |
| `task-breakdown` | Break PRDs into parent tasks and sub-tasks |
| `multi-agent-branching` | Feature-branch isolation for concurrent agents |
| `setup-local-dev` | Persistent dev server with pm2 |
| `tdd-workflow` | Red-Green-Refactor cycle |
| `code-cleanup` | Three-phase cleanup (AI slop, dead code, anti-patterns) |
| `best-practices-enforcement` | Validates code against universal standards |
| `debug-workflow` | Log-Reproduce-Fix cycle |

## Cursor Rules System

The intelligent **Router** (`ROUTER.mdc`) auto-detects your intent and loads the right rules:

- **generic/** - Architecture, code quality, testing, performance, security, debugging, communication
- **backend/** - Scala, Python, Go, Java, PHP patterns
- **frontend/** - JavaScript/TypeScript, Vue, React
- **mobile/** - Swift, Kotlin, Objective-C, CocoaPods, Gradle
- **tools/** - CLI references for curl, jq, git, docker, kcat, kubectl, aws-cli, gh-cli

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
- [Agent Skills Standard](https://agentskills.io) - The open SKILL.md specification

## License

MIT License - see [LICENSE](LICENSE) for details.

Skills from external sources retain their original licenses:
- obra/superpowers: MIT License
- anthropics/skills: Apache 2.0 (example skills), source-available (document skills)
