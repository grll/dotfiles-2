#!/bin/bash
set -euo pipefail

DIR="$(cd "$(dirname "$0")" && pwd)"
CONFIG="$DIR/../config.sh"

if [[ ! -f "$CONFIG" ]]; then
    echo "error: config.sh not found"
    echo "  cp config.example.sh config.sh && edit it"
    exit 1
fi

# gwt
mkdir -p "$HOME/.local/bin"
ln -sf "$DIR/gwt" "$HOME/.local/bin/gwt"
echo "✓ gwt → ~/.local/bin/gwt"

# completion
mkdir -p "$HOME/.local/share/gwt"
ln -sf "$DIR/gwt-completion.bash" "$HOME/.local/share/gwt/gwt-completion.bash"
echo "✓ completion → ~/.local/share/gwt/"

# tmux
ln -sf "$DIR/tmux.conf" "$HOME/.tmux.conf"
echo "✓ tmux.conf → ~/.tmux.conf"

# bashrc (idempotent)
MARKER="# ── gwt: tmux auto-attach + completion"
if grep -q "$MARKER" "$HOME/.bashrc" 2>/dev/null; then
    echo "✓ .bashrc already configured"
else
    {
        echo ""
        echo "$MARKER ───────────────"
        echo 'source "$HOME/dotfiles/remote/bashrc-gwt.sh"'
    } >> "$HOME/.bashrc"
    echo "✓ appended gwt block to .bashrc"
fi

# checks
echo ""
echo "$PATH" | grep -q "$HOME/.local/bin" || echo "⚠ add to .bashrc: export PATH=\"\$HOME/.local/bin:\$PATH\""
command -v fzf &>/dev/null || echo "⚠ install fzf: sudo apt install fzf"
command -v tmux &>/dev/null || echo "⚠ install tmux: sudo apt install tmux"
echo ""
echo "done — log out and SSH back in"
