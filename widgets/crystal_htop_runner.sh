#!/bin/bash
#
# crystal_htop_runner.sh by locupleto
# https://github.com/locupleto/crystal-widgets
#
# Common runner script for the crystal htop-style widgets.
#
# Ensures a single crystal_sampler daemon is running (it replaces the old
# crystal-htop fork: same output files, plus an atomic metrics.json with a
# heartbeat timestamp). The sampler holds an exclusive lock per output
# directory, so accidental double-starts exit immediately.
#
# Inspect:    cat "$HTOP_TEMP_DIR/metrics.json"
# Terminate:  pkill -x crystal_sampler
#
# Note: This script should be placed in the top ubersicht directory
# alongside the crystal_sampler binary.

# Source the common configuration script if the widget has not already
common_script="$(dirname "${BASH_SOURCE[0]:-$0}")/crystal_common.sh"
[ -z "$HTOP_TEMP_DIR" ] && [ -f "$common_script" ] && source "$common_script"

export HTOP_TEMP_DIR=${HTOP_TEMP_DIR:-/tmp}

if ! /usr/bin/pgrep -q -x crystal_sampler 2>/dev/null; then
    SAMPLER_DIR="$(cd "$(dirname "${BASH_SOURCE[0]:-$0}")" && pwd)"
    mkdir -p "$HTOP_TEMP_DIR"
    nohup "$SAMPLER_DIR/crystal_sampler" 1 >/dev/null 2>&1 &
    disown 2>/dev/null

    # Give the sampler a moment to publish its first files on cold start
    sleep 1
fi
