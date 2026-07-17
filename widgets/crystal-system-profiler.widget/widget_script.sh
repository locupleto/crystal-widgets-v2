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

R1=$($FASTFETCH_CMD | grep "OS" | awk -F': ' '{print $2}' | awk '{print $1 " " $2 " v" $3}')

# Corrected variable assignments
L1=$(system_profiler SPHardwareDataType 2>/dev/null | grep 'Model Name' | awk -F': ' '{print $2}' | tr -d '\n')
L2=$(system_profiler SPHardwareDataType 2>/dev/null | grep 'Chip' | awk -F': ' '{print $2}' | tr -d '\n')

# Check if L2 is empty and if so, attempt to get 'Processor Name' and 'Processor Speed'
if [[ -z "$L2" ]]; then
    processor_name=$(system_profiler SPHardwareDataType 2>/dev/null | grep 'Processor Name' | awk -F': ' '{print $2}' | tr -d '\n')
     L2="${processor_name}"
else
    processor_name=$($FASTFETCH_CMD | grep "CPU" | cut -d':' -f2 | cut -d'(' -f1 | xargs)
fi
processor_speed=$($FASTFETCH_CMD | grep "CPU" | awk -F' @ ' '{print $2}' | awk '{print $1 " " $2}')

R2=$(system_profiler SPHardwareDataType 2>/dev/null | grep 'Memory:' | awk -F': ' '{print $2 " Memory"}')
L3=$(system_profiler SPHardwareDataType 2>/dev/null | grep 'Total Number of Cores' | awk -F': ' '{print $2}' | awk '{print $1 " cores"}')

# Append processor information to L3 if L2 was initially empty
L3="${L3}, ${processor_speed}"

R3=$(diskutil info /dev/disk0 | grep 'Disk Size' | awk '{print $3, $4, "ssd"}')

# Return the values the coffee script needs
echo "$L1;$R1;$L2;$R2;$L3;$R3"
