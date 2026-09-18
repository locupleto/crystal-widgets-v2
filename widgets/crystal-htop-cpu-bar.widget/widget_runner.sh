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

# Default values for BAR_COLOR and BAR_BORDER_COLOR if not set
BAR_COLOR="${BAR_COLOR:-rgba(30, 144, 255, 1.0)}"
BAR_BORDER_COLOR=${BAR_BORDER_COLOR:-'rgba(255, 255, 255, 0.3)'} 

# Loop through each logical CPU and fetch its usage
USAGES=()
for (( i=1; i<=NUM_CPUS; i++ )); do
    CPU_FILE="$HTOP_TEMP_DIR/htop_cpu_$(printf "%03d" $i).txt"
    if [[ -f "$CPU_FILE" ]]; then
        CPU_USAGE=$(cat "$CPU_FILE")
    else
        CPU_USAGE=0
    fi
    USAGES+=("$CPU_USAGE")
done

# CPU_BARS=physical (crystal_common.sh) folds the hyperthreads of each core
# into a single bar showing their average, so a 6-core/12-thread Intel Mac
# draws six bars instead of twelve. macOS numbers sibling threads
# consecutively (logical CPUs 1-2 share core 1, 3-4 core 2, ...). Machines
# without SMT have as many logical as physical CPUs and are left untouched.
CPUs=""
if [[ "${CPU_BARS:-logical}" == "physical" ]]; then
    NUM_CORES=$(sysctl -n hw.physicalcpu 2>/dev/null || echo 0)
    if (( NUM_CORES > 0 && NUM_CPUS > NUM_CORES && NUM_CPUS % NUM_CORES == 0 )); then
        CPUs=$(printf '%s\n' "${USAGES[@]}" | awk -v per_core=$(( NUM_CPUS / NUM_CORES )) '
            { sum += $1 }
            NR % per_core == 0 { out = out (out == "" ? "" : ";") sprintf("%.1f", sum / per_core); sum = 0 }
            END { printf "%s", out }')
    fi
fi
if [[ -z "$CPUs" ]]; then
    CPUs=$(IFS=';'; echo "${USAGES[*]}")
fi

# Echo the result plus color preference
echo "$CPUs;$BAR_COLOR;$BAR_BORDER_COLOR"
