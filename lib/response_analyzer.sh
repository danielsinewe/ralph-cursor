#!/bin/bash

# Ralph Response Analyzer - Analyzes Claude Code output
# Detects completion signals, errors, and progress

# Analysis result file
ANALYSIS_FILE=".last_analysis.json"

# Analyze Claude Code response
analyze_response() {
    local output_file=$1
    local project_dir=$2
    local analysis_file="$project_dir/$ANALYSIS_FILE"
    
    if [[ ! -f "$output_file" ]]; then
        log "WARN" "No output file to analyze"
        return 1
    fi
    
    local output_content=$(cat "$output_file")
    local output_length=${#output_content}
    
    # Extract RALPH_STATUS block if present
    local status_block=""
    local status=""
    local tasks_completed=0
    local files_modified=0
    local tests_status="NOT_RUN"
    local work_type="UNKNOWN"
    local exit_signal="false"
    local recommendation=""
    
    if grep -q -- "---RALPH_STATUS---" "$output_file"; then
        status_block=$(sed -n '/---RALPH_STATUS---/,/---END_RALPH_STATUS---/p' "$output_file")
        
        status=$(echo "$status_block" | grep "^STATUS:" | sed 's/STATUS: *//')
        tasks_completed=$(echo "$status_block" | grep "^TASKS_COMPLETED_THIS_LOOP:" | sed 's/TASKS_COMPLETED_THIS_LOOP: *//')
        files_modified=$(echo "$status_block" | grep "^FILES_MODIFIED:" | sed 's/FILES_MODIFIED: *//')
        tests_status=$(echo "$status_block" | grep "^TESTS_STATUS:" | sed 's/TESTS_STATUS: *//')
        work_type=$(echo "$status_block" | grep "^WORK_TYPE:" | sed 's/WORK_TYPE: *//')
        exit_signal=$(echo "$status_block" | grep "^EXIT_SIGNAL:" | sed 's/EXIT_SIGNAL: *//')
        recommendation=$(echo "$status_block" | grep "^RECOMMENDATION:" | sed 's/RECOMMENDATION: *//')
    fi
    
    # Detect completion signals in text
    local completion_signals=0
    local completion_patterns=(
        "all.*complete"
        "project.*complete"
        "nothing.*left.*to.*implement"
        "all.*tasks.*done"
        "implementation.*complete"
        "feature.*complete"
    )
    
    for pattern in "${completion_patterns[@]}"; do
        if grep -qiE "$pattern" "$output_file"; then
            completion_signals=$((completion_signals + 1))
        fi
    done
    
    # Detect errors (two-stage filtering to avoid false positives)
    local has_errors="false"
    local error_count=0
    local error_message=""
    
    # Stage 1: Filter out JSON field patterns, then check for real errors
    if grep -v '"[^"]*error[^"]*":' "$output_file" 2>/dev/null | \
       grep -qE '(^Error:|^ERROR:|^error:|\]: error|Error occurred|failed with error|[Ee]xception|Fatal|FATAL)'; then
        has_errors="true"
        error_count=$(grep -v '"[^"]*error[^"]*":' "$output_file" 2>/dev/null | \
                     grep -cE '(^Error:|^ERROR:|^error:|\]: error|Error occurred|failed with error|[Ee]xception|Fatal|FATAL)' || echo "0")
        error_message=$(grep -v '"[^"]*error[^"]*":' "$output_file" 2>/dev/null | \
                       grep -E '(^Error:|^ERROR:|^error:|\]: error|Error occurred|failed with error|[Ee]xception|Fatal|FATAL)' | head -1)
    fi
    
    # Detect test-only loop
    local is_test_only="false"
    if [[ "$work_type" == "TESTING" && "$files_modified" == "0" ]]; then
        is_test_only="true"
    fi
    
    # Write analysis result
    cat > "$analysis_file" << EOF
{
    "timestamp": "$(date -u '+%Y-%m-%dT%H:%M:%SZ')",
    "output_length": $output_length,
    "has_status_block": $([ -n "$status_block" ] && echo "true" || echo "false"),
    "status": "$status",
    "tasks_completed": ${tasks_completed:-0},
    "files_modified": ${files_modified:-0},
    "tests_status": "$tests_status",
    "work_type": "$work_type",
    "exit_signal": $exit_signal,
    "recommendation": "$recommendation",
    "completion_signals": $completion_signals,
    "has_errors": $has_errors,
    "error_count": $error_count,
    "error_message": "$(echo "$error_message" | head -c 200 | sed 's/"/\\"/g')",
    "is_test_only": $is_test_only
}
EOF
    
    # Return appropriate exit code
    if [[ "$exit_signal" == "true" ]]; then
        return 2  # Signal to exit loop
    elif [[ "$has_errors" == "true" ]]; then
        return 1  # Has errors
    else
        return 0  # Normal
    fi
}

# Get last analysis result
get_analysis_result() {
    local project_dir=$1
    local field=$2
    local analysis_file="$project_dir/$ANALYSIS_FILE"
    
    if [[ -f "$analysis_file" ]]; then
        jq -r ".$field" "$analysis_file"
    else
        echo ""
    fi
}

# Check if should exit based on analysis
should_exit_gracefully() {
    local project_dir=$1
    local analysis_file="$project_dir/$ANALYSIS_FILE"
    
    if [[ ! -f "$analysis_file" ]]; then
        return 1  # Don't exit
    fi
    
    local exit_signal=$(jq -r '.exit_signal' "$analysis_file")
    local completion_signals=$(jq -r '.completion_signals' "$analysis_file")
    
    # Exit if Claude signaled completion
    if [[ "$exit_signal" == "true" ]]; then
        echo "exit_signal"
        return 0
    fi
    
    # Exit if multiple completion signals detected
    if [[ $completion_signals -ge 2 ]]; then
        echo "completion_signals"
        return 0
    fi
    
    return 1
}

# Log analysis summary
log_analysis_summary() {
    local project_dir=$1
    local analysis_file="$project_dir/$ANALYSIS_FILE"
    
    if [[ ! -f "$analysis_file" ]]; then
        return
    fi
    
    local status=$(jq -r '.status' "$analysis_file")
    local tasks=$(jq -r '.tasks_completed' "$analysis_file")
    local files=$(jq -r '.files_modified' "$analysis_file")
    local tests=$(jq -r '.tests_status' "$analysis_file")
    local work=$(jq -r '.work_type' "$analysis_file")
    local exit_sig=$(jq -r '.exit_signal' "$analysis_file")
    
    log "INFO" "Analysis: status=$status, tasks=$tasks, files=$files, tests=$tests, work=$work, exit=$exit_sig"
}
