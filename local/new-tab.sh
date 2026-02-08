#!/bin/bash
# Smart new tab: creates tab in same directory, works for local and remote
set -euo pipefail
export PATH="/opt/homebrew/bin:$PATH"
source ~/dotfiles/config.sh 2>/dev/null || true

# Get window info from focused tab
window_info=$(kitten @ ls | jq -r '
  .[] | select(.is_focused) | .tabs[] | select(.is_focused) |
  (.windows[] | select(.is_self == false)) // .windows[0] |
  "\(.user_vars.is_remote // "")|\(.user_vars.remote_cwd // "")"
')

is_remote="${window_info%%|*}"
remote_cwd="${window_info#*|}"

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
    kitten @ launch --type=tab -- kitten ssh "$CLUSTER" -t "cd '$remote_cwd' && exec \$SHELL -l"
else
    # Local: create new tab in current directory
    kitten @ launch --type=tab --cwd=current
fi
