#!/bin/sh
# Installs clone into installation dir and optionally copies default
# jobs and config files into config dir

install_dir="/usr/local/bin" # Installation dir
clone_dir="$HOME/.clone" # Config dir

cp "clone.sh" "/clone"
mkdir -p "$clone_dir" 2>/dev/null # Creates config dir 
mkdir -p "${clone_dir}/jobs" # Creates jobs dir

# <!-- Warning: overwrites!
#cp "config.sh" "$clone_dir" # Copy default config file 
#cp -r "jobs" "$clone_dir" # Copies example jobs
# !-->
