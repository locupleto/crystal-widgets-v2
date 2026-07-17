#!/bin/bash
#
# crystal_common.sh settings file by locupleto
# https://github.com/locupleto/crystal-widgets
#
# This file contains some common settings for the widgets

# Working directory for htop-related widgets, (defaults to /tmp if not set)
export HTOP_TEMP_DIR=$HOME/tmp

# crystal-calendar Start day of the week (defaults to SUNDAY if not set)
export START_DAY_OF_WEEK="MONDAY"

# ------ Example bar color schemes to play with -----------------------------

# Default bar color is semi-transparent gold with white outline
#export BAR_COLOR=${BAR_COLOR:-'rgba(255, 204, 0, 0.5)'} 
#export BAR_BORDER_COLOR=${BAR_BORDER_COLOR:-'rgba(255, 255, 255, 0.3)'}  

# Dodger Blue with 50% transparency
export BAR_COLOR='rgba(30, 144, 255, 1.0)'  
export BAR_BORDER_COLOR='rgba(30, 144, 255, 1.0)' 

# Medium Sea Green with full opacity
#export BAR_COLOR='rgba(60, 179, 113, 1.0)'  
#export BAR_BORDER_COLOR='rgba(60, 179, 113, 0.3)' 

# Spring Green with full opacity
#export BAR_COLOR='rgba(0, 255, 127, 1.0)'  
#export BAR_BORDER_COLOR='rgba(0, 255, 127, 0.3)'  

# ------ Paths to installation specific command-line tools ------------------

export FASTFETCH_CMD=/opt/homebrew/bin/fastfetch
