#!/bin/bash
set -euo pipefail

DIR="$(cd "$(dirname "$0")" && pwd)"
CONFIG="$DIR/../config.sh"

if [[ ! -f "$CONFIG" ]]; then
    echo "error: config.sh not found"
    echo "  cp config.example.sh config.sh && edit it"
    exit 1
fi

# bashrc (idempotent)
MARKER="# ── shell utilities for remote sessions"
if grep -q "$MARKER" "$HOME/.bashrc" 2>/dev/null; then
    echo "ok .bashrc already configured"
else
    {
        echo ""
        echo "$MARKER ───────────────"
        echo 'source "$HOME/dotfiles/remote/bashrc-gwt.sh"'
    } >> "$HOME/.bashrc"
    echo "ok appended shell utilities to .bashrc"
fi

# claude code skills
rm -rf "$HOME/.claude/skills"
ln -s "$DIR/../claude/skills" "$HOME/.claude/skills"
echo "ok claude skills → ~/.claude/skills"

# claude code hooks (merge shared + remote-specific into settings)
CLAUDE_SETTINGS="$HOME/.claude/settings.json"
SHARED_HOOKS="$DIR/../claude/claude-hooks.json"
REMOTE_HOOKS="$DIR/claude-hooks.json"

mkdir -p "$HOME/.claude"
if [[ -f "$CLAUDE_SETTINGS" ]]; then
    # Merge existing + shared + remote hooks
    jq -s '.[0] * .[1] * .[2]' "$CLAUDE_SETTINGS" "$SHARED_HOOKS" "$REMOTE_HOOKS" > "$CLAUDE_SETTINGS.tmp"
    mv "$CLAUDE_SETTINGS.tmp" "$CLAUDE_SETTINGS"
else
    # No existing settings - merge shared + remote
    jq -s '.[0] * .[1]' "$SHARED_HOOKS" "$REMOTE_HOOKS" > "$CLAUDE_SETTINGS"
fi
echo "ok claude hooks → ~/.claude/settings.json"

# checks
echo ""
command -v fzf &>/dev/null || echo "!! install fzf: sudo apt install fzf"
echo ""
echo "done - log out and SSH back in"
