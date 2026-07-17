#!/bin/bash
#
# crystal-htop-swap-bar.widget by locupleto
# https://github.com/locupleto/crystal-widgets
#
# Widget-specific script for htop-swap-bar

# Set the widget name based on the directory name
export WIDGET_NAME=$(dirname "$0")

# Ensure that crystal_htop is running, logging to specified tmp dir
common_script="$(dirname "$0")/../crystal_common.sh"
if [ -f "$common_script" ]; then
    source "$common_script"
fi
source "$(dirname "$0")/../crystal_htop_runner.sh"

# Return the values the coffee script needs
if [[ -f "$HTOP_TEMP_DIR/htop_swap_total.txt" ]] && [[ -f "$HTOP_TEMP_DIR/htop_swap_used.txt" ]]; then
    total=$(cat "$HTOP_TEMP_DIR/htop_swap_total.txt")
    used=$(cat "$HTOP_TEMP_DIR/htop_swap_used.txt")
    echo "$total $used $BAR_COLOR $BAR_COLOR"
else
    echo "0 0 $BAR_COLOR $BAR_COLOR"
fi
