#!/bin/bash

# Ralph Convert - Convert PRD.md to prd.json and requirements.md using Claude
set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/lib/utils.sh"

CLAUDE_CMD="claude --dangerously-skip-permissions"

show_help() {
    cat << HELPEOF
Ralph Convert - Convert PRD.md to JSON tasks and requirements

Usage: $0 <project-name>

Arguments:
    project-name    Name of the Ralph project to convert

Examples:
    $0 signals
    $0 pagination

This will:
1. Read ralph/projects/<project-name>/prd.md
2. Use Claude to convert it to:
   - prd.json (actionable user stories)
   - requirements.md (technical specifications)

HELPEOF
}

# Create conversion prompt
create_conversion_prompt() {
    local project_name=$1
    local project_dir=$2

    cat << PROMPTEOF
# PRD to Tasks Conversion

You are converting a PRD into actionable tasks. Read and edit the following files:

## Files to work with:
- READ: $project_dir/prd.md (the source PRD)
- EDIT: $project_dir/prd.json (write user stories here)
- EDIT: $project_dir/requirements.md (write technical specs here)

## Instructions:

### 1. First, read the PRD file to understand the requirements.

### 2. Edit prd.json with this structure:
\`\`\`json
{
  "branchName": "ralph/$project_name",
  "userStories": [
    {
      "id": "1.1",
      "category": "technical|functional|ui",
      "story": "Clear one-sentence description starting with action verb",
      "steps": ["Step 1", "Step 2", "Step 3"],
      "acceptance": "Testable criteria for completion",
      "priority": 1,
      "passes": false,
      "notes": ""
    }
  ]
}
\`\`\`

Story guidelines:
- "technical" = Database, API, backend, types/schemas
- "functional" = Business logic, features
- "ui" = Frontend components, pages, styling
- Priority: 1-10 (lower = higher priority, implement first)
- Each story should be completable in 30-60 minutes
- Order by dependencies (infrastructure before features, backend before frontend)

### 3. Edit requirements.md with technical specifications:
- System architecture requirements
- Data models and structures
- API specifications
- User interface requirements
- Performance requirements
- Security considerations

### 4. After editing both files, output a brief summary of what was created.

Important Requirement: For both files, use simple, direct and informational language. Avoid being verbose where it's not necessary.

Now read the PRD and edit the files.
PROMPTEOF
}

main() {
    local project_name="$1"

    # Validate arguments
    if [[ -z "$project_name" ]]; then
        log "ERROR" "Project name is required"
        show_help
        exit 1
    fi

    local project_dir="$SCRIPT_DIR/projects/$project_name"
    local prd_file="$project_dir/prd.md"
    local json_file="$project_dir/prd.json"
    local req_file="$project_dir/requirements.md"

    # Check if project exists
    if [[ ! -d "$project_dir" ]]; then
        log "ERROR" "Project '$project_name' does not exist"
        log "INFO" "Create it first with: ./ralph/new.sh $project_name"
        exit 1
    fi

    # Check if PRD exists
    if [[ ! -f "$prd_file" ]]; then
        log "ERROR" "PRD file not found: $prd_file"
        exit 1
    fi

    # Check if prd.json already has stories
    if [[ -f "$json_file" ]]; then
        local existing_count
        existing_count=$(jq '.userStories | length' "$json_file" 2>/dev/null || echo "0")
        if [[ "$existing_count" -gt 0 ]]; then
            log "WARN" "prd.json already has $existing_count stories"
            echo -n "Overwrite? [y/N] "
            read -r response
            if [[ ! "$response" =~ ^[Yy]$ ]]; then
                log "INFO" "Cancelled"
                exit 0
            fi
        fi
    fi

    log "INFO" "Converting PRD to tasks for project: $project_name"
    log "INFO" "Claude will edit prd.json and requirements.md directly..."

    # Create temp file with conversion prompt
    local temp_prompt=$(mktemp)
    create_conversion_prompt "$project_name" "$project_dir" > "$temp_prompt"

    # Create log file for Claude output
    local timestamp=$(date '+%Y-%m-%d_%H-%M-%S')
    local output_file="$project_dir/logs/convert_${timestamp}.log"
    mkdir -p "$project_dir/logs"

    log "INFO" "Running Claude (output: $output_file)..."

    # Run Claude - redirect output to log file
    if $CLAUDE_CMD < "$temp_prompt" > "$output_file" 2>&1; then
        # Verify files were updated
        local story_count=0
        if [[ -f "$json_file" ]]; then
            story_count=$(jq '.userStories | length' "$json_file" 2>/dev/null || echo "0")
        fi

        if [[ "$story_count" -gt 0 ]]; then
            log "SUCCESS" "Converted PRD to $story_count stories"

            # Show summary
            echo ""
            echo "═══════════════════════════════════════════════════════"
            echo "  CONVERSION SUMMARY"
            echo "═══════════════════════════════════════════════════════"
            echo ""
            echo "Branch: $(jq -r '.branchName // "not set"' "$json_file")"
            echo ""
            echo "Stories by category:"
            jq -r '.userStories | group_by(.category) | .[] | "  \(.[0].category): \(length) stories"' "$json_file" 2>/dev/null || echo "  (unable to group)"
            echo ""
            echo "First 5 stories:"
            jq -r '.userStories | sort_by(.priority) | .[:5][] | "  [\(.id)] P\(.priority) (\(.category)) \(.story)"' "$json_file"
            echo ""
            echo "═══════════════════════════════════════════════════════"
            echo ""
            echo "Next steps:"
            echo "  1. Review: cat $json_file | jq ."
            echo "  2. Start:  ./ralph/start.sh $project_name"
            echo ""
        else
            log "WARN" "prd.json has no stories - conversion may have failed"
            log "INFO" "Check the files manually:"
            echo "  cat $json_file"
            echo "  cat $req_file"
        fi
    else
        log "ERROR" "Claude conversion failed"
        exit 1
    fi

    # Cleanup
    rm -f "$temp_prompt"
}

# Handle command line arguments
case "${1:-}" in
    -h|--help)
        show_help
        exit 0
        ;;
    "")
        show_help
        exit 1
        ;;
    *)
        main "$@"
        ;;
esac
