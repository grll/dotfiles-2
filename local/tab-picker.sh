#!/bin/bash
# Simplified worktree picker for kitty
# - Shows worktrees only (the unit of work)
# - Enter: focus existing tab or create tab for worktree
# - Alt+Enter: create new worktree (supports branch@base syntax)

set -euo pipefail
export PATH="/opt/homebrew/bin:$PATH"
source ~/dotfiles/config.sh 2>/dev/null || true

# Get the title of the underlying window (not the overlay itself)
# When running as overlay, is_self=true marks the overlay; we want the other window
focused_title=$(kitten @ ls | jq -r '
  .[] | select(.is_focused) | .tabs[] | select(.is_focused) |
  (.windows[] | select(.is_self == false) | .title) // .title
')

# Detect remote context from tab title
is_remote=0
if [[ "$focused_title" == "${CLUSTER:-rno}:"* ]]; then
    is_remote=1
fi

# Get repo from current context (cd into repo before Cmd+G)
if [[ "$is_remote" == "1" ]]; then
    # Extract remote cwd from title like "rno:/home/user/Projects/forge"
    remote_cwd="${focused_title#${CLUSTER}:}"
    repo=$(ssh "$CLUSTER" "cd '$remote_cwd' 2>/dev/null && git rev-parse --show-toplevel" 2>/dev/null) || repo=""
    if [[ -z "$repo" ]]; then
        echo "Not in a git repo on remote"
        read -n1 -p "Press any key..."
        exit 1
    fi
    # Get main worktree (first in list) for consistent naming
    main_repo=$(ssh "$CLUSTER" "git -C '$repo' worktree list --porcelain" 2>/dev/null \
      | awk '/^worktree /{print $2; exit}')
    list=$(ssh "$CLUSTER" "git -C '$repo' worktree list --porcelain" 2>/dev/null \
      | awk '/^worktree /{print $2}' | while read -r p; do
        name=$(basename "$p" | sed "s|^$(basename "$main_repo")-||")
        echo "$name|$p"
    done)
else
    repo=$(git rev-parse --show-toplevel 2>/dev/null) || repo=""
    if [[ -z "$repo" ]]; then
        echo "Not in a git repo"
        read -n1 -p "Press any key..."
        exit 1
    fi
    # Get main worktree (first in list) for consistent naming
    main_repo=$(git -C "$repo" worktree list --porcelain | awk '/^worktree /{print $2; exit}')
    list=$(git -C "$repo" worktree list --porcelain \
      | awk '/^worktree /{print $2}' | while read -r p; do
        name=$(basename "$p" | sed "s|^$(basename "$main_repo")-||")
        [[ "$p" == "$main_repo" ]] && name="main"
        echo "$name|$p"
    done)
fi

# fzf (exit code 1 = no match, which is fine for creating new worktrees)
set +e
result=$(echo "$list" | fzf --reverse --prompt='worktree> ' \
  --delimiter='|' --with-nth=1 \
  --header="Enter: go | Alt+Enter: new [branch@base]" \
  --print-query --expect=alt-enter,enter)
fzf_exit=$?
set -e
[[ $fzf_exit -gt 1 ]] && exit 0

query=$(sed -n '1p' <<< "$result")
key=$(sed -n '2p' <<< "$result")
selection=$(sed -n '3p' <<< "$result")
sel_path=$(cut -d'|' -f2 <<< "$selection")


_go() {
    local path="$1" title="$2"
    if [[ "$is_remote" == "1" ]]; then
        kitten @ focus-tab --match "title:^${CLUSTER}:.*${title}" 2>/dev/null \
          || kitten @ launch --type=tab --tab-title "${CLUSTER}:${path}" -- kitten ssh "$CLUSTER" -t "cd '$path' && exec \$SHELL -l"
    else
        kitten @ focus-tab --match "cwd:$path" 2>/dev/null \
          || kitten @ launch --type=tab --tab-title "$title" --cwd="$path"
    fi
}

_create_worktree() {
    local branch="$1" base="${2:-origin/main}"
    local wt_path="$(dirname "$main_repo")/$(basename "$main_repo")-${branch//[\/.]/-}"

    if [[ "$is_remote" == "1" ]]; then
        ssh "$CLUSTER" "git -C '$main_repo' worktree add -b '$branch' '$wt_path' '$base'"
        ssh "$CLUSTER" "[[ -d '$main_repo/.venv' ]] && ln -s '$main_repo/.venv' '$wt_path/.venv'" || true
    else
        git -C "$main_repo" worktree add -b "$branch" "$wt_path" "$base"
        [[ -d "$main_repo/.venv" ]] && ln -s "$main_repo/.venv" "$wt_path/.venv" || true
    fi
    _go "$wt_path" "${branch//[\/.]/-}"
}

if [[ "$key" == "alt-enter" && -n "$query" ]]; then
    if [[ "$query" == *@* ]]; then
        _create_worktree "${query%%@*}" "${query#*@}"
    else
        _create_worktree "$query"
    fi
elif [[ -n "$sel_path" ]]; then
    _go "$sel_path" "$(cut -d'|' -f1 <<< "$selection")"
fi
