# backup job for clone.sh
# =======================
#
# we synchronize all relevant folders into a sync directory inside
# the hostname backup path, deleting files that were also deleted
# from source and preserving hard link inodes.
#
# this is a useful duplicate of manually edited/user owned files
# that can be easily placed in a new system install to replicate
# the current setup. the backup partition should be formatted
# formatted accordingly so permissions are not lost. you can
# compensate with third-party applications such as etckeeper.
# consider maintaining a list of installed packages in one of these
# locations so you can use it to reinstall them with your package
# manager.
#

opts="-vp --delete"
rsync_opts="--hard-links"

# backup base dir
base_dir="/mnt/backup/$(hostname)-backup/sync"

# sync maps
declare -gA sync_map=(
  ["/usr/local"]="${base_dir}/usr"
  ["/usr/share/xsessions"]="${base_dir}/usr/share"
  ["/etc"]="${base_dir}"
  ["/root"]="${base_dir}"
  ["/home"]="${base_dir}"
)
