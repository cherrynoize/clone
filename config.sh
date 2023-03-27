#   ____ _                        _
#  / ___| | ___  _ __   ___   ___| |__
# | |   | |/ _ \| '_ \ / _ \ / __| '_ \  - Clone simple backup utility
# | |___| | (_) | | | |  __/_\__ \ | | | - https://github.com/cherrynoize
#  \____|_|\___/|_| |_|\___(_)___/_| |_| - cherry-noize
#
# Config file for clone.sh

# Sync mappings
# (each ["key"] will be copied in "VALUE")
declare -A sync_map=(
  ["$HOME/.config/."]="$SYNC/dotfiles/config"
  ["$HOME/.old"]="$SYNC/.old"
  ["$HOME/."]="$SYNC/.vimrc"
  ["$HOME/."]="$SYNC/."
  ["$HOME/."]="$SYNC/."
  ["$HOME/."]="$SYNC/."
  ["$HOME/backup"]="$SYNC/backup"
  ["$HOME/bin"]="$SYNC/bin"
  ["$HOME/documents"]="$SYNC/documents"
  ["$HOME/downloads"]="$SYNC/downloads"
  ["$HOME/hacking"]="$SYNC/hacking"
  ["$HOME/lists"]="$SYNC/lists"
  ["$HOME/movies"]="$SYNC/movies"
  ["$HOME/music"]="$SYNC/music"
  ["$HOME/pictures"]="$SYNC/pictures"
  ["$HOME/rocknroll"]="$SYNC/rocknroll"
  ["$HOME/study"]="$SYNC/study"
)
