#!/bin/bash
# Simplified worktree picker for kitty
# - Shows worktrees only (the unit of work)
# - Enter: focus existing tab or create tab for worktree
# - Alt+Enter: create new worktree (supports branch@base, or #PR syntax)
# - Ctrl+D: delete selected worktree (stays in picker for batch delete)

set -euo pipefail
export PATH="/opt/homebrew/bin:$PATH"
source ~/dotfiles/config.sh 2>/dev/null || true

# Get the title of the underlying window (not the overlay itself)
_get_focused_title() {
    kitten @ ls | jq -r '
      .[] | select(.is_focused) | .tabs[] | select(.is_focused) |
      (.windows[] | select(.is_self == false) | .title) // .title
    '
}

# Detect if we're in remote context
_is_remote() {
    [[ "$1" == "${CLUSTER:-rno}:"* ]]
}

# Get worktree list
_get_list() {
    local is_remote="$1" main_repo="$2"
    if [[ "$is_remote" == "1" ]]; then
        ssh "$CLUSTER" "git -C '$main_repo' worktree list --porcelain" 2>/dev/null \
          | awk '/^worktree /{print $2}' | while read -r p; do
            name=$(basename "$p" | sed "s|^$(basename "$main_repo")-||")
            echo "$name|$p"
        done
    else
        git -C "$main_repo" worktree list --porcelain \
          | awk '/^worktree /{print $2}' | while read -r p; do
            name=$(basename "$p" | sed "s|^$(basename "$main_repo")-||")
            [[ "$p" == "$main_repo" ]] && name="main"
            echo "$name|$p"
        done
    fi
}

# Handle --delete mode (called from fzf bind)
if [[ "${1:-}" == "--delete" ]]; then
    is_remote="$2"
    main_repo="$3"
    path="$4"
    name="$5"

    # Prevent deleting main worktree
    [[ "$path" == "$main_repo" ]] && exit 0

    # Get branch name
    if [[ "$is_remote" == "1" ]]; then
        branch=$(ssh "$CLUSTER" "git -C '$path' rev-parse --abbrev-ref HEAD" 2>/dev/null) || true
    else
        branch=$(git -C "$path" rev-parse --abbrev-ref HEAD 2>/dev/null) || true
    fi

    # Close any tabs with this worktree
    if [[ "$is_remote" == "1" ]]; then
        kitten @ close-tab --match "title:^${CLUSTER}:.*${name}$" 2>/dev/null || true
    else
        kitten @ close-tab --match "cwd:$path" 2>/dev/null || true
    fi

    # Remove worktree and branch
    if [[ "$is_remote" == "1" ]]; then
        ssh "$CLUSTER" "git -C '$main_repo' worktree remove '$path' --force" 2>/dev/null || true
        [[ -n "$branch" ]] && ssh "$CLUSTER" "git -C '$main_repo' branch -d '$branch'" 2>/dev/null || true
    else
        git -C "$main_repo" worktree remove "$path" --force 2>/dev/null || true
        [[ -n "$branch" ]] && git -C "$main_repo" branch -d "$branch" 2>/dev/null || true
    fi
    exit 0
fi

# Handle --list mode (called from fzf reload)
if [[ "${1:-}" == "--list" ]]; then
    _get_list "$2" "$3"
    exit 0
fi

# Main flow
focused_title=$(_get_focused_title)

is_remote=0
if _is_remote "$focused_title"; then
    is_remote=1
fi

# Get repo from current context
if [[ "$is_remote" == "1" ]]; then
    remote_cwd="${focused_title#${CLUSTER}:}"
    repo=$(ssh "$CLUSTER" "cd '$remote_cwd' 2>/dev/null && git rev-parse --show-toplevel" 2>/dev/null) || repo=""
    if [[ -z "$repo" ]]; then
        echo "Not in a git repo on remote"
        read -n1 -p "Press any key..."
        exit 1
    fi
    main_repo=$(ssh "$CLUSTER" "git -C '$repo' worktree list --porcelain" 2>/dev/null \
      | awk '/^worktree /{print $2; exit}')
else
    repo=$(git rev-parse --show-toplevel 2>/dev/null) || repo=""
    if [[ -z "$repo" ]]; then
        echo "Not in a git repo"
        read -n1 -p "Press any key..."
        exit 1
    fi
    main_repo=$(git -C "$repo" worktree list --porcelain | awk '/^worktree /{print $2; exit}')
fi

list=$(_get_list "$is_remote" "$main_repo")
script_path="${BASH_SOURCE[0]}"

# fzf with inline delete (ctrl-d) that reloads list
set +e
result=$(echo "$list" | fzf --reverse --prompt='worktree> ' \
  --delimiter='|' --with-nth=1 \
  --header="Enter: go | Alt+Enter: new [branch@base or #PR] | Ctrl+D: delete" \
  --print-query --expect=alt-enter,enter \
  --bind "ctrl-d:execute-silent($script_path --delete '$is_remote' '$main_repo' {2} {1})+reload($script_path --list '$is_remote' '$main_repo')")
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
        # Try exact match first, then with trailing slash for subdirectories
        kitten @ focus-tab --match "title:${CLUSTER}:${path}\$" 2>/dev/null \
          || kitten @ focus-tab --match "title:^${CLUSTER}:${path}/" 2>/dev/null \
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

_checkout_pr() {
    local pr_number="$1"
    local branch

    # Get branch name from PR
    if [[ "$is_remote" == "1" ]]; then
        branch=$(ssh "$CLUSTER" "cd '$main_repo' && gh pr view '$pr_number' --json headRefName -q '.headRefName'" 2>/dev/null)
    else
        branch=$(gh pr view "$pr_number" --json headRefName -q '.headRefName' -R "$(git -C "$main_repo" remote get-url origin)" 2>/dev/null)
    fi

    if [[ -z "$branch" ]]; then
        echo "Could not find PR #$pr_number"
        read -n1 -p "Press any key..."
        return 1
    fi

    local wt_path="$(dirname "$main_repo")/$(basename "$main_repo")-${branch//[\/.]/-}"

    # Fetch and create worktree tracking the remote branch
    if [[ "$is_remote" == "1" ]]; then
        ssh "$CLUSTER" "git -C '$main_repo' fetch origin '$branch'"
        ssh "$CLUSTER" "git -C '$main_repo' worktree add '$wt_path' 'origin/$branch'"
        ssh "$CLUSTER" "[[ -d '$main_repo/.venv' ]] && ln -s '$main_repo/.venv' '$wt_path/.venv'" || true
    else
        git -C "$main_repo" fetch origin "$branch"
        git -C "$main_repo" worktree add "$wt_path" "origin/$branch"
        [[ -d "$main_repo/.venv" ]] && ln -s "$main_repo/.venv" "$wt_path/.venv" || true
    fi
    _go "$wt_path" "${branch//[\/.]/-}"
}

if [[ "$key" == "alt-enter" && -n "$query" ]]; then
    if [[ "$query" == "#"* ]]; then
        # PR number: #123
        _checkout_pr "${query#\#}"
    elif [[ "$query" == *@* ]]; then
        _create_worktree "${query%%@*}" "${query#*@}"
    else
        _create_worktree "$query"
    fi
elif [[ -n "$sel_path" ]]; then
    _go "$sel_path" "$(cut -d'|' -f1 <<< "$selection")"
fi
