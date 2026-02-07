# ── vsc: open VS Code on remote worktree ─────────────
[[ -f "$HOME/dotfiles/config.sh" ]] && source "$HOME/dotfiles/config.sh"

vsc() {
    local branch="${1:?usage: vsc <branch>}"
    local sanitized="${branch//[\/.]/-}"
    code --remote "ssh-remote+${CLUSTER}" "${REMOTE_REPO}-${sanitized}"
}

# ── gwt: worktree management (local mode) ────────────
gwt() {
    local out
    out="$(command gwt "$@")" || { echo "$out"; return 1; }
    if [[ -d "$out" ]]; then cd "$out"; else [[ -n "$out" ]] && echo "$out"; fi
}

[[ -f "$HOME/.local/share/gwt/gwt-completion.bash" ]] && source "$HOME/.local/share/gwt/gwt-completion.bash"
