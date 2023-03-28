#   ____ _                        _
#  / ___| | ___  _ __   ___   ___| |__
# | |   | |/ _ \| '_ \ / _ \ / __| '_ \  - Clone simple backup utility
# | |___| | (_) | | | |  __/_\__ \ | | | - https://github.com/cherrynoize
#  \____|_|\___/|_| |_|\___(_)___/_| |_| - cherry-noize
#
# Config file for clone.sh

TEST="$HOME/.clone/TEST"

# Sync mappings
# (each ["key"] will be copied in "VALUE")
declare -A sync_map=(
  ["$HOME/.config/awesome"]="$TEST/config"
)
