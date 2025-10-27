#!/bin/bash

# Immersity Unified Stress Testing and Monitoring Tool
# Single script for all testing needs

set -e

# Configuration
BASE_URL="https://somaek.ncsa.illinois.edu"
WEBGL_URL="${BASE_URL}/v0.5.7/index.html"
RELAY_URL="${BASE_URL}"
CONCURRENT_USERS=5
TEST_DURATION=120
MONITOR_INTERVAL=5
LOG_DIR="./stress-test-logs"
TIMESTAMP=$(date +"%Y%m%d_%H%M%S")
MODE="help"

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Create log directory
mkdir -p "$LOG_DIR"

#######################################
# HELPER FUNCTIONS
#######################################

show_banner() {
    echo -e "${BLUE}=== Immersity Stress Testing Tool ===${NC}"
    echo "Mode: $MODE"
    echo "Base URL: $BASE_URL"
    echo "Log Directory: $LOG_DIR"
    echo "Timestamp: $TIMESTAMP"
    echo ""
}

check_service() {
    local service_name=$1
    local url=$2
    
    echo -e "${YELLOW}Checking $service_name at $url...${NC}"
    
    if curl -s --max-time 10 "$url" > /dev/null 2>&1; then
        echo -e "${GREEN}[OK] $service_name is responding${NC}"
        return 0
    else
        echo -e "${RED}[FAILED] $service_name is not responding${NC}"
        return 1
    fi
}

cleanup() {
    echo -e "${YELLOW}Cleaning up...${NC}"
    jobs -p | xargs -r kill 2>/dev/null || true
    echo -e "${GREEN}Cleanup completed${NC}"
}

trap cleanup EXIT

#######################################
# WEBGL STRESS TEST FUNCTIONS
#######################################

test_webgl_application() {
    local user_id=$1
    local client_id=$2
    local session_id=$3
    local log_file="$LOG_DIR/webgl_test_${user_id}_${TIMESTAMP}.log"
    
    echo "User $user_id (Client $client_id): Testing WebGL application..." >> "$log_file"
    
    # Test WebGL page load
    local webgl_url="${WEBGL_URL}?session=${session_id}&client=${client_id}"
    local start_time=$(date +%s)
    
    echo "User $user_id: Loading WebGL page: $webgl_url" >> "$log_file"
    
    if curl -s --max-time 30 "$webgl_url" > /dev/null 2>&1; then
        local end_time=$(date +%s)
        local response_time=$((end_time - start_time))
        echo "User $user_id: WebGL page load time: ${response_time}s" >> "$log_file"
    else
        echo "User $user_id: WebGL page load failed" >> "$log_file"
        return 1
    fi
    
    # Test Unity WebGL files loading
    local unity_files=(
        "Build/UnityLoader.js"
        "Build/v0.5.7.framework.js"
        "Build/v0.5.7.data"
        "Build/v0.5.7.wasm"
    )
    
    for file in "${unity_files[@]}"; do
        local file_url="${BASE_URL}/v0.5.7/${file}"
        local start_time=$(date +%s)
        
        if curl -s --max-time 15 "$file_url" > /dev/null 2>&1; then
            local end_time=$(date +%s)
            local response_time=$((end_time - start_time))
            echo "User $user_id: Loaded $file in ${response_time}s" >> "$log_file"
        else
            echo "User $user_id: Failed to load $file" >> "$log_file"
        fi
        
        sleep 2
    done
    
    # Simulate continuous user activity
    echo "User $user_id: Simulating 3D model navigation..." >> "$log_file"
    
    for i in {1..20}; do
        curl -s --max-time 5 "$webgl_url" > /dev/null 2>&1
        echo "User $user_id: Navigation step $i completed" >> "$log_file"
        sleep 3
    done
}

test_relay_server() {
    local user_id=$1
    local session_id=$2
    local log_file="$LOG_DIR/relay_test_${user_id}_${TIMESTAMP}.log"
    
    echo "User $user_id: Testing relay server for session $session_id..." >> "$log_file"
    
    # Test health endpoint
    local start_time=$(date +%s)
    if curl -s --max-time 10 "$RELAY_URL/sync/health" > /dev/null 2>&1; then
        local end_time=$(date +%s)
        local response_time=$((end_time - start_time))
        echo "User $user_id: Relay health check response time: ${response_time}s" >> "$log_file"
    else
        echo "User $user_id: Relay health check failed" >> "$log_file"
    fi
    
    # Test start recording
    local start_time=$(date +%s)
    if curl -s --max-time 10 -X POST "$RELAY_URL/sync/start_recording/$session_id" > /dev/null 2>&1; then
        local end_time=$(date +%s)
        local response_time=$((end_time - start_time))
        echo "User $user_id: Start recording response time: ${response_time}s" >> "$log_file"
    else
        echo "User $user_id: Start recording failed" >> "$log_file"
    fi
    
    sleep 5
    
    # Test end recording
    local start_time=$(date +%s)
    if curl -s --max-time 10 -X POST "$RELAY_URL/sync/end_recording/$session_id" > /dev/null 2>&1; then
        local end_time=$(date +%s)
        local response_time=$((end_time - start_time))
        echo "User $user_id: End recording response time: ${response_time}s" >> "$log_file"
    else
        echo "User $user_id: End recording failed" >> "$log_file"
    fi
}

simulate_user_session() {
    local user_id=$1
    local client_id=$2
    local session_id=$3
    local log_file="$LOG_DIR/user_${user_id}_${TIMESTAMP}.log"
    
    echo "User $user_id (Client $client_id): Starting session $session_id..." >> "$log_file"
    
    test_webgl_application "$user_id" "$client_id" "$session_id" &
    test_relay_server "$user_id" "$session_id" &
    
    wait
    
    echo "User $user_id: Session $session_id completed" >> "$log_file"
}

run_stress_test() {
    echo -e "${YELLOW}Starting stress test with $CONCURRENT_USERS users...${NC}"
    
    local start_time=$(date +%s)
    local pids=()
    
    for ((i=1; i<=CONCURRENT_USERS; i++)); do
        local client_id=$i
        local session_id="test$(printf "%03d" $i)"
        simulate_user_session "$i" "$client_id" "$session_id" &
        pids+=($!)
        echo "Launched user $i (client=$client_id) with session $session_id"
        sleep 3
    done
    
    echo -e "${YELLOW}Waiting for all users to complete...${NC}"
    for pid in "${pids[@]}"; do
        wait "$pid"
    done
    
    local end_time=$(date +%s)
    local total_time=$((end_time - start_time))
    
    echo -e "${GREEN}Stress test completed in ${total_time}s${NC}"
    
    generate_stress_test_report
}

generate_stress_test_report() {
    local report_file="$LOG_DIR/stress_test_report_${TIMESTAMP}.txt"
    
    echo "=== Immersity Stress Test Report ===" > "$report_file"
    echo "Timestamp: $TIMESTAMP" >> "$report_file"
    echo "Base URL: $BASE_URL" >> "$report_file"
    echo "Concurrent Users: $CONCURRENT_USERS" >> "$report_file"
    echo "" >> "$report_file"
    
    local webgl_success=$(grep -c "WebGL page load time" "$LOG_DIR"/*.log 2>/dev/null || echo "0")
    local unity_files_success=$(grep -c "Loaded.*\.js\|Loaded.*\.wasm\|Loaded.*\.data" "$LOG_DIR"/*.log 2>/dev/null || echo "0")
    local relay_success=$(grep -c "Relay health check response time" "$LOG_DIR"/*.log 2>/dev/null || echo "0")
    
    echo "=== Test Results ===" >> "$report_file"
    echo "WebGL Page Loads: $webgl_success successful" >> "$report_file"
    echo "Unity Files Loaded: $unity_files_success successful" >> "$report_file"
    echo "Relay Health Checks: $relay_success successful" >> "$report_file"
    
    echo -e "${GREEN}Report generated: $report_file${NC}"
}

#######################################
# SYSTEM MONITORING FUNCTIONS
#######################################

get_cpu_usage() {
    top -bn1 | grep "Cpu(s)" | awk '{print $2}' | sed 's/%us,//'
}

get_memory_usage() {
    free -m | awk 'NR==2{printf "%.1f/%.1fMB (%.1f%%)", $3, $2, $3*100/$2}'
}

get_load_average() {
    uptime | awk -F'load average:' '{print $2}' | awk '{print $1}' | sed 's/,//'
}

run_system_monitor() {
    local duration=${1:-$TEST_DURATION}
    local log_file="$LOG_DIR/system_monitor_${TIMESTAMP}.log"
    local csv_file="$LOG_DIR/system_stats_${TIMESTAMP}.csv"
    
    echo "Starting system resource monitoring for ${duration}s..." > "$log_file"
    echo "Timestamp,CPU%,Memory,Load_Avg" > "$csv_file"
    
    echo -e "${YELLOW}Monitoring system resources for ${duration} seconds...${NC}"
    echo "Press Ctrl+C to stop early"
    
    local start_time=$(date +%s)
    local end_time=$((start_time + duration))
    
    while [ $(date +%s) -lt $end_time ]; do
        local current_time=$(date '+%Y-%m-%d %H:%M:%S')
        local timestamp=$(date +%s)
        
        local cpu=$(get_cpu_usage)
        local memory=$(get_memory_usage)
        local load=$(get_load_average)
        
        echo "[$current_time] CPU: ${cpu}% | Memory: ${memory} | Load: ${load}" >> "$log_file"
        echo "${timestamp},${cpu},${memory},${load}" >> "$csv_file"
        
        echo -e "${GREEN}[$current_time]${NC} CPU: ${cpu}% | Memory: ${memory} | Load: ${load}"
        
        sleep $MONITOR_INTERVAL
    done
    
    echo -e "${GREEN}System monitoring completed!${NC}"
    echo "Log file: $log_file"
    echo "CSV file: $csv_file"
    
    generate_system_report "$csv_file"
}

generate_system_report() {
    local csv_file=$1
    local report_file="$LOG_DIR/system_report_${TIMESTAMP}.txt"
    
    echo "=== System Resource Summary Report ===" > "$report_file"
    echo "Timestamp: $TIMESTAMP" >> "$report_file"
    echo "" >> "$report_file"
    
    if [ -f "$csv_file" ]; then
        local avg_cpu=$(tail -n +2 "$csv_file" | awk -F',' '{sum+=$2} END {printf "%.1f", sum/NR}')
        local max_cpu=$(tail -n +2 "$csv_file" | awk -F',' '{if($2>max) max=$2} END {printf "%.1f", max}')
        
        echo "=== CPU Statistics ===" >> "$report_file"
        echo "Average CPU Usage: ${avg_cpu}%" >> "$report_file"
        echo "Peak CPU Usage: ${max_cpu}%" >> "$report_file"
    fi
    
    echo -e "${GREEN}System report generated: $report_file${NC}"
}

#######################################
# MANUAL TESTING MODE
#######################################

run_manual_test() {
    echo -e "${BLUE}=== MANUAL USER TESTING MODE ===${NC}"
    echo ""
    echo "This mode monitors system resources while real users navigate the 3D models."
    echo ""
    echo -e "${GREEN}WebGL Application URLs:${NC}"
    for ((i=1; i<=CONCURRENT_USERS; i++)); do
        local session_id="manual$(printf "%03d" $i)"
        echo "  User $i: ${WEBGL_URL}?session=${session_id}&client=${i}"
    done
    echo ""
    echo -e "${YELLOW}Instructions for users:${NC}"
    echo "1. Each user should open their assigned URL in a web browser"
    echo "2. Wait for the Unity WebGL application to load"
    echo "3. Navigate around the 3D model"
    echo "4. Interact with features and stress test the system"
    echo ""
    echo -e "${YELLOW}Press Enter when all users are ready to start...${NC}"
    read -r
    
    echo -e "${GREEN}Starting system monitoring...${NC}"
    run_system_monitor "$TEST_DURATION" &
    local monitor_pid=$!
    
    echo ""
    echo -e "${YELLOW}Users can now navigate. Press Enter when finished...${NC}"
    read -r
    
    echo -e "${GREEN}Manual testing phase completed!${NC}"
    echo "Stopping system monitoring..."
    kill $monitor_pid 2>/dev/null || true
    wait $monitor_pid 2>/dev/null || true
    
    echo -e "${GREEN}Check $LOG_DIR for results${NC}"
}

#######################################
# MODE EXECUTION
#######################################

mode_automated() {
    show_banner
    
    if ! check_service "WebGL Application" "$WEBGL_URL"; then
        echo -e "${RED}WebGL application is not accessible. Please start services first.${NC}"
        exit 1
    fi
    
    if ! check_service "Relay Server" "$RELAY_URL/sync/health"; then
        echo -e "${RED}Relay server is not running. Please start services first.${NC}"
        exit 1
    fi
    
    echo ""
    echo -e "${GREEN}Services are ready. Starting automated stress test...${NC}"
    echo ""
    
    run_stress_test
    
    echo ""
    echo -e "${GREEN}=== Test Complete ===${NC}"
    echo "Results saved in: $LOG_DIR"
}

mode_monitor() {
    show_banner
    
    echo -e "${GREEN}Starting system resource monitoring...${NC}"
    echo ""
    
    run_system_monitor "$TEST_DURATION"
    
    echo ""
    echo -e "${GREEN}=== Monitoring Complete ===${NC}"
    echo "Results saved in: $LOG_DIR"
}

mode_manual() {
    show_banner
    
    if ! check_service "WebGL Application" "$WEBGL_URL"; then
        echo -e "${RED}WebGL application is not accessible. Please start services first.${NC}"
        exit 1
    fi
    
    if ! check_service "Relay Server" "$RELAY_URL/sync/health"; then
        echo -e "${RED}Relay server is not running. Please start services first.${NC}"
        exit 1
    fi
    
    echo ""
    run_manual_test
    
    echo ""
    echo -e "${GREEN}=== Manual Test Complete ===${NC}"
    echo "Results saved in: $LOG_DIR"
}

mode_complete() {
    show_banner
    
    if ! check_service "WebGL Application" "$WEBGL_URL"; then
        echo -e "${RED}WebGL application is not accessible. Please start services first.${NC}"
        exit 1
    fi
    
    if ! check_service "Relay Server" "$RELAY_URL/sync/health"; then
        echo -e "${RED}Relay server is not running. Please start services first.${NC}"
        exit 1
    fi
    
    echo ""
    echo -e "${GREEN}Running complete test suite...${NC}"
    echo ""
    
    # Phase 1: Automated test
    echo -e "${YELLOW}Phase 1: Automated Stress Test${NC}"
    run_stress_test
    
    echo ""
    
    # Phase 2: Manual testing with monitoring
    echo -e "${YELLOW}Phase 2: Manual Testing with Monitoring${NC}"
    run_manual_test
    
    echo ""
    echo -e "${GREEN}=== Complete Test Suite Finished ===${NC}"
    echo "All results saved in: $LOG_DIR"
}

show_help() {
    echo "Immersity Unified Stress Testing Tool"
    echo ""
    echo "Usage: $0 <mode> [OPTIONS]"
    echo ""
    echo "Modes:"
    echo "  automated    Run automated stress test (simulates users with curl)"
    echo "  monitor      Run system resource monitoring only"
    echo "  manual       Run manual user testing (provides URLs + monitoring)"
    echo "  complete     Run full suite (automated + manual + monitoring)"
    echo ""
    echo "Options:"
    echo "  --users N        Number of concurrent users (default: 5)"
    echo "  --duration N     Test/monitor duration in seconds (default: 120)"
            echo "  --url URL        Base URL for testing (default: https://somaek.ncsa.illinois.edu)"
    echo "  --interval N     Monitor interval in seconds (default: 5)"
    echo "  --help           Show this help message"
    echo ""
    echo "Examples:"
    echo "  $0 automated                           # Run automated test"
    echo "  $0 automated --users 10 --duration 300 # 10 users for 5 minutes"
    echo "  $0 monitor --duration 600              # Monitor for 10 minutes"
    echo "  $0 manual --users 5                    # Manual testing with 5 users"
    echo "  $0 complete                            # Run everything"
    echo ""
    echo "Modes Explained:"
    echo "  - automated: Best for quick performance tests without real users"
    echo "  - monitor:   Best for monitoring while users test separately"
    echo "  - manual:    Best for testing with real users navigating 3D models"
    echo "  - complete:  Best for comprehensive testing (automated + manual)"
}

#######################################
# MAIN
#######################################

# Parse mode
if [ $# -gt 0 ]; then
    MODE=$1
    shift
fi

# Parse arguments
while [[ $# -gt 0 ]]; do
    case $1 in
        --users)
            CONCURRENT_USERS="$2"
            shift 2
            ;;
        --duration)
            TEST_DURATION="$2"
            shift 2
            ;;
        --interval)
            MONITOR_INTERVAL="$2"
            shift 2
            ;;
        --url)
            BASE_URL="$2"
            WEBGL_URL="${BASE_URL}/v0.5.7/index.html"
            RELAY_URL="$BASE_URL"
            shift 2
            ;;
        --help)
            show_help
            exit 0
            ;;
        *)
            echo "Unknown option: $1"
            echo "Use --help for usage information"
            exit 1
            ;;
    esac
done

# Execute mode
case $MODE in
    automated)
        mode_automated
        ;;
    monitor)
        mode_monitor
        ;;
    manual)
        mode_manual
        ;;
    complete)
        mode_complete
        ;;
    help|--help|-h)
        show_help
        ;;
    *)
        echo "Unknown mode: $MODE"
        echo ""
        show_help
        exit 1
        ;;
esac
