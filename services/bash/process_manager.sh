#!/bin/bash

# Process management utilities

# Check if process is running
is_running() {
    local pid="$1"
    kill -0 "$pid" 2>/dev/null
}

# Get process PID by name
get_pid() {
    local name="$1"
    pgrep -f "$name" | head -1
}

# Kill process by name
kill_process() {
    local name="$1"
    pkill -f "$name"
}

# Wait for process to finish
wait_for_process() {
    local pid="$1"
    local timeout="${2:-30}"
    local elapsed=0
    
    while is_running "$pid"; do
        if [ $elapsed -ge $timeout ]; then
            echo "Timeout waiting for process $pid"
            return 1
        fi
        sleep 1
        elapsed=$((elapsed + 1))
    done
    
    return 0
}

# Run process in background
run_background() {
    local cmd="$1"
    local log="${2:-/dev/null}"
    
    nohup $cmd > "$log" 2>&1 &
    echo $!
}

# Check process CPU usage
get_cpu_usage() {
    local pid="$1"
    ps -p "$pid" -o %cpu= | tr -d ' '
}

# Check process memory usage
get_memory_usage() {
    local pid="$1"
    ps -p "$pid" -o %mem= | tr -d ' '
}

# List all processes by user
list_user_processes() {
    local user="${1:-$USER}"
    ps -u "$user" -o pid,cmd
}

# Monitor process
monitor_process() {
    local pid="$1"
    local interval="${2:-1}"
    
    while is_running "$pid"; do
        local cpu=$(get_cpu_usage "$pid")
        local mem=$(get_memory_usage "$pid")
        echo "PID: $pid | CPU: ${cpu}% | MEM: ${mem}%"
        sleep "$interval"
    done
}

# Restart service
restart_service() {
    local service="$1"
    sudo systemctl restart "$service"
}
