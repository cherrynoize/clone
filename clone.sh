#!/bin/bash
#   ____ _                        _
#  / ___| | ___  _ __   ___   ___| |__
# | |   | |/ _ \| '_ \ / _ \ / __| '_ \  - Clone simple backup utility
# | |___| | (_) | | | |  __/_\__ \ | | | - https://github.com/cherrynoize
#  \____|_|\___/|_| |_|\___(_)___/_| |_| - cherry-noize
#
# Helps configure jobs and tasks for backing up or syncing files
# and directories with rsync

# Path to clone dir
clone_dir="$HOME/.clone"

# Path to jobs dir
jobs_dir="$clone_dir/jobs"

# Path to config file
config_file="./config_test.sh"

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

# Initialization
shopt -s extglob # Remove trailing slashes
positional_args=()
printf "${color_normal}" # Set initial color

# Here we define a lot of useful functions
# :(funcs)

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

# Print warning msg
put_warn () {
  printf "${color_hint}%b${color_normal}\n" "$1"
}

# Print error and set exit status
put_err () {
  printf "${color_alert}error: %b${color_normal}\n" "$1"
  return 1
}

# Print sync check error and set status
sync_err () {
  echo

  # Output error
  put_err "files differ in: $1\n"

  # Save status from put_err
  _status="$?"
 
  # Print diff grepped output
  printf "%s\n\n" "$diff_res"

  # Return put_err status
  return $_status
}

# Finds differences unique to src
did_sync () {
  diff_res=$(diff --no-dereference -r -q $_src $_dest | grep -v "^Only in $_dest")
  if [ -n "$diff_res" ]; then
    return 1
  fi
}

# Check $1->$2
do_check () {
  # Opening separator
  printf "\n$SEP"

  # Print running checks message
  printf "${color_active}running checks...${color_normal}"

  # Print checkrun notice
  if [ -n "$check_run" ]; then
    printf " (CHECK RUN)"
  fi

  # Closing separator
  printf "\n$SEP"

  # Expected full output path
  _src="$1"
  _name="$(basename -- "$_src")"
  _dest="$2/$_name"

  # If not in no checks mode
  if [ -z "$nochecks" ]; then
    # Run lightweight checks
    if [[ -e $_dest ]]; then # Dest exists
      if [ -n "$verbose" ]; then
        # Found it
        printf "${color_active}-> FOUND dest: $_dest${color_normal}\n"
      fi

      # If not lightweight mode
      if [ -z "$lightweight" ]; then # Run full check
        if [[ -e $_src ]]; then # Source exists
          if [ -n "$verbose" ]; then
            # Print differences
            did_sync || sync_err "$_src$arrow$_dest"
          else
            # Only print error msg
            did_sync > /dev/null || sync_err "$_src$arryw$_dest"
          fi
        else # Src not found
          put_err "could not access src: $_src"
          echo "(found not a directory and not a file)"
          return $?
        fi
      fi
    else # Dest not found
      put_err "could not find dest: $_dest"
      return $?
    fi
  fi
  return $?
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
    [[ $? -ne 0 ]] && { put_err "traceback: failed while running check on $1->$2\nwill exit now.\n"; exit $?; }
    [[ -n verbose ]] && printf "\nall tests passed\n"
  fi
}

# Run a whole sync job 
exec_job () {
  # Confirm prompt
  while true; do # Loop on unrecognized input
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
        if [ "${#sync_map[@]}" -gt 0 ]; then
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
    put_warn "(you can suppress this prompt by passing \`-y\` or \`--noprompt\`)\n"
  fi

  # Sync
  if [ -n "$sources" ]; then # Run sync with sources
    # For each source entry found
    for src in ${sources[@]}; do
      # Sync $src->$dest
      do_sync "$src" "$destination"
    done
  else # Run sync with maps
    # For each map key found
    for src in "${!sync_map[@]}"; do
      # Sync $src->$dest
      do_sync "$src" "${sync_map[$src]}"
    done
  fi

  # Print work done
  if [ -n "$verbose" ]; then
    echo
    if [ -n "$sources" ]; then
      # List param defined sources
      for src in ${sources[@]}; do
        printf "${color_task}$list_prefix synced from: %s${color_normal}\n" "$src"
      done
      printf "${color_subtitle}$list_prefix successfully synced to: %s${color_normal}\n" "$destination"
    else
      if [ "${#sync_map[@]}" -gt 0 ]; then
        # Print config defined sync map
        for src in "${!sync_map[@]}"; do
          printf "${color_task}$list_prefix successfully synced: %s$arrow%s${color_normal}\n" "$src" "${sync_map[$src]}"
        done
      else
        put_err "sync map no longer available\ndon't know why\n"
        exit $?
      fi
    fi
    echo
  fi
}

# Here we start handling command line arguments
# :(args)

# Getopt version
getopt --test > /dev/null 

# If returns 4 parse with getopt
if [[ $? -ne 4 ]]; then
  put_warn "warning: \`getopt --test\` did not return 4...\ndefaulting to std handling..."
else
  # Colon after option means additional arg
  _longopts=src:,dest:,dry-run,check-run,verbose
  _options=s:d:nCv

  # Parse command line arguments using getopt
  PARSED=$(getopt --options=$_options --longoptions=$_longopts --name "$0" -- "$@")
  if [[ $? -ne 0 ]]; then
    _options= # Reset sentinel variable 
    put_err "failed to parse with \`getopt\`...\ndefaulting to std handling..."
  else
    # Set getopt output
    eval set -- "$PARSED"
  fi
fi

# Parse command arguments
while [[ $# -gt 0 ]]; do
  # Shift makes you parse next argument as $1.
  # Shift n makes you move n arguments ahead.
  case $1 in
    -s|--src)
      # Remove any amount of trailing slashes
      _trimmed_s="${2%%+(/)}"
      # Source files to copy to destination
      IFS=', ' read -r -a sources <<< "$_trimmed_s"
      shift 2
      ;;
    -d|--dest)
      # Remove any amount of trailing slashes
      _trimmed_d="${2%%+(/)}"
      # Destination path
      IFS=', ' read -r -a destination <<< "$_trimmed_d"
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
    --)
      shift
      break
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

# If getopt wasn't used
if [ -z "$_options" ]; then
  # Restore positional arguments
  set -- "${positional_args[@]}"
fi

# Free arguments are now set as $@ 
# Can be accessed later on

# From here on we start program execution
# :(startup)

# Print config file location
if [ -e "$config_file" ]; then
  printf "\nconfig file found: %s\n" "$config_file"
  . $config_file # Source file
else
  printf "\nconfig not found\n"
fi

if [ -n "$verbose" ]; then
  SEP=$separator
fi

# Print launch message
printf "\n${SEP}${color_title}starting ${PROGRAM_NAME}...${color_normal}\n${SEP}\n"

# Print a message if in dry run
if [ -n "$dry_run" ]; then
  printf "${color_active}(running dry run -- no changes will be applied)${color_normal}\n\n"
fi

# Run jobs
exec_job

# All over
[ "$?" -eq "0" ] && printf "done.\n\n"

#####################################
# TODO
# - re-enable checks
# - add support for incremental backups
# - add support for remote backups
