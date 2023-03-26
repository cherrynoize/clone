#!/bin/bash
#   ____ _                        _
#  / ___| | ___  _ __   ___   ___| |__
# | |   | |/ _ \| '_ \ / _ \ / __| '_ \  - Clone simple backup utility
# | |___| | (_) | | | |  __/_\__ \ | | | - https://github.com/cherrynoize
#  \____|_|\___/|_| |_|\___(_)___/_| |_| - cherry-noize
#
# Helps configure jobs and tasks for backing up or syncing files
# and directories with rsync

# Path to config file
config_file="$HOME/.clone/config.sh"

# Default list of sources for backup 
sources=("/home" "/etc")

# Path to file with sources
source_file="$HOME/.clone/sources.conf"

# Version number
VERSION="0.00.1"

# Colorschemes
RED='\033[0;31m'
GREEN='\033[0;32m'
BLUE='\033[0;36m'
PURPLE='\033[0;35m'
YELLOW='\033[0;37m'
NC='\033[0m' # No color

# Program colors
color_alert=$RED
color_title=$YELLOW
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

# Initialize variables
options=
positional_args=()

# Source config
. $config_file

# Set initial color 
printf "${color_normal}"

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
  # - sources in source_file are newline separated
  echo Sorry, the help message is not ready yet.
  exit 0
}

# Print error running check and set exit status
check_err () {
  printf "${color_alert}error running check: files differ: %s${color_normal}\n\n" "$1"
  return 1
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

# Run integrity checks 
runchecks () {
  # Opening separator
  printf "\n$SEP"

  if [ -n "$verbose" ]; then
    # Print checkrun notice
    if [ -n "$check_run" ]; then
      printf "CHECKRUN SPECIFIED (-C|--check-run)\n"
    fi
  fi

  # Print running checks message
  printf "${color_active}running checks...${color_normal}\n$SEP"

  # Check that each source is now found in dest
  for src in ${sources[@]}; do
    name="$(basename -- '$src')"
    out="$dest/$name"

    # If not in no checks mode
    if [ -z "$nochecks" ]; then
      # Run lightweight checks
      if [[ -f $out ]]; then # Destination exists
        if [ -n "$verbose" ]; then
          # Found it
          printf "${color_active}-> $out found${color_normal}\n"
        fi

        # If not in lightweight mode
        if [ -z "$lightweight" ]; then # Run full check
          # Check the type of src
          if [[ -d $src ]]; then # is directory
            if [ -n "$verbose" ]; then
              # Print differences
              diff -r -q $src/ $out/ || check_err "$out"
            else
              # Only print error msg if finds any difference
              diff -r -q $src/ $out/ > /dev/null || check_err "$out"
            fi
          elif [[ -f $src ]]; then # is file
            cmp --silent $src $out || check_err "$out"
          else # is none of that
            printf "${color_alert}error: could not access src: %s${color_normal}\n\n" "$src"
            echo "(found not a directory and not a file)"
            return 1
          fi
        fi
      else # Destination not found
        printf "${color_alert}error: could not find dest: %s${color_normal}\n\n" "$out"
        return 1
      fi
    fi
  done
}

# Parse exact-match command arguments
while [[ $# -gt 0 ]]; do
  # Shift makes you parse next argument as $1.
  # Shift n makes you move n arguments ahead.
  case $1 in
    -s|--sources)
      # Source files to copy to destination
      source_override=1
      noprompt=1
      IFS=', ' read -r -a sources <<< "$2"
      shift 2
      ;;
    -f|--source-file)
      # File with sources to copy to destination
      noprompt=1
      IFS=', ' read -r -a source_file <<< "$2"
      shift 2
      ;;
    -i|--ignore-existing)
      # Ignore files that already exist in the destination
      options+=' --ignore-existing'
      shift
      ;;
    -d|--delete)
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
      echo "Unknown option $1"
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

if [ -n "$verbose" ]; then
  SEP=$separator
fi

# Print launch message
printf "$SEP${color_title}starting clone...${color_normal}\n$SEP\n"

# Print a message if in dry run
if [ -n "$dry_run" ]; then
  printf "${color_active}(running dry run -- no changes will be applied)${color_normal}\n\n"
fi

# If source_file is set and file exists and --sources
# parameter is not set.
if [ -n "$source_file" ] && [[ -f "$source_file" ]] && [ -z "$source_override" ]; then
  # Reinitialize sources
  sources=
  # Read sources from file
  i=0
  if [ -n "$verbose" ]; then
    echo $source_file: fetching sources...
  fi
  while IFS= read -r source; do
    # Ignore lines that start with a #
    [[ $source =~ ^#.* ]] && continue

    # Add line entries to sources
    sources[i]="$source"
    let i++
  done < $source_file
fi

while true; do
  # List entries found
  if [ -n "$verbose" ] || [ -n "$interactive" ] || [ -z "$noprompt" ]; then
    for src in ${sources[@]}; do
      printf "${color_task}$list_prefix FOUND entry: %s${color_normal}\n" "$src"
    done
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

if [ -n "$verbose" ] && [ -z "$noprompt" ]; then
  printf "\n${color_hint}(you can omit this prompt by passing \`-y\` or \`--noprompt\`)${color_normal}\n\n"
fi

# For each source entry found
for src in ${sources[@]}; do
  printf "$SEP${color_title}cloning (%s)${color_normal}\n$SEP\n" "$src"
  if [ -n "$verbose" ]; then
    echo checking path to destination...
    printf "${color_hint}running mkdir -p for %s${color_normal}\n\n" "$dest"
  fi

  # If not in dry run
  if [ -z "$dry_run" ]; then
    # Create path to destination if it doesn't exist
    mkdir -p "$dest" 2>/dev/null
  fi

  printf "$SEP${color_title}syncing (%s$arrow%s)${color_normal}\n$SEP" "$src" "$dest"

  # Do the copying
  if [ -n "$verbose" ]; then
    # Copy each source to the destination
    rsync -aP $options "$src" "$dest"
  else
    # Quiet mode
    rsync -aP $options "$src" "$dest" > /dev/null
  fi
done

# If not in dry run or if in check run
if [ -z "$dry_run" ] || [ -n "$check_run" ]; then
  runchecks
fi

# All over
[ "$?" -eq "0" ] && printf "done."

#####################################
# TODO
# - add support for remote backups
#
# - configure 2 tasks:
#  - backup (incremental backups in directory on hdd1__bak)
#  - sync (overwrite non-deleting copying location->destination) (i.e: metadisk)
