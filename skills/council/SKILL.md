---
name: council
description: "Use when exploring codebase deeply, understanding complex features, debugging across modules, architecting before refactoring, or onboarding to a codebase. Spawns multiple agents for parallel exploration. Make sure to use when user mentions: how does X work, deep dive, explore architecture, understand this codebase, before refactoring, or needs comprehensive understanding. Do NOT use for simple lookups or single-file questions."
disable-model-invocation: true
---
# Council - Multi-Agent Codebase Exploration

Spawns multiple agents to deeply explore a codebase area before acting, providing comprehensive understanding through parallel investigation.

## When to Use This Skill

**APPLY WHEN:**
- Understanding how a complex feature works across multiple files/modules
- Debugging across related code paths
- Architecture questions or mapping subsystem design
- Before refactoring (comprehensive understanding first)
- Onboarding to a specific area of the codebase
- User asks "how does X work?", "deep dive", "explore", "understand this architecture"

**SKIP WHEN:**
- Simple lookups or single-file questions
- User needs a quick answer (file read or grep suffices)
- Subagent support not available (Cursor 2.4+ required)

## Core Directive

**Spawn multiple agents for parallel exploration, then synthesize.** Use the combined intelligence from diverse perspectives to fulfill the request with deep contextual understanding.

## Usage

```
/council [n=10] <area-of-interest>
```

## Parameters

- `n` (optional): Number of agents to spawn (default: 10). Use n=5 for focused questions, n=15-20 for complex investigations.
- `area-of-interest` (required): The specific area, feature, or question to investigate

## Process

1. **Initial Reconnaissance**: Gather general information (keywords, architecture overview) related to the area of interest.

2. **Parallel Deep Dive**: Spawn n task agents to explore various aspects. Agents take out-of-the-box approaches for variance and comprehensive coverage.

3. **Synthesis & Action**: Once agents complete, use aggregated information to fulfill the user's request with deep contextual understanding.

4. **Plan Mode Support**: If the user is in plan mode, use gathered information to create a comprehensive plan.

## Examples

```
/council how does authentication work?
```
Spawns 10 agents to explore authentication flow from multiple angles.

```
/council n=15, how does the payment system integrate with external providers?
```
Spawns 15 agents for deeper investigation of payment integrations.

```
/council find all places we use InstancedGeometry
```
Agents search and analyze all usages of InstancedGeometry pattern.

```
/council n=5, getting this error: "Cannot read property 'id' of undefined"
```
5 agents investigate the error from different perspectives.

## How It Works

- **Parallel exploration**: Multiple agents working simultaneously for faster understanding
- **Diverse perspectives**: Different agents focus on different aspects (usage, implementation, tests, configs)
- **Comprehensive coverage**: Variance in exploration ensures no critical areas are missed
- **Deep context**: Agents may dig into rabbit holes without blocking the main investigation

## Requirements

- Cursor 2.4+ with subagent support
- Max Mode enabled (for legacy request-based plans)

## Related Skills

- `/code-structure-analysis` - Single-agent code structure analysis
- `/dispatching-parallel-agents` - General parallel orchestration

## Source

Adapted from [Cursor Resources by @shaoruu](https://shaoruu.io/cursor/council)
