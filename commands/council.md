---
name: council
description: "Spawns multiple agents to deeply explore a codebase area before acting, providing comprehensive understanding through parallel investigation."
---

# Council - Multi-Agent Codebase Exploration

Spawns multiple agents to deeply explore a codebase area before acting, providing comprehensive understanding through parallel investigation.

## Usage

```
/council [n=10] <area-of-interest>
```

## Parameters

- `n` (optional): Number of agents to spawn for exploration (default: 10)
- `area-of-interest` (required): The specific area, feature, or question to investigate

## What it does

Based on the given area of interest, this command:

1. **Initial Reconnaissance**: Digs around the codebase to gather general information such as keywords and architecture overview related to the area of interest.

2. **Parallel Deep Dive**: Spawns n=10 (unless specified otherwise) task agents to dig deeper into the codebase. These agents explore various aspects of the area of interest, with some taking out-of-the-box approaches for variance and comprehensive coverage.

3. **Synthesis & Action**: Once the task agents complete their exploration, uses the aggregated information to fulfill the user's request with deep contextual understanding.

4. **Plan Mode Support**: If the user is in plan mode, uses the gathered information to create a comprehensive plan.

## When to use

- **Complex features**: Understanding how a large feature works across multiple files/modules
- **Debugging**: Investigating the root cause of an issue by exploring related code paths
- **Architecture questions**: Mapping out how a subsystem is designed and interconnected
- **Before refactoring**: Getting comprehensive understanding before making changes
- **Onboarding**: Learning how a specific area of the codebase works

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

## How it works

The council approach provides several benefits:

- **Parallel exploration**: Multiple agents working simultaneously for faster understanding
- **Diverse perspectives**: Different agents may focus on different aspects (usage, implementation, tests, configs)
- **Comprehensive coverage**: Variance in exploration ensures no critical areas are missed
- **Deep context**: Agents can dig into rabbit holes without blocking the main investigation

## Requirements

- Cursor 2.4+ with subagent support
- Max Mode enabled (for legacy request-based plans)

## Notes

- Adjust `n` based on complexity: use smaller values (n=5) for focused questions, larger values (n=15-20) for complex architectural investigations
- The council command is most effective for exploratory tasks rather than simple lookups
- Agents may explore related areas beyond the immediate question to provide full context

## Source

Adapted from [Cursor Resources by @shaoruu](https://shaoruu.io/cursor/council)
