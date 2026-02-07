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

# checks
echo ""
command -v fzf &>/dev/null || echo "!! install fzf: sudo apt install fzf"
echo ""
echo "done - log out and SSH back in"
