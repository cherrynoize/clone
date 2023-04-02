#!/usr/bin/env bash
#   ____ _                        _
#  / ___| | ___  _ __   ___   ___| |__
# | |   | |/ _ \| '_ \ / _ \ / __| '_ \  ~ Clone simple backup utility
# | |___| | (_) | | | |  __/_\__ \ | | | ~ https://github.com/cherrynoize
#  \____|_|\___/|_| |_|\___(_)___/_| |_| ~ cherry-noize
#
# Configure tasks and jobs for backing up and syncing

# Path to clone dir
clone_path="$HOME/.clone"

# Path to config file
config_file="./config_test.sh"

# Location for log files
log_file="${clone_path}/logs/clone.log"
err_file="${clone_path}/logs/clone_err.log"

# Extension for job files
JOB_FILE_EXT=".sh"

# Extension for log backup files
BAK_EXT=".bak"

# Min number of changes for incremental backup
min_changes=0

# Date format for writing incremental backups
# Date precision also defines min interval between incremental 
# backups (i.e: the least significant unit)
#date_fmt="+%Y-%m-%d_%H-%M-%S" # Try to update backup every second
date_fmt="+%Y-%m-%d" # Daily backup

# Version number
VERSION="0.00.4"

# Colorschemes
RED='\033[1;31m'
GREEN='\033[1;32m'
ORANGE='\033[1;33m'
PURPLE='\033[3;35m'
BLUE='\033[1;36m'
YELLOW='\033[1;37m'
NC='\033[0m' # No color
BG_PINK_I='\033[2;41m' # No color, italic

# Program colors
color_alert=$RED
color_warn=$PURPLE
color_title=$YELLOW
color_subtitle=$ORANGE
color_hint=$PURPLE
color_task=$BLUE
color_active=$YELLOW
color_normal=$NC
italic=$BG_PINK_I

# List entry prefix 
list_prefix="->"

# Right arrow
arrow="->"

# Verbose output separator
#separator="============================\n"

# Initialization
shopt -s extglob # Remove trailing slashes
shopt -s lastpipe # Last pipe runs in current shell
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
  printf "${color_warn}%b${color_normal}\n" "$1"
}

# Print error and set exit status
put_err () {
  printf "${color_alert}error: %b${color_normal}\n" "$1"
  return 1
}

# Print sync check error and set status
sync_err () {
  echo
  # Print error
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

  if [ -z "$lightweight" ]; then # Print heavy load msg
    printf " (this may take a while)"
  fi

  if [ -n "$check_run" ]; then # Print checkrun notice
    printf " (CHECK RUN)"
  fi

  # Closing separator
  printf "\n$SEP"

  # Expected full output path
  _src="$1"
  _name="$(basename -- "$_src")"
  _dest="$2/$_name"

  # Run lightweight checks
  if [[ -e $_dest ]]; then # Dest exists
    if [ -n "$verbose" ]; then
      # Found it
      printf "${color_active}${list_prefix} FOUND dest: $_dest${color_normal}\n"
    fi

    # If not lightweight mode
    if [ -z "$lightweight" ]; then # Run full check
      if [[ -e $_src ]]; then # Source exists
        if [ -n "$verbose" ]; then
          # Print differences
          did_sync || sync_err "$_src${arrow}$_dest"
        else
          # Only print error msg
          did_sync > /dev/null || sync_err "$_src$arryw$_dest"
        fi
      else # Src not found
        put_err "could not access src: $_src"
        echo "(not a directory or file)"
        return $?
      fi
    fi
  else # Dest not found
    put_err "could not find dest: $_dest"
    return $?
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
  printf "$SEP${color_title}syncing (%s${arrow}%s)${color_normal}\n$SEP" "$1" "$2"

  if [ -f "${log_file}" ] && [[ "$bak_file" -lt 2 ]]; then
    # Backup logs
    if [[ "$verbose" -gt "1" ]]; then
      printf "creating log backup: %1%2\n\n" "${log_file}" "${BAK_EXT}"
    fi
    cp "${log_file}" "${log_file}${BAK_EXT}"
  else
    log_dir="$(dirname -- "${log_file}")"

    if [ ! -e "$log_dir")" ]; then
      # Create path
      if [[ "$verbose" -gt "1" ]]; then
        printf "creating log dir: %1\n\n" "${log_dir}"
      fi
      mkdir -p "${log_dir}" 2>&1 > /dev/null
    fi
  fi
  
  # Do the actual copying
  if [ -n "$verbose" ]; then # Also write to stdout
    # Copy each source to destination
    rsync -aP $options "$1" "$2" > >(tee "${log_file}") 2> >(tee "${err_file}" >&2)
  else # Write to logs only
    # Quiet mode
    # Passes stdout only to pipe
    rsync -aP $options "$1" "$2" 2> >(tee "${err_file}" >&2) > /dev/null 
  fi

  # Save incremental backups
  if [ -n "$incremental" ]; then
    # Count changes
    changes=$(wc -l "${log_file}" | cut -d" " -f1)

    if [ -n "$verbose" ]; then
      put_warn "warning: using \`verbose\` flag with \`incremental\` mode\nnumber of min changes might not be respected"
    fi

    # If enough lines found in log 
    if [[ "$changes" -ge "$min_changes" ]]; then
      # Fetch date
      _date=$(date ${date_fmt})

      # If current date snapshot does not exist
      if [ ! -e "${2}_${_date}" ]; then
        # Make hardlinked copy for current date
        cp -al "$2" "${2}_${_date}"
        # Rename log files
        cp "${log_file}" "${log_file}_${_date}"
        if [ -f "${log_file}${BAK_EXT}" ] && [ -z "$bak_file" ]; then
          cp "${log_file}${BAK_EXT}" "${log_file}${BAK_EXT}_${_date}"
        fi
      fi
    fi
  fi

  # If checks option is set
  if [ -n "$checks" ]; then
    # Run checks
    do_check "$1" "$2"
    [[ $? -ne 0 ]] && {
      put_err "traceback: failed while running check on $1->$2\nwill exit now.\n";
      exit 5;
    }
    [[ -n verbose ]] && printf "\nall tests passed\n"
  fi
}

# Run a whole sync job 
exec_job () {
  # Confirm prompt
  while true; do # Loop on unrecognized input
    # List entries found
    if [ -n "$verbose" ] || [ -n "$interactive" ] || [ -z "$noprompt" ]; then
      if [ -n "$sources" ]; then # Use set parameters
        # List param defined sources
        for src in ${sources[@]}; do
          printf "${color_task}${list_prefix} FOUND source: %s${color_normal}\n" "$src"
        done
        printf "${color_subtitle}${list_prefix} destination: %s${color_normal}\n" "$destination"
      else # Use sync map
        # Print job sync map
        for src in "${!sync_map[@]}"; do
          printf "${color_task}${list_prefix} FOUND mapping: %s${arrow}%s${color_normal}\n" "$src" "${sync_map[$src]}"
        done
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
        * ) printf "\ninvalid option: \'%s\'\n\n" "$input";;
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
  if [ -n "$sources" ]; then # Run sync from sources to dest
    for src in ${sources[@]}; do # For each source entry found
      do_sync "$src" "$destination"
    done
  else # Run sync with maps
    for src in "${!sync_map[@]}"; do # For each map key found
      do_sync "$src" "${sync_map[$src]}"
    done
  fi

  # Print work done
  if [ -n "$verbose" ]; then
    echo
    if [ -n "$sources" ]; then
      # List param defined sources
      for src in ${sources[@]}; do
        printf "${color_task}${list_prefix} synced from: %s${color_normal}\n" "$src"
      done
      printf "${color_subtitle}${list_prefix} successfully synced to: %s${color_normal}\n" "$destination"
    else
      # Print config defined sync map
      for src in "${!sync_map[@]}"; do
        printf "${color_task}${list_prefix} successfully synced: %s${arrow}%s${color_normal}\n" "$src" "${sync_map[$src]}"
      done
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
  _longopts="src:,dest:,config:,list,all,incremental,ignore-existing,delete,update,checks,lightweight,check-run,dry-run,safe,no-prompt,interactive,progress,verbose,logorrheic,no-logs,bak:,background,version,help"
  _options="s:d:f:laIiDucLCnSyIpvNVh"

  # Parse command line arguments using getopt
  PARSED=$(getopt --options=$_options --longoptions=$_longopts --name "$0" -- "$@")
  if [[ $? -ne 0 ]]; then
    exit 1
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
    -l|--list)
      # List jobs
      list_jobs=1
      shift
      ;;
    -a|--all)
      # Run all jobs
      all_jobs=1
      shift
      ;;
    -I|--incremental)
      # Create incremental backups in dest
      incremental=1
      options+=' --delete -i'
      shift
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
    -c|--checks)
      # Run additional checks
      checks=1
      shift
      ;;
    -L|--lightweight)
      # Perform lighter checks
      lightweight=1
      checks=1
      shift
      ;;
    -C|--check-run)
      # Dry run with checks
      check_run=1
      checks=1
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
    -S|--safe)
      # Don't perform risky operations like sourcing or copying 
      safe_mode=1
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
    -p|--progress)
      # Show total progress
      options+=' --info=progress2'
      shift
      ;;
    -v|--verbose)
      # Print more stuff
      if [ -n "$verbose" ]; then
        options+=' -i'
      fi
      let verbose++
      options+=' -v'
      shift
      ;;
    --logorrheic)
      # Print even more stuff
      let verbose+=2
      options+=' -vv -i'
      shift
      ;;
    -N|--no-logs)
      # Flush logs
      log_file="/dev/null"
      shift
      ;;
    --bak)
      # Log file bak behaviour
      IFS=', ' read -r -a bak_file <<< "$2"
      shift 2
      ;;
    --background)
      # Don't burn resources
      run_in_background=1
      shift
      ;;
    -V|--version)
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
      echo "${0}: invalid option -- '${1}'"
      exit 1
      ;;
    *)
      positional_args+=("$1") # Save positional args
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

if [ -n "$run_in_background" ]; then
  # Run this process with real low priority
  ionice -c 3 -p $$
  renice +12  -p $$
fi

# Print config file location
if [ -e "$config_file" ]; then
  printf "config file found: %s\n" "$config_file"
  if [ -z "$safe_mode" ]; then
    . "$config_file" # Source file
  fi
else
  printf "config not found\n"
fi

if [ -n "$verbose" ]; then
  SEP=$separator
fi

# Print launch message
printf "${SEP}${color_title}starting ${0}...${color_normal}\n${SEP}"

# Print a message if in dry run
if [ -n "$dry_run" ]; then
  printf "${color_active}(running dry run -- no changes will be applied)${color_normal}\n"
fi

echo

if [ -n "$sources" ]; then # Source parameter set
  # Destination parameter not set
  if [ -z "$destination" ]; then
    put_err "expecting --dest when setting --src but found nothing\n"
    exit 3
  else
    # Run job using set parameters
    (exec_job)
  fi
elif [ -n "$all_jobs" ] || [ -n "$list_jobs" ] || [ -n "$safe_mode" ]; then
  if [ -z "$jobs_path" ]; then
    if [ -n "$safe_mode" ]; then
      put_err "in --safe mode you need to pass the jobs path variable manually:" 
      printf "${italic}%s${color_normal}\n" 'jobs_path="/path/to/clone/jobs clone [options] [jobs]"'
      exit 2
    else
      put_err "jobs path not defined"
      printf "try adding to your config file:\n"
      printf "${italic}%s${color_normal}\n" 'jobs_path="/path/to/clone/jobs"'
      exit 2
    fi
  elif [ ! -d "$jobs_path" ]; then
    put_err "${jobs_path} is not a directory"
    exit 4
  fi

  if [ -n "$list_jobs" ]; then
    printf "listing jobs inside %s\n\n" "$jobs_path"
  else
    printf "running all jobs found in: %s\n\n" "$jobs_path"
  fi

  # Store paths to job files into array
  find ${jobs_path} -type f -name "*${JOB_FILE_EXT}" -print0 | while IFS= read -r -d '' _job_file; do
      jobs_array[$i]="$_job_file"
      let i++
  done

  # Check if we found anything
  if [[ "${#jobs_array[@]}" -eq "0" ]]; then
    put_err "${jobs_path}: no job files found\n"
    exit 3
  fi

  for job_file in ${jobs_array[@]}; do
    # Make sure file exists
    if [ ! -e "$job_file" ]; then
      put_err "${job_file}: file not found\n"
      continue
    fi

    if [ -z "$safe_mode" ]; then
      # Source job
      # We fetch the new sync mappings
      . "$job_file"

      if [ "${#sync_map[@]}" -eq "0" ]; then
        put_err "${job_file}: sync map not found"
        printf "add a sync map to your job file\n"
        exit 2
      fi
    fi

    _filename="$(basename -- "$job_file")"
    job_name="${filename%.*}"

    # Print job found
    printf "${color_title}${list_prefix} FOUND job: %s (%s)${color_normal}\n" "$job_name" "$job_file"

    if [ -n "$list_jobs" ]; then
      if [ -z "$safe_mode" ]; then
        echo
        # Print sync map
        for src in "${!sync_map[@]}"; do
          printf "${color_task}${list_prefix} FOUND mapping: %s${arrow}%s${color_normal}\n" "$src" "${sync_map[$src]}"
        done
      fi
      echo
    else
      # Run jobs in subshell
      # This way we can configure local options in the job file 
      (exec_job)
    fi
  done
else
  if [ "$#" -eq "0" ]; then
    printf "no jobs specified.\n"
    exit 1
  fi

  # Iterate each free argument as job name 
  for job_name; do
    job_file="${jobs_path}/${job_name}${JOB_FILE_EXT}"

    # Source job
    # We fetch the new sync mappings
    . "$job_file" 2>/dev/null || {
      put_err "${job_file}: job file not found\n"
      continue
    }

    # Print job found
    printf "${color_title}${list_prefix} FOUND job: %s (%s)${color_normal}\n" "$job_name" "$job_file"

    # Run jobs in subshell
    # This way we can configure local options in the job file 
    (exec_job)
  done
fi

# All over
[ "$?" -eq "0" ] && printf "done.\n"

#####################################
# EXIT CODES
# - 0 OK
# - 1 command external (e.g: command syntax/arg format)
# - 2 command internal (e.g: bad configuration)
# - 3 file (e.g: file not found)
# - 4 path (e.g: dir not found)
#
# TODO
# - remove comma separator in sources param
# - add support for incremental backups
#  - fix min changes option
# - add support for remote backups
# - add md5sum option for checks (separate: + or - diff checks)
# - fix loop error with jobs_path="." 
# - add optional notification at the end of each exec_job 
