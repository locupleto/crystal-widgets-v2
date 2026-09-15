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

# Übersicht treats anything on stderr as a widget failure and replaces the
# panel with a white error box, so route diagnostics to a log file instead
# (or discard them if the directory cannot be written).
if mkdir -p "$HTOP_TEMP_DIR" 2>/dev/null && touch "$HTOP_TEMP_DIR/crystal-widgets.log" 2>/dev/null; then
    exec 2>>"$HTOP_TEMP_DIR/crystal-widgets.log"
else
    exec 2>/dev/null
fi

# Number of logical CPUs -- the sampler publishes one file per logical CPU.
# sysctl answers instantly; system_profiler can take seconds on a cold boot,
# which is longer than this widget's 1 s refresh budget.
NUM_CPUS=$(sysctl -n hw.logicalcpu 2>/dev/null || echo 0)

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