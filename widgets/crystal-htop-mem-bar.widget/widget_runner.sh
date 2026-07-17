#!/bin/bash
#
# crystal-htop-mem-bar.widget by locupleto
# https://github.com/locupleto/crystal-widgets
#
# Widget-specific script for htop-mem-bar

# Set the widget name based on the directory name
export WIDGET_NAME=$(dirname "$0")

# Ensure that crystal_htop is running, logging to specified tmp dir
common_script="$(dirname "$0")/../crystal_common.sh"
if [ -f "$common_script" ]; then
    source "$common_script"
fi
source "$(dirname "$0")/../crystal_htop_runner.sh"

# Check if memory files exist and pass the color variables
if [[ -f "$HTOP_TEMP_DIR/htop_mem_avail.txt" ]] && [[ -f "$HTOP_TEMP_DIR/htop_mem_used.txt" ]]; then
    echo $(cat "$HTOP_TEMP_DIR/htop_mem_avail.txt") $(cat "$HTOP_TEMP_DIR/htop_mem_used.txt") $BAR_COLOR $BAR_COLOR
else
    echo "0 0 0 0 $BAR_COLOR $BAR_COLOR"
fi
