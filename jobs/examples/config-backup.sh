# Example backup job for clone.sh

# Dest path
dest="$clone_path/example"

# Sync maps
declare -A sync_map=(
  ["$HOME/.config/."]="$dest/config"
)
