---
name: setup-local-dev
description: "Sets up persistent local development server using pm2 process management that survives terminal closes and IDE restarts. Configures pm2 to auto-restart on crashes, persist across sessions, and provide process monitoring. Use when starting development session, needing persistent dev server, doing long-running development work, or requiring server that survives terminal closes. Produces pm2-based dev server configuration with auto-restart and persistence enabled."
version: "1.0.0"
last_updated: "2026-01-25"
tags: ["development", "server", "pm2", "workflow", "universal"]
---
# Setup Local Development Server

Setup persistent local development server using pm2 process management.

**CRITICAL**: Use pm2 for dev servers that must survive terminal closes and IDE restarts. Provides auto-restart, logging, and process management.

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

## Efficient Log Searching

**For AI agents - use non-streaming logs:**

```bash
# Quick status check (last 50 lines)
pm2 logs dev-server --lines 50 --nostream

# Find errors
pm2 logs dev-server --lines 200 --nostream | grep -i "error"

# Find specific patterns
pm2 logs dev-server --lines 200 --nostream | grep "database"

# Check recent activity
pm2 logs dev-server --lines 100 --nostream | tail -20
```

**Why non-streaming:** Keeps context windows clean, provides full log access without streaming

## Language-Specific Examples

### Node.js/TypeScript

```bash
# Start
pm2 start "npm run dev" --name "dev-server"

# Or with ecosystem file
pm2 start ecosystem.config.cjs
```

### Python (using pm2 with uvicorn/gunicorn)

```bash
# Start
pm2 start "uvicorn main:app --reload" --name "api-server"

# Or with ecosystem file
pm2 start ecosystem.config.cjs
```

### Scala (sbt)

```bash
# Start
pm2 start "sbt ~run" --name "scala-server"

# Or with ecosystem file
pm2 start ecosystem.config.cjs
```

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

## Common Scenarios

### Scenario 1: Starting Fresh Session

**Morning routine:**

```bash
# 1. Check status
pm2 list

# 2. If not running, start
pm2 start ecosystem.config.cjs

# 3. Verify
pm2 logs dev-server --lines 10 --nostream
```

### Scenario 2: Server Crashed

**Auto-restart handles it:**

```bash
# pm2 automatically restarts
# Check logs to see what happened
pm2 logs dev-server --err --lines 50 --nostream
```

### Scenario 3: Need to Restart

**Quick restart:**

```bash
pm2 restart dev-server
```

### Scenario 4: Checking Logs

**For AI context:**

```bash
# Get recent logs (non-streaming)
pm2 logs dev-server --lines 100 --nostream

# Search for errors
pm2 logs dev-server --lines 200 --nostream | grep -i error
```

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

## Success Criteria

- **pm2 installed** and verified
- **Server started** with pm2
- **Server responding** to requests
- **Logs accessible** via pm2 commands
- **Server persists** across terminal closes

## Output

**This skill produces:**
- Dev server running via pm2
- Process managed and monitored
- Logs accessible via pm2 commands
- Server survives terminal closes

## Remember

> "pm2 keeps servers alive across sessions"

> "Use --nostream for AI-friendly log access"

> "Check status before starting - might already be running"

> "Ecosystem files make configuration reusable"
