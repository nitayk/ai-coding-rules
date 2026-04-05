#!/usr/bin/env node
const { spawnSync } = require('child_process');
const path = require('path');
const fs = require('fs');

// Read stdin from Cursor
let inputData = '';
process.stdin.setEncoding('utf8');

process.stdin.on('data', chunk => {
  inputData += chunk;
});

process.stdin.on('end', () => {
  try {
    const payload = JSON.parse(inputData);
    const hookName = payload.hook; // e.g. "afterFileEdit", "preCommand"
    const repoRoot = process.env.CURSOR_PROJECT_ROOT || process.cwd();
    const scriptDir = path.resolve(__dirname, '..', 'scripts', 'hooks');

    // 1. afterFileEdit -> post-edit-format & post-edit-typecheck
    if (hookName === 'afterFileEdit') {
      const filePath = payload.file;
      if (filePath) {
        // Mock Claude Code input format for existing scripts
        const mockClaudeInput = JSON.stringify({
          tool_input: { file_path: filePath }
        });

        // Run Formatter
        spawnSync('node', [path.join(scriptDir, 'post-edit-format.js')], {
          input: mockClaudeInput,
          stdio: ['pipe', 'inherit', 'inherit']
        });
      }
    }
    
    // 2. Additional routing can be added here
    
  } catch (err) {
    console.error(`[cursor-adapter] Error processing hook: ${err.message}`);
    process.exit(0); // Fail silently to avoid blocking Cursor
  }
});