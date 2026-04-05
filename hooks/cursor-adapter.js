#!/usr/bin/env node
const { spawnSync } = require('child_process');
const path = require('path');
const fs = require('fs');

let inputData = '';
process.stdin.setEncoding('utf8');

process.stdin.on('data', chunk => {
  inputData += chunk;
});

process.stdin.on('end', () => {
  try {
    const payload = JSON.parse(inputData);
    const hookName = payload.hook;
    const hooksDir = __dirname;

    if (hookName === 'afterFileEdit') {
      const filePath = payload.file;
      if (filePath) {
        const formatScript = path.join(hooksDir, 'quality', 'format-after-edit.sh');
        if (fs.existsSync(formatScript)) {
          spawnSync('bash', [formatScript], {
            input: JSON.stringify({ tool_input: { file_path: filePath } }),
            stdio: ['pipe', 'inherit', 'inherit']
          });
        }
      }
    }
  } catch (err) {
    console.error(`[cursor-adapter] Error processing hook: ${err.message}`);
    process.exit(0);
  }
});
