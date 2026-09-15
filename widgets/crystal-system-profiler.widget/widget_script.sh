#!/bin/bash
#
# crystal-system-profiler.widget by locupleto
# https://github.com/locupleto/crystal-widgets
#
# Widget-specific script for system-profiler

# Locate tmp dir for caching
common_script="$(dirname "$0")/../crystal_common.sh"
if [ -f "$common_script" ]; then
    source "$common_script"
fi
export HTOP_TEMP_DIR=${HTOP_TEMP_DIR:-/tmp}

# Übersicht treats anything on stderr as a widget failure and replaces the
# panel with a white error box, so route diagnostics to a log file instead
# (or discard them if the directory cannot be written).
if mkdir -p "$HTOP_TEMP_DIR" 2>/dev/null && touch "$HTOP_TEMP_DIR/crystal-widgets.log" 2>/dev/null; then
    exec 2>>"$HTOP_TEMP_DIR/crystal-widgets.log"
else
    exec 2>/dev/null
fi

# Query each source ONCE and parse from the captured text. system_profiler
# can take seconds on a cold boot and the widget has a 30 s budget before
# Übersicht gives up on the command. fastfetch is asked for just the two
# modules used here, with no logo and no user config, so it can never stall
# on a network-dependent module.
HW=$(system_profiler SPHardwareDataType 2>/dev/null)
FF=""
if [ -n "$FASTFETCH_CMD" ] && [ -x "$FASTFETCH_CMD" ]; then
    FF=$("$FASTFETCH_CMD" -c none --logo none --structure os:cpu 2>/dev/null)
fi

R1=$(echo "$FF" | grep "^OS" | awk -F': ' '{print $2}' | sed -E 's/^(.*[^0-9 ]) ([0-9][0-9.]*).*$/\1 v\2/')

L1=$(echo "$HW" | grep 'Model Name' | awk -F': ' '{print $2}' | tr -d '\n')
L2=$(echo "$HW" | grep 'Chip' | awk -F': ' '{print $2}' | tr -d '\n')

# Check if L2 is empty and if so, attempt to get 'Processor Name' and 'Processor Speed'
if [[ -z "$L2" ]]; then
    processor_name=$(echo "$HW" | grep 'Processor Name' | awk -F': ' '{print $2}' | tr -d '\n')
     L2="${processor_name}"
else
    processor_name=$(echo "$FF" | grep "CPU" | cut -d':' -f2 | cut -d'(' -f1 | xargs)
fi
processor_speed=$(echo "$FF" | grep "CPU" | awk -F' @ ' '{print $2}' | awk '{print $1 " " $2}')

R2=$(echo "$HW" | grep 'Memory:' | awk -F': ' '{print $2 " Memory"}')
L3=$(echo "$HW" | grep 'Total Number of Cores' | awk -F': ' '{print $2}' | awk '{print $1 " cores"}')

# Append processor information to L3 if L2 was initially empty
L3="${L3}, ${processor_speed}"

R3=$(diskutil info /dev/disk0 2>/dev/null | grep 'Disk Size' | awk '{print $3, $4, "ssd"}')

# Return the values the coffee script needs
echo "$L1;$R1;$L2;$R2;$L3;$R3"
