#!/usr/bin/env bash

do_tar_sync () {
  # Check if exclude file exists
  if [ ! -f $tar_exclude ]; then
    while true; do # Loop on unrecognized input
      echo "Exclude file not found"
      read -n 1 -p "Are you sure you want to proceed? (y/N) " input
      # y/N prompt
      continue_prompt && break
    done
  fi

  # -p, --acls and --xattrs store all permissions, ACLs and extended attributes. 
  # Without both of these, many programs will stop working!
  # It is safe to remove the verbose (-v) flag. If you are using a 
  # slow terminal, this can greatly speed up the backup process.
  # Use bsdtar because GNU tar will not preserve extended attributes.
  bsdtar --exclude-from="$tar_exclude" --acls --xattrs -cpvzf "$2" "$1"
}
