# Cursor CLI Rules

## Description
Rules for handling Cursor CLI commands and automation in our TikTok clone project.

## Globs
- .cursor/rules/*.mdc
- .cursorrules

## Context
The project uses Cursor CLI for development automation:
- Safe commands can run automatically
- Potentially destructive commands require approval
- Commands are organized by safety level

## Rules

### Automatic Commands
The following commands can run without user approval:
1. Status checks and monitoring:
   - Port checks (lsof, netstat)
   - Process status (ps, top)
   - File existence checks
2. Read-only operations:
   - Directory listing (ls, find)
   - File content viewing (cat, head, tail)
   - Git status and log commands

### Manual Approval Required
Commands that require user approval:
1. Service operations:
   - Starting/stopping emulators
   - Running test scripts
   - Database operations
2. File modifications:
   - Creating new files
   - Modifying existing files
   - Deleting files
3. Git operations:
   - Commits
   - Pushes
   - Branch operations

### Common Issues
- If automatic commands fail, verify PATH settings
- For port conflicts, check running processes
- For permission issues, verify file ownership 