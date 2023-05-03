# Example backup job for clone.sh

# Src path
src="/usr"
# Dest path
dest="$clone_path/example"

# Sync maps
declare -A sync_map=(
  ["$src/local/bin"]="$dest/local"
  ["$src/share"]="$dest"
)
