# Running Claude Code in a Loop

A guide to building an autonomous AI development loop using Claude Code CLI.

---

## What This Is

A bash script system that runs Claude Code repeatedly until a task is complete. It reads a list of tasks (PRD), picks the next incomplete one, runs Claude, and loops until everything is done.

```
┌─────────────────────────────┐
│  1. Read task list          │
│  2. Pick next incomplete    │
│  3. Run Claude Code         │
│  4. Check if done           │
│  5. If not done → go to 1   │
└─────────────────────────────┘
```

---

## Prerequisites

```bash
# Install dependencies
brew install jq tmux coreutils

# Install Claude Code CLI
npm install -g @anthropic-ai/claude-code

# Verify
claude --version
```

---
## Ralph loop is just a loop

At its core, Ralph is a `while` loop that runs Claude Code repeatedly until a task is complete.

```bash
while true; do

    response=$(echo "Continue working on the feature. Say DONE when finished." | claude --dangerously-skip-permissions 2>&1)

    echo "$response"

    if echo "$response" | grep -q "DONE"; then
        echo "Claude says it's done!"
        break
    fi

    sleep 2
done
```

This works. But it has problems: no timeout if Claude hangs, no rate limiting, no way to detect if Claude is stuck. The following layers add these safeguards one at a time.

---

## Layer 1: Add a Task List

Instead of checking for "DONE", let's track tasks in a JSON file. Add a `prd.json` with user stories as described in Anthropic's [Guide to Effective Harnesses for Long-Running Agents](https://www.anthropic.com/engineering/effective-harnesses-for-long-running-agents).

```bash
set -e

# Run Claude with a prompt, check output, repeat
while true; do
    echo "Running Claude..."

    # Pipe prompt to Claude
    echo "Implement the next task from prd.json" | claude --dangerously-skip-permissions > output.log 2>&1

    # Check if all tasks are done
    incomplete=$(jq '[.userStories[] | select(.passes == false)] | length' prd.json)

    if [[ "$incomplete" -eq 0 ]]; then
        echo "All done!"
        break
    fi

    echo "$incomplete tasks remaining..."
    sleep 5
done
```

The `prd.json` file tracks each task:

```json
{
  "userStories": [
    {
      "story": "Add LumaUser interface and getSelf() method to LumaClient",
      "steps": [
        "Open packages/configs/src/luma/client.ts",
        "Add LumaUser interface with api_id, name, email fields",
        "Implement getSelf() method that calls GET /user/get-self endpoint"
      ],
      "acceptance": "getSelf() returns user info with valid API key",
      "priority": 1,
      "passes": false,
      "notes": ""
    }
  ]
}
```

- `--dangerously-skip-permissions`: Runs Claude without asking for confirmation on file edits/commands. Required for autonomous operation.
- `jq`: Parses the JSON to count incomplete tasks. The loop exits when all stories have `passes: true`.

--

## Layer 3: Add Completion Token

Claude can signal it's done by outputting a special token. This gives Claude explicit control over when to stop.

```bash
#!/bin/bash
set -e

TIMEOUT_MINUTES=15
COMPLETE_TOKEN="<COMPLETE>"

while true; do
    echo "Running Claude..."

    # Run with timeout, capture output
    if gtimeout $((TIMEOUT_MINUTES * 60))s bash -c 'echo "Implement next task. Output $COMPLETE_TOKEN when all tasks are done." | claude --dangerously-skip-permissions' > output.log 2>&1; then
        echo "Claude finished"
    else
        if [[ $? -eq 124 ]]; then
            echo "Claude timed out, retrying..."
            continue
        fi
    fi

    # Check for completion token
    if grep -q "$COMPLETE_TOKEN" output.log; then
        echo "Claude signaled completion!"
        break
    fi

    # Fallback: check prd.json
    incomplete=$(jq '[.userStories[] | select(.passes == false)] | length' prd.json)
    [[ "$incomplete" -eq 0 ]] && break

    sleep 5
done
```

Now there are two exit conditions:
1. Claude outputs `<COMPLETE>` - it decided it's done
2. All tasks in `prd.json` have `passes: true` - fallback check

---

## Layer 4: Add Circuit Breaker

Detect when Claude is stuck (no progress, same error repeating).

```bash
# Track in a file
NO_PROGRESS_COUNT=0
MAX_NO_PROGRESS=3

record_result() {
    local files_changed=$1

    if [[ "$files_changed" -eq 0 ]]; then
        NO_PROGRESS_COUNT=$((NO_PROGRESS_COUNT + 1))
    else
        NO_PROGRESS_COUNT=0
    fi

    if [[ $NO_PROGRESS_COUNT -ge $MAX_NO_PROGRESS ]]; then
        echo "HALTED: No file changes in $NO_PROGRESS_COUNT loops"
        exit 1
    fi
}

# After each Claude run
files_modified=$(git diff --name-only | wc -l)
record_result "$files_modified"
```

Full circuit breaker tracks:
- Consecutive loops with no file changes
- Same error repeating multiple times
- Output length declining (possible stagnation)

---

---

## Layer 2: Add Timeout

Claude can hang. Add a timeout.

```bash
#!/bin/bash
set -e

TIMEOUT_MINUTES=15

while true; do
    echo "Running Claude (timeout: ${TIMEOUT_MINUTES}m)..."

    # gtimeout on macOS, timeout on Linux
    if gtimeout $((TIMEOUT_MINUTES * 60))s bash -c 'echo "Implement next task" | claude --dangerously-skip-permissions' > output.log 2>&1; then
        echo "Claude finished"
    else
        if [[ $? -eq 124 ]]; then
            echo "Claude timed out, retrying..."
            continue
        fi
        echo "Claude failed"
    fi

    # Check completion
    incomplete=$(jq '[.userStories[] | select(.passes == false)] | length' prd.json)
    [[ "$incomplete" -eq 0 ]] && break

    sleep 5
done
```

---
--

## Layer 5: The Prompt

Claude needs context. Generate a prompt with:

```bash
generate_prompt() {
    cat << EOF
# Instructions

1. Read prd.json for tasks (stories with passes: false need work)
2. Pick the highest priority incomplete task
3. Implement it
4. Run tests: turbo check-types
5. Commit: git commit -m "feat: [ID] - [Title]"
6. Update prd.json: set passes: true for completed story

## Task List

$(cat prd.json)

## Progress So Far

$(cat progress.txt)

Now implement the next incomplete story.
EOF
}

# Use it
generate_prompt | claude --dangerously-skip-permissions
```

---

## Layer 6: The PRD (Product Requirements Document)

The task list. Structure:

```json
{
  "branchName": "ralph/my-feature",
  "userStories": [
    {
      "id": "1.1",
      "category": "technical",
      "story": "Create database schema for users",
      "steps": [
        "Create migration file",
        "Define users table with id, email, name",
        "Run migration"
      ],
      "acceptance": "Migration runs without error. Table exists in database.",
      "priority": 1,
      "passes": false,
      "notes": ""
    }
  ]
}
```

Fields:
- `id`: "phase.sequence" (1.1, 1.2, 2.1...)
- `category`: technical | functional | ui
- `story`: One sentence, starts with verb
- `steps`: 3-7 actionable steps
- `acceptance`: Definition of "done"
- `priority`: Lower = do first
- `passes`: false until done
- `notes`: Claude fills with learnings

---

## Creating the PRD

### Step 1: Write a Loose Description

Start with a markdown file describing what you want:

```markdown
# Feature: User Subscriptions

I want users to be able to subscribe to plans.
There should be free, pro, and enterprise tiers.
Users can upgrade/downgrade.
Show usage limits based on plan.
```

### Step 2: Have AI Interview You

Ask Claude to interview you about the feature:

```
I want to build [feature]. Ask me clarifying questions
until you understand exactly what I need. Ask one
question at a time.
```

Questions it might ask:
- What payment provider? (Stripe, etc.)
- What happens when limit exceeded?
- Can users switch plans mid-cycle?
- What's the billing cycle?

### Step 3: Convert to PRD

After the interview, ask Claude to write a PRD:

```
Based on our conversation, write a detailed PRD
following this template: [paste prd-template.md]
```

### Step 4: Convert PRD to JSON

Use Claude to convert the markdown PRD to structured JSON:

```bash
#!/bin/bash

# Read the PRD
prd_content=$(cat prd.md)

# Create prompt
cat << 'EOF' > /tmp/convert_prompt.txt
Convert this PRD to JSON with this structure:

{
  "branchName": "ralph/feature-name",
  "userStories": [
    {
      "id": "1.1",
      "category": "technical|functional|ui",
      "story": "One sentence task",
      "steps": ["Step 1", "Step 2"],
      "acceptance": "Definition of done",
      "priority": 1,
      "passes": false,
      "notes": ""
    }
  ]
}

Rules:
- Break into small tasks (30-60 min each)
- Priority 1-10 for MVP, 11-20 for Phase 2
- Lower priority = do first
- Separate DB, API, UI into different stories

PRD:
EOF

echo "$prd_content" >> /tmp/convert_prompt.txt
echo -e "\n\nOutput only valid JSON, no explanation." >> /tmp/convert_prompt.txt

# Run conversion
claude --print < /tmp/convert_prompt.txt > prd.json
```

---

## Full Script Structure

```
ralph/
├── start.sh           # Main loop
├── convert.sh         # PRD → JSON
├── new.sh             # Create new project
├── monitor.sh         # Status dashboard
├── lib/
│   ├── utils.sh       # Colors, logging, helpers
│   ├── circuit_breaker.sh
│   └── response_analyzer.sh
├── templates/
│   ├── PROMPT.md      # Prompt template
│   └── prd-template.md
└── projects/
    └── my-feature/
        ├── prd.md
        ├── prd.json
        ├── progress.txt
        └── logs/
```

---

## Running It

```bash
# 1. Create project
./ralph/new.sh my-feature

# 2. Write your PRD
code ralph/projects/my-feature/prd.md

# 3. Convert to JSON
./ralph/convert.sh my-feature

# 4. Run the loop
./ralph/start.sh my-feature

# Or with tmux monitoring
./ralph/start.sh my-feature --monitor
```

---

## Stopping Conditions

The loop stops when:

1. **All stories pass**: `passes: true` for all items
2. **Complete token**: Claude outputs `<promise>COMPLETE</promise>`
3. **Circuit breaker opens**: No progress for 3 loops, or same error 5 times
4. **Rate limit**: Waits for next hour, then continues
5. **Max iterations**: If `-n 10` flag set

---

## Key Files

### utils.sh

```bash
# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
NC='\033[0m'

# Logging
log() {
    local level=$1
    local message=$2
    echo -e "[$level] $message"
}

# Count stories
count_incomplete() {
    jq '[.userStories[] | select(.passes == false)] | length' "$1"
}
```

### circuit_breaker.sh

```bash
# States: CLOSED (normal), HALF_OPEN (testing), OPEN (halted)

init_circuit_breaker() {
    echo '{"state": "CLOSED", "no_progress_count": 0}' > .circuit_breaker.json
}

should_halt() {
    local state=$(jq -r '.state' .circuit_breaker.json)
    [[ "$state" == "OPEN" ]]
}

record_result() {
    local files_changed=$1
    # If 0 files changed 3 times in a row, open circuit
}
```

---

## Tips

1. **Start small**: First PRD should be 5-10 stories max
2. **Clear acceptance criteria**: Claude needs to know when it's done
3. **Check the logs**: `ralph/projects/<name>/logs/`
4. **Reset if stuck**: `./ralph/start.sh <name> --reset`
5. **Priority matters**: Lower number = done first

---

## Troubleshooting

**Claude not responding**
```bash
# Check logs
tail -f ralph/projects/my-feature/logs/claude_*.log
```

**Circuit breaker opened**
```bash
./ralph/start.sh my-feature --status  # See why
./ralph/start.sh my-feature --reset   # Reset
```

**Rate limit hit**
The script waits automatically. Detach with `Ctrl+B, D` if using tmux.

---

## That's It

The core idea is simple:
1. Define tasks as JSON
2. Loop: run Claude, check if done
3. Add safety: timeout, rate limit, circuit breaker
4. Let it run

The PRD is the key. Good task breakdown = good results.



gotchas:
add playwright mcp to claude:
claude mcp add playwright npx @playwright/mcp@latest

Inttall this on root:
npx playwright@latest install chrome