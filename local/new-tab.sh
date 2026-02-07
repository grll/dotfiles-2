#!/bin/bash
# Smart new tab: creates tab in same directory, works for local and remote
set -euo pipefail
export PATH="/opt/homebrew/bin:$PATH"
source ~/dotfiles/config.sh 2>/dev/null || true

# Get info about the current window (not overlay)
window_info=$(kitten @ ls | jq -r '
  .[] | select(.is_focused) | .tabs[] | select(.is_focused) |
  (.windows[] | select(.is_self == false)) // .windows[0] |
  "\(.user_vars.remote // "")|\(.title)"
')
remote_var="${window_info%%|*}"
focused_title="${window_info#*|}"

# Detect remote context from user variable
if [[ -n "$remote_var" ]]; then
    # Remote: use path from title and launch new SSH tab with remote var
    kitten @ launch --type=tab --tab-title "$focused_title" --var "remote=$remote_var" -- kitten ssh "$remote_var" -t "cd '$focused_title' && exec \$SHELL -l"
else
    # Local: create new tab in current directory
    kitten @ launch --type=tab --cwd=current
fi
