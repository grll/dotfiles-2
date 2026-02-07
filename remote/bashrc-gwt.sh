# ── gwt: tmux auto-attach + completion ───────────────
[[ -f "$HOME/dotfiles/config.sh" ]] && source "$HOME/dotfiles/config.sh"

if [ -n "$SSH_CONNECTION" ] && [ -z "$TMUX" ]; then
    tmux attach -t main 2>/dev/null || tmux new-session -s main -c "${REMOTE_REPO:-$HOME}"
fi

[ -f "$HOME/.local/share/gwt/gwt-completion.bash" ] && source "$HOME/.local/share/gwt/gwt-completion.bash"

# ── vsc: open VS Code locally via kitty remote control ──
vsc() {
    local dir
    if [[ $# -gt 0 ]]; then
        local sanitized="${1//[\/.]/-}"
        dir="$(dirname "$REMOTE_REPO")/$(basename "$REMOTE_REPO")-${sanitized}"
    else
        dir="$(pwd)"
    fi
    if ! kitten @ ls &>/dev/null; then
        echo "error: kitty remote control not available (use kitten ssh)" >&2
        return 1
    fi
    kitten @ launch --type=background -- code --remote "ssh-remote+${CLUSTER}" "$dir"
}

# ── notify: send macOS notification via kitty remote control ──
notify() {
    local msg="${*:-Done}"
    if kitten @ ls &>/dev/null; then
        kitten @ launch --type=background -- osascript -e "display notification \"${msg}\" with title \"Terminal\""
    else
        echo ":: ${msg}" >&2
    fi
}
