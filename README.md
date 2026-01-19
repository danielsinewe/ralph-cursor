# Ralph - Autonomous AI Development Loop

Ralph is an autonomous development loop system that uses **Cursor Agent** (or Claude Code) to iteratively implement features from a PRD (Product Requirements Document).

## Key Features

- ✅ **Cursor Agent Support** - Use Cursor's powerful AI agent for autonomous development (default)
- ✅ **Claude Code Compatible** - Can also use Claude Code CLI as alternative
- ✅ **Zero Configuration** - Works out of the box with Cursor Agent
- ✅ **Full Feature Parity** - All original Ralph features included

## Quick Start

To add Ralph to your existing project, copy the entire `ralph` directory into your repo:

```bash
cp -r path/to/ralph your-project/
```

Or if you are starting from this repo, clone and copy:

```bash
git clone https://github.com/danielsinewe/ralph-cursor.git
cp -r ralph-cursor your-project/ralph
```


```bash
# 1. Create a new project
./ralph/new.sh my-feature

# 2. Edit your PRD
code ralph/projects/my-feature/prd.md

# 3. Convert PRD to JSON tasks
./ralph/convert.sh my-feature

# 4. Start the loop (with tmux monitoring)
./ralph/start.sh my-feature --monitor
```

## Prerequisites

```bash
# Install dependencies
brew install jq tmux coreutils

# Cursor Agent (default, recommended) - NO INSTALL NEEDED!
# Cursor Agent comes built-in with Cursor IDE
# Just ensure 'agent' is in your PATH (~/.local/bin/agent)
# If not, add to ~/.zshrc or ~/.bashrc:
# export PATH="$HOME/.local/bin:$PATH"
# 
# Verify installation:
# agent --help

# OR install Claude Code (optional alternative)
# Only needed if you want to use Claude Code instead of Cursor Agent
# npm install -g @anthropic-ai/claude-code
# claude login
```

## Configuration

Ralph uses **Cursor Agent by default**. To switch to Claude Code, edit `start.sh`:

```bash
# Default (Cursor Agent) - in start.sh
CLAUDE_CMD="agent --print --force"

# Alternative (Claude Code) - change in start.sh
CLAUDE_CMD="claude --dangerously-skip-permissions"
```

### Why Cursor Agent? (Default)

| Feature | Claude Code | Cursor Agent ⭐ |
|---------|-------------|----------------|
| **Installation** | `npm install -g @anthropic-ai/claude-code` | Built-in with Cursor IDE |
| **API Limits** | Yes (100 calls/hour) | **No limits** |
| **Cost** | Paid API usage | **Free** with Cursor IDE |
| **File Editing** | ✅ | ✅ |
| **Shell Commands** | ✅ | ✅ (with --force) |
| **Setup Time** | 5-10 minutes | **0 minutes** (already installed) |
| **Rate Limits** | Strict | **None** |

**Cursor Agent is the default** - no installation required if you have Cursor IDE!

### Chrome DevTools MCP (Optional - Claude Code only)

For browser debugging capabilities with Claude Code, add the Chrome DevTools MCP server:

- https://github.com/ChromeDevTools/chrome-devtools-mcp

```bash
claude mcp add chrome-devtools --scope user npx chrome-devtools-mcp@latest
```

## Commands

### `./ralph/new.sh <project-name>`
Create a new project from template.

```bash
./ralph/new.sh signals
# Creates: ralph/projects/signals/
```

### `./ralph/convert.sh <project-name>`
Convert your PRD.md to actionable JSON tasks using Cursor Agent (or Claude).

```bash
./ralph/convert.sh signals
# Reads: ralph/projects/signals/prd.md
# Creates: ralph/projects/signals/prd.json
```

### `./ralph/start.sh <project-name> [options]`
Run the autonomous development loop.

```bash
# Without tmux (output directly in terminal)
./ralph/start.sh signals

# With tmux monitoring (recommended)
./ralph/start.sh signals --monitor

# Check status
./ralph/start.sh signals --status

# Reset circuit breaker if stuck
./ralph/start.sh signals --reset
```

Options:
- `-m, --monitor` - Start with tmux session and live monitor
- `-c, --calls NUM` - Max calls per hour (default: 100)
- `-t, --timeout MIN` - Agent timeout in minutes (default: 20)
- `-s, --status` - Show project status and exit
- `-r, --reset` - Reset circuit breaker

### `./ralph/monitor.sh <project-name>`
Live status dashboard (auto-started with `--monitor`).

```bash
./ralph/monitor.sh signals
```

## Workflow

```
┌─────────────────────────────────────────────────────────────────┐
│                                                                 │
│  1. Write PRD (prd.md)                                          │
│     Human-readable requirements document                        │
│                                                                 │
│  2. Convert to JSON (prd.json)                                  │
│     Cursor Agent (or Claude) breaks down PRD into tasks        │
│                                                                 │
│  3. Ralph Loop                                                  │
│     ┌─────────────────────────────────────────────────────┐     │
│     │  Pick next story where passes=false                 │     │
│     │  ↓                                                  │     │
│     │  Generate prompt with story + context               │     │
│     │  ↓                                                  │     │
│     │  Run Cursor Agent (or Claude Code)                  │     │
│     │  ↓                                                  │     │
│     │  Analyze response (check status block)              │     │
│     │  ↓                                                  │     │
│     │  If story complete: mark passes=true, commit        │     │
│     │  ↓                                                  │     │
│     │  If all done: exit                                  │     │
│     │  Else: loop back                                    │     │
│     └─────────────────────────────────────────────────────┘     │
│                                                                 │
└─────────────────────────────────────────────────────────────────┘
```

## PRD JSON Format

The `prd.json` file has this structure:

```json
{
  "branchName": "ralph/feature-name",
  "userStories": [
    {
      "id": "1.1",
      "category": "functional",
      "story": "Short description of what to build",
      "steps": [
        "Step 1: What to do",
        "Step 2: Next action",
        "Step 3: How to verify"
      ],
      "acceptance": "Detailed acceptance criteria",
      "priority": 1,
      "passes": false,
      "notes": ""
    }
  ]
}
```

### Fields

| Field | Description |
|-------|-------------|
| `branchName` | Git branch Ralph will create/use for this feature |
| `id` | Story identifier (phase.sequence, e.g., "1.1", "2.3") |
| `category` | One of: `technical`, `functional`, `ui` |
| `story` | One-sentence description of what to build |
| `steps` | Actionable steps to complete the story |
| `acceptance` | Definition of "done" |
| `priority` | **Lower = do first** (1-10 MVP, 11-20 Phase 2, 21+ Phase 3) |
| `passes` | Set to `true` when story is complete |
| `notes` | Ralph fills this with learnings during implementation |

## tmux Controls

When running with `--monitor`:

| Keys | Action |
|------|--------|
| `Ctrl+B`, `D` | Detach (keeps running in background) |
| `Ctrl+B`, `←/→` | Switch between panes |
| `Ctrl+B`, `[` | Enter scroll mode (`q` to exit) |
| `tmux ls` | List sessions |
| `tmux attach -t ralph-<project>` | Reattach to session |

## Safety Features

- **Rate Limiting**: Max 100 calls/hour (configurable, mainly for Claude Code)
- **Circuit Breaker**: Auto-stops after repeated failures
- **Exit Detection**: Stops when Agent signals completion
- **Branch Isolation**: Each feature runs on its own git branch

## Learnings System

Ralph has a two-tier learning system:

| File | Purpose | Lifetime |
|------|---------|----------|
| `progress.txt` | Session memory for Ralph | Per-project |
| `AGENTS.md` | Permanent docs for humans & future agents | Forever |

### progress.txt Structure

```markdown
## Codebase Patterns
- Migrations: Use IF NOT EXISTS
- Types: Export from actions.ts

## Key Files
- db/schema.ts
- app/auth/actions.ts
---
## 2024-01-15 - Story 1.1
- What was implemented
- **Learnings:** patterns discovered
```

### AGENTS.md Updates

Ralph updates `AGENTS.md` files in directories where it made changes:

✅ **Good additions:**
- "When modifying X, also update Y"
- "This module uses pattern Z"
- "Tests require dev server running"

❌ **Don't add:**
- Story-specific details
- Temporary notes

## Project Structure

```
ralph/
├── new.sh          # Create new project
├── convert.sh      # PRD → JSON converter
├── start.sh        # Main loop
├── monitor.sh      # Status dashboard
├── lib/
│   ├── utils.sh
│   ├── circuit_breaker.sh
│   └── response_analyzer.sh
├── templates/
│   ├── PROMPT.md        # Standard prompt
│   ├── prd-template.md  # PRD template
│   └── prd-schema.json  # JSON example
└── projects/
    └── <your-projects>/
        ├── prd.md         # Your PRD
        ├── prd.json       # Generated tasks
        ├── progress.txt   # Progress log
        ├── status.json    # Current status
        ├── PROMPT.md      # Standard prompt
        └── logs/          # Execution logs
```

## Troubleshooting

### Circuit breaker opened
```bash
./ralph/start.sh <project> --status  # Check what happened
./ralph/start.sh <project> --reset   # Reset and continue
```

### Rate limit hit
Ralph automatically waits for the next hour. You can detach with `Ctrl+B, D` and come back later.

### Agent not responding
Check the logs in `ralph/projects/<project>/logs/` for details.

### Switching between Cursor Agent and Claude Code

**Cursor Agent is the default** - works out of the box with Cursor IDE!

To use Claude Code instead (optional):

1. Install Claude Code:
   ```bash
   npm install -g @anthropic-ai/claude-code
   claude login
   ```

2. Edit `start.sh` and change:
   ```bash
   CLAUDE_CMD="agent --print --force"
   ```
   to:
   ```bash
   CLAUDE_CMD="claude --dangerously-skip-permissions"
   ```

**Note:** Cursor Agent is recommended - no installation or API limits!
