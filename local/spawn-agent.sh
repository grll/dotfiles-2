#!/bin/bash
# Create a git worktree, write TASK.md from stdin, open a kitty tab with Claude Code.
# Usage: spawn-agent <branch> [base]
#        echo "task content" | spawn-agent <branch> [base]
set -euo pipefail

source ~/dotfiles/config.sh 2>/dev/null || true

BRANCH="${1:?usage: spawn-agent <branch> [base]}"
BASE="${2:-origin/main}"

# Find main repo (first worktree = main)
MAIN_REPO=$(git worktree list --porcelain | awk '/^worktree /{print $2; exit}')
REPO_NAME=$(basename "$MAIN_REPO")
SANITIZED="${BRANCH//[\/.]/-}"
WT_PATH="$(dirname "$MAIN_REPO")/${REPO_NAME}-${SANITIZED}"

# Create worktree
git -C "$MAIN_REPO" worktree add -b "$BRANCH" "$WT_PATH" "$BASE"

# Symlink shared directories
[[ -d "$MAIN_REPO/.venv" ]] && ln -s "$MAIN_REPO/.venv" "$WT_PATH/.venv" || true
[[ -d "$MAIN_REPO/.claude" ]] && ln -s "$MAIN_REPO/.claude" "$WT_PATH/.claude" || true

# Write TASK.md from stdin if piped
if [[ ! -t 0 ]]; then
    cat > "$WT_PATH/TASK.md"
fi

PROMPT="Read TASK.md and implement the task. Use /commit for commits, /pr when done."

# Launch kitty tab with Claude
if [[ -n "${SSH_CONNECTION:-}" ]]; then
    # Remote: kitten @ talks to local kitty via forwarded remote control
    kitten @ launch --type=tab \
        --var "worktree=$WT_PATH" \
        -- kitten ssh "$CLUSTER" -t "cd '$WT_PATH' && claude '$PROMPT'"
else
    # Local: use login shell so PATH includes brew, cargo, etc.
    kitten @ launch --type=tab \
        --cwd="$WT_PATH" \
        --var "worktree=$WT_PATH" \
        -- zsh -lc "claude '$PROMPT'"
fi

echo "Spawned agent in $WT_PATH"
