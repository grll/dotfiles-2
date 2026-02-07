#!/bin/bash
# Smart new tab: creates tab in same directory, works for local and remote
set -euo pipefail
export PATH="/opt/homebrew/bin:$PATH"
source ~/dotfiles/config.sh 2>/dev/null || true

# Get the title of the current window (not overlay)
focused_title=$(kitten @ ls | jq -r '
  .[] | select(.is_focused) | .tabs[] | select(.is_focused) |
  (.windows[] | select(.is_self == false) | .title) // .title
')

# Detect remote context from tab title
if [[ "$focused_title" == "${CLUSTER:-rno}:"* ]]; then
    # Remote: extract path from title and launch new SSH tab
    remote_path="${focused_title#${CLUSTER}:}"
    kitten @ launch --type=tab --tab-title "${CLUSTER}:${remote_path}" -- kitten ssh "$CLUSTER" -t "cd '$remote_path' && exec \$SHELL -l"
else
    # Local: create new tab in current directory
    kitten @ launch --type=tab --cwd=current
fi
