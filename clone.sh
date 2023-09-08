#!/usr/bin/env bash
#
#   ____ _                        _
#  / ___| | ___  _ __   ___   ___| |__
# | |   | |/ _ \| '_ \ / _ \ / __| '_ \  ~ Clone backup automation utility
# | |___| | (_) | | | |  __/_\__ \ | | | ~ https://github.com/cherrynoize
#  \____|_|\___/|_| |_|\___(_)___/_| |_| ~ cherry-noize
#
#
# Configure automated jobs for backing up and syncing files
#

# Fetch install dir
install_dir="$(dirname $(readlink -f $0))"

# Path to clone dir
clone_path="${HOME}/.clone"

# Override with env default
if [ -n "$CLONE_PATH" ]; then
  clone_path="$CLONE_PATH"
fi

# Jobs dir
jobs_path="${clone_path}/jobs"

#
# Set the path to your config file
#

# Path to config file
config_file="${clone_path}/config.sh"

#
# You should override all following values from your config file
#

# Path to tar module
tar_module="${install_dir}/tar.sh"

# Location for log files
log_path="/var/log/clone"
log_file="${log_path}/clone.log"
stdout_file="${log_path}/stdout.log"
err_file="${log_path}/err.log"

# Job file extension
JOB_FILE_EXT=".sh"

# Log file extension
LOG_FILE_EXT=".log"

# Default number of digits for varying index
DEFAULT_INDEX_LEN="2"

# Default starting index
start_index=0

# Date format for writing incremental backups
# Date precision also defines min interval between incremental 
# backups (i.e: the least significant unit)
#date_fmt="+%Y-%m-%d_%H-%M-%S" # Try to update backup every second
date_fmt="+%Y-%m-%d" # Daily backup

# Version number
VERSION="0.00.6"

# Colorschemes
RED='\033[1;31m'
#GREEN='\033[1;32m'
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

list_prefix="->"
arrow="->"
sep="========================\n"

# Initialization
shopt -s extglob # Remove trailing slashes
shopt -s lastpipe # Last pipe runs in current shell
printf "$color_normal" # Set initial color

# Set active log and err file for writing
active_log_file="$log_file"
active_stdout_file="$stdout_file"
active_err_file="$err_file"
  
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
  echo """Usage:
  clone [OPTIONS] [-s SOURCE -d DEST | [-d DEST] JOBS]

Options:
  Mandatory arguments to long options are mandatory for short options too.

  -s|--src SOURCE
    Copy list of whitespace/comma separated files to destination

  -d|--dest DESTINATION
    Set DESTINATION as destination path

  -f|--config CONFIG
    Replace default config file with CONFIG

  -l|--list
    List available jobs

  -a|--all
    Run all jobs

  -I|--incremental
    Create incremental backups in destination

  -i|--ignore-existing
    Ignore files that already exist in destination

  -D|--delete
    Delete from destination files that were also deleted in source

  -u|--update
    Skip files that are newer on the receiver

  -c|--checks
    Run additional checks (experimental)

  -L|--lightweight
    Perform lighter (faster) checks

  -C|--check-run
    Dry run with checks

  -n|--dry-run
    Perform a trial run with no changes applied

  -S|--safe
    Don't perform risky operations like sourcing or copying

  -X|--pass ARGS
    Pass ARGS verbatim as string of parameters to copying command
    (e.g: rsync, tar, ...)

  -t|--tar
    Use tar for copying instead of the default command (rsync)

  -y|--no-prompt 
    Do not prompt for verification before execution

  -P|--interactive
    Prompt user for confirmation before actions

  -H|--human
    Human readable format

  -p|--progress
    Display overall progress

  -v|--verbose
    Print more stuff

  --logorrheic
    Print even more stuff

  -N|--no-logs
    Flush logs

  --background
    If possible run with minimum resources

  -V|--version
    Print version number and exit

  -h|--help 
    Print this help message

Exit codes:
  0 OK
  1 command external (e.g: command syntax/arg format)
  2 command internal (e.g: bad configuration)
  3 file (e.g: file not found)
  4 path (e.g: dir not found)

Examples:
  clone -s . -d /mnt --tar
   backup current directory into /mnt as a tar archive
  clone sync inc
   run \`sync\` job, then \`inc\` job
  clone --list
   print jobs list and exit
  clone -a
   run all jobs found"""

  exit 0
}

parse_args () {
  if [ -z "$use_getopt" ]; then
    put_warn "warning: \`getopt --test\` did not return 4...\ndefaulting to std handling..."
  else
    # Colon after option means additional arg
    _longopts="src:,dest:,config:,list,all,incremental,ignore-existing,delete,update,checks,lightweight,check-run,dry-run,safe,pass:,use-tar,no-prompt,interactive,human,progress,verbose,logorrheic,no-logs,background,version,help"
    _options="s:d:f:laIiDucLCnSX:tyPHpvNVh"

    # Parse command line arguments using getopt
    _GETOPT_PARSED=$(getopt --options=$_options --longoptions=$_longopts --name "$0" -- $@)
    if [[ $? -ne 0 ]]; then
      exit 1
    else
      # Set getopt output
      eval set -- "$_GETOPT_PARSED"
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
        options+=' --itemize-changes'
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
      -X|--pass)
        # Pass next argument as string of params in cmd 
        IFS=', ' read -r -a pass_args <<< "$2"
        shift 2
        ;;
      -t|--tar)
        # Use tar
        use_tar=1
        shift
        ;;
      -y|--no-prompt)
        # Do not prompt for verification 
        # (overridden by -I|--interactive)
        noprompt=1
        shift
        ;;
      -P|--interactive)
        # Prompt user for actions
        # (overrides -y|--no-prompt)
        interactive=1
        shift
        ;;
      -H|--human)
        # Human readable
        options+=' -h'
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
      --background)
        # Don't burn resources
        run_in_background=1
        shift
        ;;
      -V|--version)
        # Print version number and exit
        ver
        ;;
      -h|--help)
        # Print help and exit
        print_help
        ;;
      --)
        shift
        break
        ;;
      -*)
        echo "${0}: invalid option -- '${1}'"
        exit 1
        ;;
      *)
        positional_args+=("$1") # Save positional args
        shift
        ;;
    esac
  done

  # Put remaining arguments into an array
  parsed=( "${@}" )
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

# y/N prompt
continue_prompt () {
  case $input in
    [Yy]* ) echo; return;;
    [Nn]* ) exit;;
    "" ) exit;;
    * ) printf "\ninvalid option: \'%s\'\n\n" "$input";;
  esac
  return 1
}

# Finds differences unique to src
did_sync () {
  diff_res=$(diff --no-dereference -r -q "$_src" "$_dest" | grep -v "^Only in ${_dest}")
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
          did_sync > /dev/null || sync_err "$_src$arrow$_dest"
        fi
      else # Src not found
        put_err "could not access src: $_src (not a file/directory)\n"
        return $?
      fi
    fi
  else # Dest not found
    put_err "could not find dest: $_dest"
    return $?
  fi
  return $?
}

# Source file and parse options
parse_file () { 
  echo "sourcing $1 file $2"
  # Source file
  . "$2" 2>/dev/null || {
    put_err "${2}: ${1} file not found\n"
    return 1
  }

  # Append file options to args
  parse_args "${opts[@]}"
  # Add any free arguments to list
  free_args+=( "${parsed[@]}" )
}

# Sync $1->$2
do_sync () { 
  # Prepare for cloning
  printf "$SEP${color_title}cloning (%s)${color_normal}\n$SEP\n" "$1"
  if [ -n "$verbose" ]; then
    echo verifying path to destination...
  fi

  _dest="$2"

  # Incremental backups format
  if [ -n "$incremental" ]; then
    # Fetch dest dir
    _dest_dir="${_dest}"
    if [ ! -d "${_dest}" ]; then
      _dest_dir="$(dirname -- "${_dest}")"
    fi
    # Full path to last modified element in dest dir
    link_dest="${_dest_dir}/$(ls -t "${_dest_dir}" 2>/dev/null | head -n 1)"
    # Use last dest as link base
    if [ -n "$link_dest" ]; then
      options+=" --link-dest ${link_dest}"
    fi

    # Update with new log and err file for writing
    log_base="${log_file%.*}"
    active_log_file="${log_base}_${_date}${LOG_FILE_EXT}"
    err_base="${err_file%.*}"
    active_err_file="${err_base}_${_date}${LOG_FILE_EXT}"
  fi

  # Check if dir exists (or is file).
  # Create it otherwise
  if [[ -d "${_dest}" ]]; then # Dir exists
    if [ -n "$verbose" ]; then
      printf "%s: dir already exists\n\n" "${_dest}"
      printf "${color_hint}skipping mkdir${color_normal}\n\n"
    fi
  elif [[ -f "${_dest}" ]]; then # Is file
    if [ -n "$verbose" ]; then
      printf "%s: file already exists\n\n" "${_dest}"
    fi
  elif [[ -e "${_dest}" ]]; then # Exists but unrecognized
    put_err "${_dest}: unrecognized type (not file or directory)\n"
  else # Dir not found
    if [ -n "$verbose" ]; then
      printf "%s: could not find dir\n\n" "${_dest}"
      printf "${color_hint}running: mkdir -p %s${color_normal}\n\n" "${_dest}"
    fi

    # If not in dry run
    if [ -z "$dry_run" ]; then
      # Try to create path to destination
      mkdir -p "${_dest}" 2>/dev/null || put_err "mkdir: could not create directory"
    fi
  fi

  # Start syncing
  printf "$SEP${color_title}syncing (%s${arrow}%s)${color_normal}\n$SEP\n" "$1" "${_dest}"

  # Create logs dir
  if [ -f "${log_file}" ]; then
    log_dir="$(dirname -- "${log_file}")"
    if [ ! -e "$log_dir" ]; then
      if [[ "$verbose" -gt "1" ]]; then
        printf "creating log dir: %1\n\n" "${log_dir}"
      fi
      mkdir -p "${log_dir}" > /dev/null 2>&1
    fi
  fi

  # Write opening separator to log file
  echo "$sep" >> "${active_log_file}"

  # Start backup
  echo "Starting backup on $(date +"%Y-%m-%d %H:%M:%S")" >> "${active_log_file}"

  # Do the actual copying
  if [ -z "$use_tar" ]; then # use rsync
    if [ -n "$verbose" ]; then
      # Write to both logs and stdout
      rsync --exclude-from="${clone_path}/exclude-file.txt" -aP $options $rsync_opts $pass_args "$1" "$_dest" > >(tee "${active_stdout_file}" -a) 2> >(tee "${active_err_file}" -a >&2)
    else # Quiet mode
      # Write to logs only and not stdout
      rsync --exclude-from="${clone_path}/exclude-file.txt" -aP $options $rsync_opts $pass_args "$1" "$_dest" 2> >(tee "${active_err_file}" -a >&2) >> ${active_stdout_file}
    fi

    # If checks option is set
    if [ -n "$checks" ]; then
      # Run checks
      do_check "$1" "${_dest}" || {
        put_err "traceback: failed while running check on $1->${_dest}\nwill exit now.\n";
        exit 5;
      }
      [[ -n "$verbose" ]] && printf "\nall tests passed\n"
    fi
  else # use tar
    # shellcheck source=tar.sh
    . "$tar_module"
    do_tar_sync --exclude-from="${clone_path}/exclude-file.txt" $options $tar_opts $pass_args "$1" "${_dest}"
  fi

  # Save completed backup timestamp to log file
  echo "Backup completed on $(date +"%Y-%m-%d %H:%M:%S")" >> "${active_log_file}"
}

# Run a whole sync job 
exec_job () {
  # Confirm prompt
  while true; do # Loop on unrecognized input
    # List entries found
    if [ -n "$verbose" ] || [ -n "$interactive" ] || [ -z "$noprompt" ]; then
      if [ -n "$sources" ]; then # Use set parameters
        # List param defined sources
        for src in "${sources[@]}"; do
          printf "${color_task}${list_prefix} FOUND source: %s${color_normal}\n" "$src"
        done
        printf "${color_subtitle}${list_prefix} destination: %s${color_normal}\n" "$destination"
      else # Use sync map
        # Print job sync map
        for src in "${!sync_map[@]}"; do
          printf "${color_task}${list_prefix} FOUND mapping: %s${arrow}%s${color_normal}\n" "$src" "${sync_map[$src]}"
        done
      fi
      echo
    fi

    # Prompt user for confirmation
    if [ -n "$interactive" ] || [ -z "$noprompt" ]; then
      read -n 1 -p "Are you sure you want to proceed? (y/N) " input
      echo
      # y/N prompt
      continue_prompt && break
    else
      break;
    fi
  done

  # Suppress prompt hint
  if [ -n "$verbose" ] && [ -z "$noprompt" ]; then
    put_warn "(you can suppress this prompt by passing \`-y\` or \`--noprompt\`)\n"
  fi

  # If running incremental backup and we're not in dry run
  if [ -n "$incremental" ] && [ -z "$dry_run" ]; then
    # Fetch date
    _date="$(date "${date_fmt}")"

    # Add date to base dir
    base_dir="${base_dir}_${_date}"

    # Create dir
    mkdir -p "${base_dir}" 2>/dev/null || put_err "mkdir: could not create directory"
  fi

  # Sync
  if [ -n "$sources" ]; then # Run sync from sources to dest
    for src in "${sources[@]}"; do # For each source entry found
      do_sync "$src" "$destination"
    done
  else # Run sync with maps
    # Set fallback number of digits for index
    if [ -z "$index_len" ]; then
      index_len="${DEFAULT_INDEX_LEN}"
    fi

    for src in "${!sync_map[@]}"; do # For each map key found
      (( _index+="$start_index" ))

      while true; do
        # Pad with zeroes
        _index_str="$(printf "%0${index_len}d" $_index)"

        # Fetch dest using index 
        dst_res="${sync_map[$src]//\$/${_index_str}}" # Replace dollar sign with index

        # Dest unchanged means no dollar sign found
        if [ "$dst_res" == "${sync_map[$src]}" ]; then
          # Skip index bumping
          break
        fi

        # Check if dest exists
        if [ ! -e "$dst_res" ]; then
          break
        elif [[ "$verbose" -gt "1" ]]; then
          echo "${dst_res} already exists"
        fi

        # Try next index
        (( _index++ ))
      done

      do_sync "$src" "$dst_res"
    done
  fi

  # Print work done
  if [ -n "$verbose" ]; then
    echo
    if [ -n "$sources" ]; then
      # List param defined sources
      for src in "${sources[@]}"; do
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

main () {
  # Getopt version
  getopt --test > /dev/null 
  # If getopt exits with 4 parse with getopt
  [[ $? -eq 4 ]] && use_getopt=1

  # Parse command line arguments
  parse_args "$@"
  # Set free args
  free_args=( "${parsed[@]}" )

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
      # Source config file
      parse_file config "$config_file"
    fi
  else
    printf "config file not found\n"
  fi

  if [ -n "$verbose" ]; then
    SEP=$sep
  fi

  # Print launch message
  printf "${SEP}${color_title}starting $(basename -- ${0})...${color_normal}\n${SEP}"

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
    find "${jobs_path}" -type f -name "*${JOB_FILE_EXT}" -print0 | while IFS= read -r -d '' _job_file; do
        jobs_array[i]="$_job_file"
        (( i++ ))
    done

    # Check if we found anything
    if [[ "${#jobs_array[@]}" -eq "0" ]]; then
      put_err "${jobs_path}: no job files found\n"
      exit 3
    fi

    for job_file in "${jobs_array[@]}"; do
      if [ -z "$safe_mode" ]; then
        # Source job file
        parse_file job "$job_file"

        # If sync map is empty
        if [ "${#sync_map[@]}" -eq "0" ]; then
          put_err "${job_file}: sync map not found"
          printf "add a sync map to your job file\n"
          exit 2
        fi
      fi

      _filename="$(basename -- "$job_file")"
      job_name="${_filename%.*}"

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
    for job_name in "${free_args[@]}"; do
      # Skip empty job names
      if [ -z "$job_name" ]; then
        continue
      fi

      # Source job file
      job_file="${jobs_path}/${job_name}${JOB_FILE_EXT}"
      parse_file job "$job_file"

      # Print job found
      printf "${color_title}${list_prefix} FOUND job: %s (%s)${color_normal}\n" "$job_name" "$job_file"

      # Run jobs in subshell
      # This way we can configure local options in the job file 
      (exec_job)
    done
  fi
}

# All over
if main "$@"; then # If exiting with 0
  # Write closing separator to log file
  echo "$sep" >> "${active_log_file}"
  printf "done.\n"
fi
