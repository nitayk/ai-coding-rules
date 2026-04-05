---
name: onboard-developer
description: "Use when onboarding a new developer to the codebase. Generates comprehensive guide, checklist, key files, first issues. Make sure to use when user says: onboard developer, /onboard, new developer guide, or help someone get started with this project."
disable-model-invocation: true
---
# Onboard New Developer

Help a new developer understand the codebase.

## When to Use This Skill

**APPLY WHEN:**
- User wants onboarding guide for new developers
- User says "onboard", "/onboard", "new developer guide"
- Creating materials for team onboarding

**SKIP WHEN:**
- User is already familiar with the codebase
- User wants architecture deep-dive (use `/council`)

## Core Directive

**Generate comprehensive guide: overview, setup, structure, workflow, common tasks, resources.** Include checklist and suggested first issues.

## Usage

```
/onboard [focus-area]
```

## Process

1. Generates a comprehensive onboarding guide covering:
   - **Project Overview**: Purpose, architecture, tech stack
   - **Development Setup**: Prerequisites, installation, running locally
   - **Code Structure**: Directory layout, key modules, conventions
   - **Development Workflow**: Git workflow, testing, deployment
   - **Common Tasks**: How to add features, fix bugs, run tests
   - **Resources**: Documentation, wiki, team contacts
2. Creates an onboarding checklist
3. Identifies key files to review first
4. Suggests good "first issues" for new contributors

## Examples

```
/onboard
```

Generate full onboarding guide.

```
/onboard frontend
```

Focus on frontend development onboarding.

```
/onboard api
```

Focus on API development onboarding.

## Onboarding Guide Structure

### 1. Project Overview
- What does this project do?
- Who are the users?
- What's the tech stack?

### 2. Getting Started
```bash
# Prerequisites
node >= 18.0.0
npm >= 9.0.0

# Installation
git clone <repo>
npm install
cp .env.example .env

# Run locally
npm run dev
```

### 3. Code Structure
```
src/
├── api/          # REST API endpoints
├── components/   # React components
├── utils/        # Helper functions
└── tests/        # Test suites
```

### 4. Development Workflow
- Create feature branch from `main`
- Make changes and add tests
- Run `npm test` and `npm run lint`
- Create PR with clear description
- Address review comments
- Merge when approved

### 5. Common Tasks
- **Add new API endpoint**: See `src/api/README.md`
- **Add React component**: Follow patterns in `src/components/`
- **Run tests**: `npm test` or `npm run test:watch`
- **Debug**: Use VS Code debugger (see `.vscode/launch.json`)

### 6. Resources
- [Main documentation](link)
- [API documentation](link)
- [Team wiki](link)
- [Slack channel](link)

## New Developer Checklist

- [ ] Clone repository and run locally
- [ ] Read architecture overview
- [ ] Review code style guide
- [ ] Understand git workflow
- [ ] Complete first "good first issue"
- [ ] Set up development tools
- [ ] Join team communication channels

## Best Practices

- Tailor guide to actual project structure
- Include working code examples
- Link to external resources
- Update regularly as project evolves
- Get feedback from new team members
