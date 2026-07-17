#!/bin/bash
#
# crystal-htop-load.widget by locupleto
# https://github.com/locupleto/crystal-widgets
#
# Widget-specific script for htop-load

# Set the widget name based on the directory name
export WIDGET_NAME=$(dirname "$0")

# Ensure that crystal_htop is running, logging to specified tmp dir
common_script="$(dirname "$0")/../crystal_common.sh"
if [ -f "$common_script" ]; then
    source "$common_script"
fi
source "$(dirname "$0")/../crystal_htop_runner.sh"

# Fetch total tasks and threads
TOTAL_TASKS=$(cat "$HTOP_TEMP_DIR/htop_total_tasks.txt" 2>/dev/null || echo "0")
THREADS=$(cat "$HTOP_TEMP_DIR/htop_threads.txt" 2>/dev/null || echo "0")

# Use uptime to get load averages and system uptime
UPTIME_INFO=$(uptime)

# Extract load averages
LOAD_AVG_1=$(echo $UPTIME_INFO | awk -F'load averages: ' '{print $2}' | awk '{print $1}' | sed 's/,//')
LOAD_AVG_2=$(echo $UPTIME_INFO | awk -F'load averages: ' '{print $2}' | awk '{print $2}' | sed 's/,//')
LOAD_AVG_3=$(echo $UPTIME_INFO | awk -F'load averages: ' '{print $2}' | awk '{print $3}')

# Extract uptime
SYSTEM_UPTIME=$(echo $UPTIME_INFO | awk -F'up ' '{print $2}' | awk -F', [0-9]+ users?' '{print $1}')

# Echo the results separated by semicolons
echo "$LOAD_AVG_1;$LOAD_AVG_2;$LOAD_AVG_3;$TOTAL_TASKS;$THREADS;$SYSTEM_UPTIME"