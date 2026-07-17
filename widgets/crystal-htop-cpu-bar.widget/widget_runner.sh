#!/bin/bash
#
# crystal-htop-cpu-bar.widget by locupleto
# https://github.com/locupleto/crystal-widgets
#
# Widget-specific script for htop-cpu-bar

# Set the widget name based on the directory name
export WIDGET_NAME=$(dirname "$0")

# Ensure that crystal_htop is running, logging to specified tmp dir
source "$(dirname "$0")/../crystal_common.sh"
source "$(dirname "$0")/../crystal_htop_runner.sh"

# Fetch the total number of CPU cores
NUM_CPUS=$(system_profiler SPHardwareDataType 2>/dev/null | grep 'Total Number of Cores' | awk -F': ' '{print $2}' | awk '{print $1}')

# Initialize the CPUs string
CPUs=""

# Default values for BAR_COLOR and BAR_BORDER_COLOR if not set
BAR_COLOR="${BAR_COLOR:-rgba(30, 144, 255, 1.0)}"
BAR_BORDER_COLOR=${BAR_BORDER_COLOR:-'rgba(255, 255, 255, 0.3)'} 

# Loop through each CPU and fetch its usage
for (( i=1; i<=NUM_CPUS; i++ )); do
    CPU_FILE="$HTOP_TEMP_DIR/htop_cpu_$(printf "%03d" $i).txt"
    if [[ -f "$CPU_FILE" ]]; then
        CPU_USAGE=$(cat "$CPU_FILE")
    else
        CPU_USAGE=0
    fi
    CPUs+="$CPU_USAGE;"
done

# Remove the trailing semi-colon
CPUs=${CPUs%?}

# Echo the result plus color preference
echo "$CPUs;$BAR_COLOR;$BAR_BORDER_COLOR"