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

# Übersicht treats anything on stderr as a widget failure and replaces the
# panel with a white error box, so route diagnostics to a log file instead
# (or discard them if the directory cannot be written).
if mkdir -p "$HTOP_TEMP_DIR" 2>/dev/null && touch "$HTOP_TEMP_DIR/crystal-widgets.log" 2>/dev/null; then
    exec 2>>"$HTOP_TEMP_DIR/crystal-widgets.log"
else
    exec 2>/dev/null
fi

# Return the values the coffee script needs
if [[ -f "$HTOP_TEMP_DIR/htop_swap_total.txt" ]] && [[ -f "$HTOP_TEMP_DIR/htop_swap_used.txt" ]]; then
    total=$(cat "$HTOP_TEMP_DIR/htop_swap_total.txt")
    used=$(cat "$HTOP_TEMP_DIR/htop_swap_used.txt")
    echo "$total $used $BAR_COLOR $BAR_COLOR"
else
    echo "0 0 $BAR_COLOR $BAR_COLOR"
fi
