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

# ── Zoxide + Kitty integration ────────────────────────
# Wrap z to ensure Kitty CWD update via OSC 7
z() {
    __zoxide_z "$@" && builtin printf '\e]7;kitty-shell-cwd://%s%s\a' "$HOSTNAME" "$PWD"
}

# ── SSH shortcuts ─────────────────────────────────────
alias rno='kitten ssh rno'

# ── Claude Code with tab identification ───────────────
cld() {
    # Set user variable to identify this as a Claude Code tab
    printf '\033]1337;SetUserVar=claude_code=%s\007' "$(printf '1' | base64)"
    # Set tab title
    printf '\033]1;Claude Code\007'
    claude "$@"
    # Clear the variable when Claude exits
    printf '\033]1337;SetUserVar=claude_code\007'
}
