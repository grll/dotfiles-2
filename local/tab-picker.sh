#!/bin/bash
# Simplified worktree picker for kitty
# - Shows worktrees only (the unit of work)
# - Enter: focus existing tab or create tab for worktree
# - Alt+Enter: create new worktree (supports branch@base, or #PR syntax)
# - Ctrl+D: delete selected worktree (stays in picker for batch delete)

set -euo pipefail
export PATH="/opt/homebrew/bin:$PATH"
source ~/dotfiles/config.sh 2>/dev/null || true

# Get info about the underlying window (not the overlay itself)
# Use foreground_processes[0].cwd for accurate local cwd (more reliable than .cwd)
_get_focused_window() {
    kitten @ ls | jq -r '
      .[] | select(.is_focused) | .tabs[] | select(.is_focused) |
      (.windows[] | select(.is_self == false)) // .windows[0] |
      (.foreground_processes[0].cwd // .cwd) as $local_cwd |
      "\(.user_vars.is_remote // "")|\($local_cwd)|\(.user_vars.remote_cwd // "")"
    '
}

source ~/dotfiles/shared/format-branch.sh

# Detect if we're in remote context
_is_remote() {
    [[ "$1" == "1" ]]
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
    kitten @ close-tab --match "var:worktree=$path" 2>/dev/null || true

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
window_info=$(_get_focused_window)
is_remote_var="${window_info%%|*}"
rest="${window_info#*|}"
focused_cwd="${rest%%|*}"
remote_cwd="${rest#*|}"

# Fallback for legacy remote tabs (have remote_cwd but no is_remote)
if [[ -z "$is_remote_var" && -n "$remote_cwd" ]]; then
    is_remote_var="1"
fi

is_remote=0
if _is_remote "$is_remote_var"; then
    is_remote=1
fi

# Get repo from current context
if [[ "$is_remote" == "1" ]]; then
    # Get CWD from user variable (already decoded by kitty)
    if [[ -z "$remote_cwd" ]]; then
        # Fallback for tabs without user variable
        remote_cwd="$HOME"
    fi
    repo=$(ssh "$CLUSTER" "cd '$remote_cwd' 2>/dev/null && git rev-parse --show-toplevel" 2>/dev/null) || repo=""
    if [[ -z "$repo" ]]; then
        echo "Not in a git repo on remote"
        read -n1 -p "Press any key..."
        exit 1
    fi
    main_repo=$(ssh "$CLUSTER" "git -C '$repo' worktree list --porcelain" 2>/dev/null \
      | awk '/^worktree /{print $2; exit}')
else
    # Use cwd from focused window for local tabs
    repo=$(git -C "$focused_cwd" rev-parse --show-toplevel 2>/dev/null) || repo=""
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
  --header="Enter: go | Alt+Enter: new [branch@base, branch@#PR, or #PR] | Ctrl+D: delete" \
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
    local path="$1" name="$2"
    local branch smart_title

    if [[ "$is_remote" == "1" ]]; then
        # Get branch for smart title and matching
        branch=$(ssh "$CLUSTER" "git -C '$path' rev-parse --abbrev-ref HEAD" 2>/dev/null) || branch=""
        # Handle detached HEAD - get tracking ref
        if [[ "$branch" == "HEAD" ]]; then
            local ref=$(ssh "$CLUSTER" "git -C '$path' describe --all --exact-match HEAD 2>/dev/null") || ref=""
            [[ "$ref" == remotes/origin/* ]] && branch="${ref#remotes/origin/}"
        fi
        smart_title=$(format_branch "${branch:-$name}")

        # Try var:worktree first, then create new tab
        # Don't set --tab-title; let the remote shell's __set_title set it (includes PR number)
        kitten @ focus-tab --match "var:worktree=$path" 2>/dev/null \
          || kitten @ launch --type=tab --var "worktree=$path" -- kitten ssh "$CLUSTER" -t "cd '$path' && exec \$SHELL -l"
    else
        # Try var:worktree first, then fall back to cwd matching for manually-created tabs
        kitten @ focus-tab --match "var:worktree=$path" 2>/dev/null \
          || kitten @ focus-tab --match "cwd:$path" 2>/dev/null \
          || kitten @ launch --type=tab --tab-title "$name" --var "worktree=$path" --cwd="$path"
    fi
}

_create_worktree() {
    local branch="$1" base="${2:-origin/main}"
    local wt_path="$(dirname "$main_repo")/$(basename "$main_repo")-${branch//[\/.]/-}"

    # Resolve PR number to branch if base is #NNN
    if [[ "$base" == "#"* ]]; then
        local pr_number="${base#\#}"
        local pr_branch
        if [[ "$is_remote" == "1" ]]; then
            pr_branch=$(ssh "$CLUSTER" "cd '$main_repo' && gh pr view '$pr_number' --json headRefName -q '.headRefName'" 2>/dev/null)
        else
            pr_branch=$(gh pr view "$pr_number" --json headRefName -q '.headRefName' -R "$(git -C "$main_repo" remote get-url origin)" 2>/dev/null)
        fi
        if [[ -z "$pr_branch" ]]; then
            echo "Could not find PR #$pr_number"
            read -n1 -p "Press any key..."
            return 1
        fi
        # Fetch the PR branch and use it as base
        if [[ "$is_remote" == "1" ]]; then
            ssh "$CLUSTER" "git -C '$main_repo' fetch origin '$pr_branch'"
        else
            git -C "$main_repo" fetch origin "$pr_branch"
        fi
        base="origin/$pr_branch"
    fi

    if [[ "$is_remote" == "1" ]]; then
        ssh "$CLUSTER" "git -C '$main_repo' worktree add -b '$branch' '$wt_path' '$base'"
        ssh "$CLUSTER" "[[ -d '$main_repo/.venv' ]] && ln -s '$main_repo/.venv' '$wt_path/.venv'" || true
        ssh "$CLUSTER" "[[ -d '$main_repo/.claude' ]] && ln -s '$main_repo/.claude' '$wt_path/.claude'" || true
    else
        git -C "$main_repo" worktree add -b "$branch" "$wt_path" "$base"
        [[ -d "$main_repo/.venv" ]] && ln -s "$main_repo/.venv" "$wt_path/.venv" || true
        [[ -d "$main_repo/.claude" ]] && ln -s "$main_repo/.claude" "$wt_path/.claude" || true
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

    # Check if worktree already exists
    local wt_exists=0
    if [[ "$is_remote" == "1" ]]; then
        ssh "$CLUSTER" "[[ -d '$wt_path' ]]" && wt_exists=1
    else
        [[ -d "$wt_path" ]] && wt_exists=1
    fi

    # Create worktree if it doesn't exist
    if [[ "$wt_exists" == "0" ]]; then
        if [[ "$is_remote" == "1" ]]; then
            ssh "$CLUSTER" "git -C '$main_repo' fetch origin '$branch'"
            ssh "$CLUSTER" "git -C '$main_repo' worktree add -b '$branch' '$wt_path' 'origin/$branch'"
            ssh "$CLUSTER" "[[ -d '$main_repo/.venv' ]] && ln -s '$main_repo/.venv' '$wt_path/.venv'" || true
            ssh "$CLUSTER" "[[ -d '$main_repo/.claude' ]] && ln -s '$main_repo/.claude' '$wt_path/.claude'" || true
        else
            git -C "$main_repo" fetch origin "$branch"
            git -C "$main_repo" worktree add -b "$branch" "$wt_path" "origin/$branch"
            [[ -d "$main_repo/.venv" ]] && ln -s "$main_repo/.venv" "$wt_path/.venv" || true
            [[ -d "$main_repo/.claude" ]] && ln -s "$main_repo/.claude" "$wt_path/.claude" || true
        fi
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
elif [[ -n "$query" ]]; then
    echo "No match. Did you mean Alt+Enter to create '$query'?"
    read -n1 -p "Press any key..."
fi
