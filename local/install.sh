#!/bin/bash
set -euo pipefail

DIR="$(cd "$(dirname "$0")" && pwd)"
CONFIG="$DIR/../config.sh"
SHELL_RC="$HOME/.bashrc"

if [[ ! -f "$CONFIG" ]]; then
    echo "error: config.sh not found"
    echo "  cp config.example.sh config.sh && edit it"
    exit 1
fi

# detect zsh
if [[ "${SHELL:-}" == */zsh ]]; then
    SHELL_RC="$HOME/.zshrc"
fi

# vsc function
MARKER="# ── vsc: open VS Code on remote worktree"
if grep -q "$MARKER" "$SHELL_RC" 2>/dev/null; then
    echo "✓ vsc already in $SHELL_RC"
else
    {
        echo ""
        echo "$MARKER ─────────────"
        echo 'source "$HOME/dotfiles/local/bashrc-local.sh"'
    } >> "$SHELL_RC"
    echo "✓ vsc function → $SHELL_RC"
fi

# kitty session
KITTY_DIR="$HOME/.config/kitty/sessions"
mkdir -p "$KITTY_DIR"
ln -sf "$DIR/sessions/work.conf" "$KITTY_DIR/work.conf"
echo "✓ kitty session → $KITTY_DIR/work.conf"

# gwt
mkdir -p "$HOME/.local/bin"
ln -sf "$DIR/../remote/gwt" "$HOME/.local/bin/gwt"
echo "✓ gwt → ~/.local/bin/gwt"

# spawn-agent
ln -sf "$DIR/spawn-agent.sh" "$HOME/.local/bin/spawn-agent"
echo "✓ spawn-agent → ~/.local/bin/spawn-agent"

# gwt completion
mkdir -p "$HOME/.local/share/gwt"
ln -sf "$DIR/../remote/gwt-completion.bash" "$HOME/.local/share/gwt/gwt-completion.bash"
echo "✓ completion → ~/.local/share/gwt/"

# kitty dotfiles config
ln -sf "$DIR/kitty-dotfiles.conf" "$HOME/.config/kitty/dotfiles.conf"
echo "✓ kitty config → ~/.config/kitty/dotfiles.conf"

# add include to kitty.conf (idempotent)
KITTY_CONF="$HOME/.config/kitty/kitty.conf"
INCLUDE_LINE="include dotfiles.conf"
if grep -qF "$INCLUDE_LINE" "$KITTY_CONF" 2>/dev/null; then
    echo "✓ include already in kitty.conf"
else
    printf '\n%s\n' "$INCLUDE_LINE" >> "$KITTY_CONF"
    echo "✓ added include to kitty.conf"
fi

# kitten ssh config (generated from CLUSTER)
source "$CONFIG"
cat > "$HOME/.config/kitty/ssh.conf" <<EOF
# managed by dotfiles — do not edit
hostname ${CLUSTER}
forward_remote_control yes
EOF
echo "✓ ssh.conf → ~/.config/kitty/ssh.conf"

# claude code skills
rm -rf "$HOME/.claude/skills"
ln -s "$DIR/../claude/skills" "$HOME/.claude/skills"
echo "✓ claude skills → ~/.claude/skills"

# claude code hooks (merge into existing settings)
CLAUDE_SETTINGS="$HOME/.claude/settings.json"
HOOKS_FILE="$DIR/../claude/claude-hooks.json"
if [[ -f "$HOOKS_FILE" ]]; then
    mkdir -p "$HOME/.claude"
    if [[ -f "$CLAUDE_SETTINGS" ]]; then
        jq -s '.[0] * .[1]' "$CLAUDE_SETTINGS" "$HOOKS_FILE" > "$CLAUDE_SETTINGS.tmp"
        mv "$CLAUDE_SETTINGS.tmp" "$CLAUDE_SETTINGS"
    else
        cp "$HOOKS_FILE" "$CLAUDE_SETTINGS"
    fi
    echo "✓ claude hooks → ~/.claude/settings.json"
fi

echo ""
echo "done — restart kitty and source your shell config"
