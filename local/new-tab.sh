#!/bin/bash
# Smart new tab: creates tab in same directory, works for local and remote
set -euo pipefail
export PATH="/opt/homebrew/bin:$PATH"
source ~/dotfiles/config.sh 2>/dev/null || true

# Get window info from focused tab
window_info=$(kitten @ ls | jq -r '
  .[] | select(.is_focused) | .tabs[] | select(.is_focused) |
  (.windows[] | select(.is_self == false)) // .windows[0] |
  "\(.title)|\(.user_vars.remote_cwd // "")"
')

focused_title="${window_info%%|*}"
remote_cwd_b64="${window_info#*|}"

# Detect remote context from tab title
if [[ "$focused_title" == "${CLUSTER:-rno}:"* ]]; then
    # Remote: get CWD from user variable (base64 encoded)
    if [[ -n "$remote_cwd_b64" ]]; then
        remote_path=$(echo "$remote_cwd_b64" | base64 -d)
    else
        # Fallback: prompt will update title on first command
        remote_path="~"
    fi
    kitten @ launch --type=tab -- kitten ssh "$CLUSTER" -t "cd '$remote_path' && exec \$SHELL -l"
else
    # Local: create new tab in current directory
    kitten @ launch --type=tab --cwd=current
fi
