#!/bin/bash
#   ____ _                        _
#  / ___| | ___  _ __   ___   ___| |__
# | |   | |/ _ \| '_ \ / _ \ / __| '_ \  - Clone simple backup utility
# | |___| | (_) | | | |  __/_\__ \ | | | - https://github.com/cherrynoize
#  \____|_|\___/|_| |_|\___(_)___/_| |_| - cherry-noize
#
# Helps configure jobs and tasks for backing up or syncing files
# and directories with rsync

#
# Options
#

# Path to clone dir
clone_dir="$HOME/.clone"

# Path to jobs dir
jobs_dir="$clone_dir/jobs"

# Path to config file
config_file="$clone_dir/config.sh"

# Program name
PROGRAM_NAME="clone"

# Version number
VERSION="0.00.2"

# Colorschemes
RED='\033[1;31m'
GREEN='\033[1;32m'
ORANGE='\033[1;33m'
PURPLE='\033[3;35m'
BLUE='\033[1;36m'
YELLOW='\033[1;37m'
NC='\033[0m' # No color

# Program colors
color_alert=$RED
color_title=$YELLOW
color_subtitle=$ORANGE
color_hint=$PURPLE
color_task=$BLUE
color_active=$YELLOW
color_normal=$NC

# List entry prefix 
list_prefix="->"

# Right arrow
arrow="->"

# Verbose output separator
#separator="============================\n"

#
# Initialization
#

# Initialize variables
positional_args=()

# Source config
. $config_file

# Set initial color 
printf "${color_normal}"

#
# Functions
#

# Print version number and quit
ver () {
  echo """
======================================
  ____ _                        _
 / ___| | ___  _ __   ___   ___| |__
| |   | |/ _ \| '_ \ / _ \ / __| '_ \\
| |___| | (_) | | | |  __/_\__ \ | | |
 \____|_|\___/|_| |_|\___(_)___/_| |_|
======================================

===========================
Clone simple backup utility
Version $VERSION
© 2023 cherry-noize
===========================
   """
  exit 0
}

# Print help message and quit
print_help () {
  # Notes:
  # - sources after "-s" are a string of comma or
  #   whitespace separated source paths
  echo Sorry, the help message is not ready yet.
  exit 0
}

# Print error and set exit status
put_err () {
  printf "${color_alert}error: %s${color_normal}\n" "$1"
  return 1
}

# Print check error and set status
check_err () {
  echo
  put_err "(running check) files differ: $1"
  return $?
}

# Print diff between files in group $1 and files in $2
check_diff () {
  # For each file in group $1
  for f in $1; do
    # Skip if file doesn't exist
    # (Avoids problems when no files are matched)
    if [[ ! -e "$f" ]]; then continue; fi

    # Fetch basename
    name="$(basename -- '$f')"

    # Destination path
    ldest="$2/$name"

    # Check differences between $f and $2
    if [ -n "$verbose" ]; then
      printf "checking for lines unique to %s...\n\n" "$f"
    fi

    # Find lines unique to $f
    if [ "$verbose" -gt "1" ]; then
      # Show lines unique to $f 
      comm -23 "$f" "$ldest" 2>/dev/null || check_err "$f->$ldest"
    else
      # Only show error message
      comm "$f" "$ldest" > /dev/null 2>&1 || check_err "$f->$ldest"
    fi
  done
}

# Check $1->$2
do_check () {
  # Opening separator
  printf "\n$SEP"

  # Print running checks message
  printf "${color_active}running checks...${color_normal}"

  # Print checkrun notice
  if [ -n "$check_run" ]; then
    printf " (CHECKRUN)"
  fi

  # Closing separator
  printf "\n$SEP"

  # Expected full output path
  _src="$1"
  _name="$(basename -- "$_src")"
  _out="$2/$_name"

  # If not in no checks mode
  if [ -z "$nochecks" ]; then
    # Run lightweight checks
    if [[ -e $_out ]]; then # Destination exists
      if [ -n "$verbose" ]; then
        # Found it
        printf "${color_active}-> $_out found${color_normal}\n"
      fi

      # If not in lightweight mode
      if [ -z "$lightweight" ]; then # Run full check
        # Check the type of src
        if [[ -d $_src ]]; then # is directory
          if [ -n "$verbose" ]; then
            # Print differences
            diff --no-dereference -r -q $_src/ $_out/ || check_err "$_src$arrow$_out"
          else
            # Only print error msg if finds any difference
            diff --no-dereference -r -q $_src/ $_out/ > /dev/null || check_err "$_src$arryw$_out"
          fi
        elif [[ -f $_src ]]; then # is file
          cmp --silent $_src $_out || check_err "$_out"
        else # is none of that
          put_err "could not access src: $_src"
          echo "(found not a directory and not a file)"
          return 1
        fi
      fi
    else # Destination not found
      put_err "could not find dest: $_out"
      return 1
    fi
  fi
}

# Sync $1->$2
do_sync () { 
  # Prepare for cloning
  printf "$SEP${color_title}cloning (%s)${color_normal}\n$SEP\n" "$1"
  if [ -n "$verbose" ]; then
    echo verifying path to destination...
  fi

  # Check if dir exists (or is file).
  # Create it otherwise
  if [[ -d $2 ]]; then # Dir exists
    if [ -n "$verbose" ]; then
      printf "%s: dir already exists\n\n" "$2"
      printf "${color_hint}skipping mkdir${color_normal}\n\n"
    fi
  elif [[ -f $2 ]]; then # Is file
    if [ -n "$verbose" ]; then
      printf "%s: file already exists\n\n" "$2"
    fi
  elif [[ -e $2 ]]; then # Exists but unrecognized
    put_err "$2: unrecognized type (not file or directory)\n"
  else # Dir not found
    if [ -n "$verbose" ]; then
      printf "%s: could not find dir\n\n" "$2"
      printf "${color_hint}running: mkdir -p %s${color_normal}\n\n" "$2"
    fi

    # If not in dry run
    if [ -z "$dry_run" ]; then
      # Try to create path to destination
      mkdir -p "$2" 2>/dev/null || put_err "mkdir: could not create directory"
    fi
  fi

  # Start syncing
  printf "$SEP${color_title}syncing (%s$arrow%s)${color_normal}\n$SEP" "$1" "$2"

  # Do the actual copying
  if [ -n "$verbose" ]; then
    # Copy each source to destination
    rsync -aP $options "$1" "$2"
  else
    # Quiet mode
    rsync -aP $options "$1" "$2" > /dev/null
  fi

  # If not in dry run or if in check run
  if [ -z "$dry_run" ] || [ -n "$check_run" ]; then
    # Run check
    do_check "$1" "$2"
    [[ $? -gt 0 ]] && { put_err "traceback: failed while running check on $1->$2\n"; exit $?; }
    [[ -n verbose ]] && printf "\nall tests passed\n"
  fi
}

#
# Params
#

# Parse command arguments
while [[ $# -gt 0 ]]; do
  # Shift makes you parse next argument as $1.
  # Shift n makes you move n arguments ahead.
  case $1 in
    -s|--src)
      # Source files to copy to destination
      IFS=', ' read -r -a sources <<< "$2"
      shift 2
      ;;
    -d|--dest)
      # Unique destination path
      IFS=', ' read -r -a destination <<< "$2"
      shift 2
      ;;
    -f|--config)
      # Replace default config file 
      IFS=', ' read -r -a config_file <<< "$2"
      shift 2
      ;;
    -i|--ignore-existing)
      # Ignore files that already exist in the destination
      options+=' --ignore-existing'
      shift
      ;;
    -D|--delete)
      # Delete files that were deleted in source
      options+=' --delete'
      shift
      ;;
    -u|--update)
      # Skip files that are newer on the receiver
      options+=' -u'
      shift
      ;;
    -c|--nochecks)
      # Skip check entirely
      nochecks=1
      shift
      ;;
    -l|--lightweight)
      # Perform lighter checks
      lightweight=1
      shift
      ;;
    -C|--check-run)
      # Dry run with checks
      check_run=1
      dry_run=1
      options+=' -n'
      shift
      ;;
    -n|--dry-run)
      # Perform a trial run with no changes applied
      dry_run=1
      options+=' -n'
      shift
      ;;
    -y|--no-prompt)
      # Do not prompt for verification 
      # (overridden by -I|--interactive)
      noprompt=1
      shift
      ;;
    -I|--interactive)
      # Prompt user for actions
      # (overrides -y|--no-prompt)
      interactive=1
      shift
      ;;
    -v|--verbose)
      # Print more stuff
      let verbose++
      options+=' -v'
      shift
      ;;
    -V|--logorrheic)
      # Print even more stuff
      let verbose++
      options+=' -vv'
      shift
      ;;
    -ver|--version)
      # Print version number
      ver
      shift
      ;;
    -h|--help)
      # Print help
      print_help
      shift
      ;;
    -*|--*)
      echo "$PROGRAM_NAME: unknown option $1"
      exit 1
      ;;
    *)
      positional_args+=("$1") # Save positional arg
      shift
      ;;
  esac
done

# Restore positional arguments
set -- "${positional_args[@]}"

# Parse free arguments
if [[ -n $1 ]]; then
  # Remove trailing slashes
  shopt -s extglob
  # Remove any amount of trailing slashes from dest
  dest="${1%%+(/)}"
else
  # Set working directory as destination
  dest="$PWD"
fi

#
# Startup
#

if [ -n "$verbose" ]; then
  SEP=$separator
fi

# Print launch message
printf "\n$SEP${color_title}starting $PROGRAM_NAME...${color_normal}\n$SEP\n"

# Print a message if in dry run
if [ -n "$dry_run" ]; then
  printf "${color_active}(running dry run -- no changes will be applied)${color_normal}\n\n"
fi

#
# Confirmation prompt
#

# Loop on unrecognized keys
while true; do
  # List entries found
  if [ -n "$verbose" ] || [ -n "$interactive" ] || [ -z "$noprompt" ]; then
    # If source parameter is defined
    if [ -n "$sources" ]; then
      # If destination parameter was not set
      if [ -z "$destination" ]; then
        put_err "expecting --dest when using --src parameter but found nothing\n"
        exit $?
      else
        # List param defined sources
        for src in ${sources[@]}; do
          printf "${color_task}$list_prefix FOUND source: %s${color_normal}\n" "$src"
        done
        printf "${color_subtitle}$list_prefix destination: %s${color_normal}\n" "$destination"
      fi
    else
      if [ -n "$sync_map" ]; then
        # Print config defined sync map
        for src in "${!sync_map[@]}"; do
          printf "${color_task}$list_prefix FOUND mapping: %s$arrow%s${color_normal}\n" "$src" "${sync_map[$src]}"
        done
      else
        put_err "sync map not found\n"
        exit $?
      fi
    fi
    # Print newline
    echo
  fi

  # Prompt user for confirmation
  if [ -n "$interactive" ] || [ -z "$noprompt" ]; then
    read -n 1 -p "Are you sure you want to proceed? (y/N) " input
    echo
    case $input in
      [Yy]* ) echo; break;;
      [Nn]* ) exit;;
      "" ) exit;;
      * ) printf "\n${color_alert}unrecognized option: %s${color_normal}\n\n" "$input";;
    esac
  else
    break;
  fi
done

# Suppress prompt hint
if [ -n "$verbose" ] && [ -z "$noprompt" ]; then
  printf "${color_hint}(you can omit this prompt by passing \`-y\` or \`--noprompt\`)${color_normal}\n\n"
fi

#
# Sync
#

# Run sync for either sources or maps
if [ -n $sources ]; then
  # For each source entry found
  for src in ${sources[@]}; do
    # Sync $src->$dest
    do_sync "$src" "$destination"
  done
else
  # For each map key found
  for src in "${!sync_map[@]}"; do
    # Sync $src->$dest
    do_sync "$src" "${sync_map[$src]}"
  done
fi

#
# Done
#

# All over
[ "$?" -eq "0" ] && printf "done.\n\n"

#####################################
# TODO
# - re-enable checks
# - add support for incremental backups
# - add support for remote backups
