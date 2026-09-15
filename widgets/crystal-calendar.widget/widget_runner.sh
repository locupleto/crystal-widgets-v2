#!/bin/bash

# crystal-calendar.widget by locupleto
# https://github.com/locupleto/crystal-widgets
#
# Based on calendar by felixHageloh
# https://github.com/felixhageloh/uebersicht-widgets/
#
# Widget-specific script for crystal-calendar

# Set the widget name based on the directory name
export WIDGET_NAME=$(dirname "$0")

# Source the common configuration script
source "$(dirname "$0")/../crystal_common.sh"
export HTOP_TEMP_DIR=${HTOP_TEMP_DIR:-/tmp}
export START_DAY_OF_WEEK=${START_DAY_OF_WEEK:-SUNDAY}

# Übersicht treats anything on stderr as a widget failure and replaces the
# panel with a white error box, so route diagnostics to a log file instead
# (or discard them if the directory cannot be written).
if mkdir -p "$HTOP_TEMP_DIR" 2>/dev/null && touch "$HTOP_TEMP_DIR/crystal-widgets.log" 2>/dev/null; then
    exec 2>>"$HTOP_TEMP_DIR/crystal-widgets.log"
else
    exec 2>/dev/null
fi

# Define calendar commands
sundayFirstCalendar='cal -h && date "+%-m %-d %y"'
mondayFirstCalendar=$(
cat <<'EOF'
cal -h | awk '{ print " "$0; getline; print "Mo Tu We Th Fr Sa Su"; getline; if (substr($0,1,2) == " 1") print "                    1 "; do { prevline=$0; if (getline == 0) exit; print " " substr(prevline,4,17) " " substr($0,1,2) " "; } while (1) }' && date "+%-m %-d %y"
EOF
)

# Execute the appropriate calendar command based on START_DAY_OF_WEEK
if [ "$START_DAY_OF_WEEK" = "SUNDAY" ]; then
    eval $sundayFirstCalendar
else
    eval $mondayFirstCalendar
fi
