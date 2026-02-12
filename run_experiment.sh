#!/bin/bash
set -e

# --- Configuration ---
RECORDINGS_DIR="recordings"
mkdir -p "$RECORDINGS_DIR"

FILE_INITIAL="$RECORDINGS_DIR/01_initial.txt"
FILE_CPU_PEAK="$RECORDINGS_DIR/02_cpu_peak.txt"
FILE_POST_CPU_RESTART="$RECORDINGS_DIR/03_post_cpu_restart.txt"
FILE_MEM_PEAK="$RECORDINGS_DIR/04_mem_peak.txt"
FILE_POST_MEM_RESTART="$RECORDINGS_DIR/05_post_mem_restart.txt"
SUMMARY_FILE="$RECORDINGS_DIR/summary.md"

# Clear previous recordings
rm -f "$RECORDINGS_DIR"/*

# --- Functions ---

# Helper to get current metrics
get_metrics() {
    local POD_NAME=$(kubectl get pods -n my-app -l app=my-app -o jsonpath="{.items[0].metadata.name}")
    
    local POD_CPU=$(kubectl get pod "$POD_NAME" -n my-app -o jsonpath="{.spec.containers[0].resources.requests.cpu}")
    local POD_MEM=$(kubectl get pod "$POD_NAME" -n my-app -o jsonpath="{.spec.containers[0].resources.requests.memory}")
    local POD_CPU_LIM=$(kubectl get pod "$POD_NAME" -n my-app -o jsonpath="{.spec.containers[0].resources.limits.cpu}")
    local POD_MEM_LIM=$(kubectl get pod "$POD_NAME" -n my-app -o jsonpath="{.spec.containers[0].resources.limits.memory}")
    
    local VPA_CPU=$(kubectl get vpa my-app-vpa -n my-app -o jsonpath="{.status.recommendation.containerRecommendations[0].target.cpu}")
    local VPA_MEM=$(kubectl get vpa my-app-vpa -n my-app -o jsonpath="{.status.recommendation.containerRecommendations[0].target.memory}")

    # Return as space-separated string. Use "N/A" if VPA is empty.
    echo "${POD_CPU:-N/A} ${POD_MEM:-N/A} ${POD_CPU_LIM:-N/A} ${POD_MEM_LIM:-N/A} ${VPA_CPU:-N/A} ${VPA_MEM:-N/A}"
}

# Function to record verbose data
record_details() {
    local OUTFILE=$1
    local DESC=$2
    
    echo "Recording details for: $DESC..."
    {
        echo "=================================================="
        echo "STEP: $DESC"
        echo "DATE: $(date)"
        echo "=================================================="
        echo ""
        echo "--- POD SPEC (Live) ---"
        local POD_NAME=$(kubectl get pods -n my-app -l app=my-app -o jsonpath="{.items[0].metadata.name}")
        kubectl get pod "$POD_NAME" -n my-app -o yaml | sed -n '/resources:/,/status:/p' | sed '$d'
        
        echo ""
        echo "--- VPA STATUS ---"
        kubectl get vpa my-app-vpa -n my-app -o yaml | sed -n '/status:/,$p'
    } > "$OUTFILE"
}

# Function to add row to summary
update_summary() {
    local STEP_NAME=$1
    # Read metrics into array
    read -r PC PM PCL PML VC VM <<< "$(get_metrics)"
    
    # Format line for markdown table
    # | Step | Pod CPU Req | Pod Mem Req | Pod CPU Lim | Pod Mem Lim | VPA CPU Tgt | VPA Mem Tgt |
    echo "| $STEP_NAME | $PC | $PM | $PCL | $PML | $VC | $VM |" >> "$SUMMARY_FILE"
}

# --- Main Execution ---

echo "Starting VPA Experiment..."

echo "Initializing Summary File..."
{
    echo "# VPA Experiment Summary"
    echo ""
    echo "| Step | Pod CPU Req | Pod Mem Req | Pod CPU Lim | Pod Mem Lim | VPA CPU Tgt | VPA Mem Tgt |"
    echo "|---|---|---|---|---|---|---|"
} > "$SUMMARY_FILE"


# 1. Setup
echo "--- 1. Setup & Deploy ---"
task setup
task example:create

echo "Waiting 2 minutes for baseline..."
sleep 120

record_details "$FILE_INITIAL" "Initial Baseline"
update_summary "1. Initial"


# 2. CPU Spike
echo "--- 2. CPU Spike ---"
task example:cpu-spike
echo "Waiting 3 minutes for VPA reaction..."
sleep 180

record_details "$FILE_CPU_PEAK" "After CPU Spike"
update_summary "2. After CPU Spike"


# 3. CPU Cleanup
echo "--- 3. CPU Cleanup (Restart) ---"
task example:restart
echo "Waiting 1 minute for stabilization..."
sleep 60

record_details "$FILE_POST_CPU_RESTART" "After CPU Restart"
update_summary "3. Post-CPU Restart"


# 4. Memory Spike
echo "--- 4. Memory Spike ---"
task example:mem-spike
echo "Waiting 3 minutes for VPA reaction..."
sleep 180

record_details "$FILE_MEM_PEAK" "After Memory Spike"
update_summary "4. After Mem Spike"


# 5. Memory Cleanup
echo "--- 5. Memory Cleanup (Restart) ---"
task example:restart
echo "Waiting 1 minute for stabilization..."
sleep 60

record_details "$FILE_POST_MEM_RESTART" "After Memory Restart"
update_summary "5. Post-Mem Restart"


echo "Experiment Complete!"
echo "Summary available at: $SUMMARY_FILE"
cat "$SUMMARY_FILE"
