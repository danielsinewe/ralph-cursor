#!/bin/bash

# Ralph Circuit Breaker - Prevents runaway loops
# Detects stagnation, repeated errors, and auto-halts

# Circuit breaker states
CB_STATE_CLOSED="CLOSED"       # Normal operation
CB_STATE_HALF_OPEN="HALF_OPEN" # Testing if recovered
CB_STATE_OPEN="OPEN"           # Halted, needs intervention

# Thresholds (configurable)
CB_NO_PROGRESS_THRESHOLD=${CB_NO_PROGRESS_THRESHOLD:-3}
CB_SAME_ERROR_THRESHOLD=${CB_SAME_ERROR_THRESHOLD:-5}
CB_OUTPUT_DECLINE_THRESHOLD=${CB_OUTPUT_DECLINE_THRESHOLD:-70}

# Circuit breaker state file
CB_STATE_FILE=".circuit_breaker.json"

# Initialize circuit breaker
init_circuit_breaker() {
    local project_dir=$1
    local cb_file="$project_dir/$CB_STATE_FILE"
    
    if [[ ! -f "$cb_file" ]]; then
        cat > "$cb_file" << EOF
{
    "state": "$CB_STATE_CLOSED",
    "no_progress_count": 0,
    "same_error_count": 0,
    "last_error": "",
    "last_files_changed": 0,
    "last_output_length": 0,
    "history": [],
    "opened_at": null,
    "opened_reason": null
}
EOF
    fi
}

# Get current circuit breaker state
get_circuit_state() {
    local project_dir=$1
    local cb_file="$project_dir/$CB_STATE_FILE"
    
    if [[ -f "$cb_file" ]]; then
        jq -r '.state' "$cb_file"
    else
        echo "$CB_STATE_CLOSED"
    fi
}

# Check if circuit breaker should halt execution
should_halt_execution() {
    local project_dir=$1
    local state=$(get_circuit_state "$project_dir")
    
    [[ "$state" == "$CB_STATE_OPEN" ]]
}

# Record loop result and update circuit breaker
record_loop_result() {
    local project_dir=$1
    local loop_count=$2
    local files_changed=$3
    local has_errors=$4
    local output_length=$5
    local error_message=${6:-""}
    
    local cb_file="$project_dir/$CB_STATE_FILE"
    
    if [[ ! -f "$cb_file" ]]; then
        init_circuit_breaker "$project_dir"
    fi
    
    local current_state=$(jq -r '.state' "$cb_file")
    local no_progress_count=$(jq -r '.no_progress_count' "$cb_file")
    local same_error_count=$(jq -r '.same_error_count' "$cb_file")
    local last_error=$(jq -r '.last_error' "$cb_file")
    local last_output=$(jq -r '.last_output_length' "$cb_file")
    
    local new_state="$current_state"
    local open_reason=""
    
    # Check for no progress
    if [[ "$files_changed" -eq 0 ]]; then
        no_progress_count=$((no_progress_count + 1))
        if [[ $no_progress_count -ge $CB_NO_PROGRESS_THRESHOLD ]]; then
            new_state="$CB_STATE_OPEN"
            open_reason="No file changes in $no_progress_count consecutive loops"
        fi
    else
        no_progress_count=0
    fi
    
    # Check for repeated errors
    if [[ "$has_errors" == "true" ]]; then
        if [[ "$error_message" == "$last_error" && -n "$last_error" ]]; then
            same_error_count=$((same_error_count + 1))
            if [[ $same_error_count -ge $CB_SAME_ERROR_THRESHOLD ]]; then
                new_state="$CB_STATE_OPEN"
                open_reason="Same error repeated $same_error_count times"
            fi
        else
            same_error_count=1
        fi
    else
        same_error_count=0
        error_message=""
    fi
    
    # Check for output decline
    if [[ $last_output -gt 0 && $output_length -gt 0 ]]; then
        local decline_percent=$(( (last_output - output_length) * 100 / last_output ))
        if [[ $decline_percent -gt $CB_OUTPUT_DECLINE_THRESHOLD ]]; then
            log "WARN" "Output declined by ${decline_percent}% (possible stagnation)"
        fi
    fi
    
    # Update state file
    local timestamp=$(date -u '+%Y-%m-%dT%H:%M:%SZ')
    local tmp_file=$(mktemp)
    
    jq --arg state "$new_state" \
       --argjson no_progress "$no_progress_count" \
       --argjson same_error "$same_error_count" \
       --arg last_err "$error_message" \
       --argjson files "$files_changed" \
       --argjson output "$output_length" \
       --arg reason "$open_reason" \
       --arg ts "$timestamp" \
       --argjson loop "$loop_count" \
       '.state = $state |
        .no_progress_count = $no_progress |
        .same_error_count = $same_error |
        .last_error = $last_err |
        .last_files_changed = $files |
        .last_output_length = $output |
        .history += [{
            "loop": $loop,
            "timestamp": $ts,
            "files_changed": $files,
            "output_length": $output
        }] |
        .history = (.history | .[-10:]) |
        if $state == "OPEN" then
            .opened_at = $ts |
            .opened_reason = $reason
        else . end' \
       "$cb_file" > "$tmp_file" && mv "$tmp_file" "$cb_file"
    
    if [[ "$new_state" == "$CB_STATE_OPEN" && "$current_state" != "$CB_STATE_OPEN" ]]; then
        log "ERROR" "🛑 Circuit breaker OPENED: $open_reason"
        return 1
    fi
    
    return 0
}

# Reset circuit breaker
reset_circuit_breaker() {
    local project_dir=$1
    local reason=${2:-"Manual reset"}
    local cb_file="$project_dir/$CB_STATE_FILE"
    
    if [[ -f "$cb_file" ]]; then
        local tmp_file=$(mktemp)
        jq --arg reason "$reason" \
           '.state = "CLOSED" |
            .no_progress_count = 0 |
            .same_error_count = 0 |
            .last_error = "" |
            .opened_at = null |
            .opened_reason = null |
            .history += [{"event": "reset", "reason": $reason, "timestamp": now | todate}]' \
           "$cb_file" > "$tmp_file" && mv "$tmp_file" "$cb_file"
        
        log "SUCCESS" "Circuit breaker reset: $reason"
    fi
}

# Show circuit breaker status
show_circuit_status() {
    local project_dir=$1
    local cb_file="$project_dir/$CB_STATE_FILE"
    
    if [[ ! -f "$cb_file" ]]; then
        echo "Circuit breaker not initialized"
        return
    fi
    
    echo "Circuit Breaker Status"
    echo "======================"
    echo ""
    jq -r '
        "State:            \(.state)",
        "No Progress Count: \(.no_progress_count)/'"$CB_NO_PROGRESS_THRESHOLD"'",
        "Same Error Count:  \(.same_error_count)/'"$CB_SAME_ERROR_THRESHOLD"'",
        (if .last_error != "" then "Last Error:        \(.last_error)" else empty end),
        (if .opened_at then "Opened At:         \(.opened_at)" else empty end),
        (if .opened_reason then "Opened Reason:     \(.opened_reason)" else empty end)
    ' "$cb_file"
}
