#!/bin/bash
# Smart new tab/window: creates tab or OS window in same directory, works for local and remote
# Usage: new-tab.sh [tab|os-window]  (default: tab)
set -euo pipefail
export PATH="/opt/homebrew/bin:$PATH"
source ~/dotfiles/config.sh 2>/dev/null || true

launch_type="${1:-tab}"

# Get window info from focused tab
# Use foreground_processes[0].cwd for accurate local cwd
window_info=$(kitten @ ls | jq -r '
  .[] | select(.is_focused) | .tabs[] | select(.is_focused) |
  (.windows[] | select(.is_self == false)) // .windows[0] |
  (.foreground_processes[0].cwd // .cwd) as $local_cwd |
  "\(.user_vars.is_remote // "")|\(.user_vars.remote_cwd // "")|\($local_cwd)"
')

is_remote="${window_info%%|*}"
rest="${window_info#*|}"
remote_cwd="${rest%%|*}"
local_cwd="${rest##*|}"

# Fallback for legacy remote tabs (have remote_cwd but no is_remote)
if [[ -z "$is_remote" && -n "$remote_cwd" ]]; then
    is_remote="1"
fi

if [[ "$is_remote" == "1" ]]; then
    # Remote: get CWD from user variable (already decoded by kitty)
    if [[ -z "$remote_cwd" ]]; then
        # Fallback: prompt will update title on first command
        remote_cwd="~"
    fi
    kitten @ launch --type="$launch_type" -- kitten ssh "$CLUSTER" -t "cd '$remote_cwd' && exec \$SHELL -l"
else
    # Local: use foreground process cwd (more reliable than kitty's --cwd=current)
    kitten @ launch --type="$launch_type" --cwd="$local_cwd"
fi
