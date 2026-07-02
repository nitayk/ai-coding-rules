---
name: setup-local-dev
description: "Use when starting development session, needing persistent dev server, doing long-running development work, or requiring server that survives terminal closes. Do NOT use for quick one-off tasks, when not running a dev server, when using Docker Compose or Kubernetes, or when server is already running."
last-reviewed: 2026-06-02
---
# Setup Local Development Server

Setup persistent local development server using pm2 process management.

**CRITICAL**: Use pm2 for dev servers that must survive terminal closes and IDE restarts. Provides auto-restart, logging, and process management.

## Fit Check (read first)

| | |
|---|---|
| **USE WHEN** | Node.js dev server (`npm run dev`, Next.js, Vite, Nuxt, Remix, Astro) — anything spawned from `npm`/`pnpm`/`yarn` that you want to keep alive across terminal closes |
| **DO NOT USE FOR** | Go services (`go run`, compiled binaries) · Scala/sbt (`sbt run`, `sbt ~reStart`) · Python (`uvicorn`, `gunicorn`, `flask run`) · Docker Compose / Kubernetes stacks · anything already managed by `make dev`, `tilt`, `skaffold`, or a repo-specific launcher |
| **INSTEAD** | Go/Scala/Python services in this workspace (UADS / iAds / ISX) typically run via `sbt`, `go run`, `docker compose`, or k8s — see `/docker-patterns` or run the service's documented command directly. pm2 adds no value (and may mask) for those stacks. |

Skip the rest of this skill if your stack isn't Node.js.

## When to Use This Skill

**APPLY WHEN:**
- Starting daily development session
- Need dev server that survives terminal closes
- Long-running development work
- Multiple terminal sessions
- Need centralized logging

**SKIP WHEN:**
- Quick one-off tasks
- Not running a dev server
- Using Docker Compose or Kubernetes
- Server already running

## Core Directive

**Check if running → Start with pm2 if needed → Verify ready → Use pm2 commands for management.**

## The Problem

**Traditional dev server issues:**

- Dies when terminal closes
- No crash recovery
- Logs disappear or fill context windows
- Hard to manage across IDE sessions
- No process monitoring

**Solution:** pm2 process manager

## Prerequisites

### Install pm2

```bash
# Global install
npm install -g pm2

# Or via package manager
brew install pm2  # macOS
```

### Verify Installation

```bash
pm2 --version
```

## Workflow

### Step 1: Check if Server Already Running

**Check pm2 status:**

```bash
pm2 list
```

**If server already running:**
- Server name appears in list
- Status shows "online"
- Continue to Step 3 (verify ready)

**If not running:**
- Continue to Step 2 (start server)

### Step 2: Start Dev Server with pm2

**Start server using pm2:**

```bash
# Option A: Direct command
pm2 start "npm run dev" --name "dev-server"

# Option B: Using ecosystem file (recommended)
pm2 start ecosystem.config.cjs
```

**Ecosystem file example (`ecosystem.config.cjs`):**

```javascript
module.exports = {
  apps: [{
    name: 'dev-server',
    script: 'npm',
    args: 'run dev',
    cwd: '/path/to/project',
    watch: false,  // Set to true for auto-restart on file changes
    autorestart: true,
    max_memory_restart: '1G',
    env: {
      NODE_ENV: 'development',
      PORT: 3000
    },
    error_file: './logs/pm2-error.log',
    out_file: './logs/pm2-out.log',
    log_date_format: 'YYYY-MM-DD HH:mm:ss Z'
  }]
};
```

### Step 3: Verify Server Ready

**Check server is responding:**

```bash
# Check pm2 status
pm2 status

# Check logs
pm2 logs dev-server --lines 20 --nostream

# Test server endpoint
curl http://localhost:3000/health
# or
curl http://localhost:3000
```

**Expected:** Server responds successfully

### Step 4: Daily Workflow

**Morning routine:**

```bash
# 1. Check if running
pm2 list

# 2. If not running, start
pm2 start ecosystem.config.cjs

# 3. Verify ready
pm2 logs dev-server --lines 10 --nostream
```

**Rest of day:** Server just works

## pm2 Commands Reference

### Process Management

```bash
# Start server
pm2 start ecosystem.config.cjs

# Stop server
pm2 stop dev-server

# Restart server
pm2 restart dev-server

# Delete process
pm2 delete dev-server

# List all processes
pm2 list

# Show details
pm2 show dev-server
```

### Logging

```bash
# View logs (streaming)
pm2 logs dev-server

# View last N lines (non-streaming, good for AI context)
pm2 logs dev-server --lines 50 --nostream

# View error logs only
pm2 logs dev-server --err --lines 50 --nostream

# View output logs only
pm2 logs dev-server --out --lines 50 --nostream

# Clear logs
pm2 flush dev-server
```

### Monitoring

```bash
# Real-time monitoring
pm2 monit

# Process info
pm2 info dev-server

# Save process list (for auto-start on reboot)
pm2 save

# Setup startup script (one-time)
pm2 startup
```

**For AI agents:** always pass `--nostream` so logs return a bounded snapshot instead of streaming — keeps context windows clean. Pipe to `grep`/`tail` to find errors or patterns, e.g. `pm2 logs dev-server --lines 200 --nostream | grep -i error`.

## Node.js Start Example

```bash
# Start
pm2 start "npm run dev" --name "dev-server"

# Or with ecosystem file
pm2 start ecosystem.config.cjs
```

> This skill is Node.js-only (see the Fit Check at the top). pm2 adds no value for Go/Scala/Python servers — run those via their native command, `/docker-patterns`, or a repo launcher instead.

## Ecosystem File Best Practices

### Recommended Configuration

```javascript
module.exports = {
  apps: [{
    name: 'dev-server',
    script: 'npm',
    args: 'run dev',
    cwd: process.cwd(),
    watch: false,  // Disable file watching (use dev server's own watch)
    autorestart: true,
    max_memory_restart: '1G',
    min_uptime: '10s',
    max_restarts: 10,
    env: {
      NODE_ENV: 'development'
    },
    error_file: './logs/pm2-error.log',
    out_file: './logs/pm2-out.log',
    log_date_format: 'YYYY-MM-DD HH:mm:ss Z',
    merge_logs: true,
    time: true
  }]
};
```

### Multiple Environments

```javascript
module.exports = {
  apps: [{
    name: 'dev-server',
    script: 'npm',
    args: 'run dev',
    env: {
      NODE_ENV: 'development',
      PORT: 3000
    },
    env_production: {
      NODE_ENV: 'production',
      PORT: 8080
    }
  }]
};
```

## Integration with Other Skills

**Use with:**
- `/git-workflow` - Start server before development
- `/tdd-workflow` - Server running for integration tests
- `/pr-workflow` - Verify server works before PR

## Troubleshooting

### Server Won't Start

**Check logs:**

```bash
pm2 logs dev-server --err --lines 50 --nostream
```

**Common issues:**
- Port already in use
- Missing dependencies
- Configuration errors

### Server Keeps Restarting

**Check restart count:**

```bash
pm2 show dev-server
```

**If restarting too often:**
- Check error logs
- Verify configuration
- Check resource limits

### Logs Too Large

**Clear logs:**

```bash
pm2 flush dev-server
```

**Or rotate logs:**

```bash
pm2 install pm2-logrotate
```

## Success Criteria / Output

A pm2-managed dev server that is installed/verified, started, responding to requests, monitored, and persists across terminal closes — with logs accessible via pm2 commands.

## Remember

> "pm2 keeps servers alive across sessions"

> "Use --nostream for AI-friendly log access"

> "Check status before starting - might already be running"

> "Ecosystem files make configuration reusable"

<!-- Cross-platform: see AGENTS.md in the repository root for Cursor, Claude Code, and Copilot paths. -->
