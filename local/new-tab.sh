#!/bin/bash
# Smart new tab: creates tab in same directory, works for local and remote
set -euo pipefail
export PATH="/opt/homebrew/bin:$PATH"
source ~/dotfiles/config.sh 2>/dev/null || true
source ~/dotfiles/shared/window-info.sh

window_info=$(get_focused_window)
is_remote="${window_info%%|*}"
rest="${window_info#*|}"
local_cwd="${rest%%|*}"
remote_cwd="${rest#*|}"

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
    # Local: use foreground process cwd (more reliable than kitty's --cwd=current)
    kitten @ launch --type=tab --cwd="$local_cwd"
fi
