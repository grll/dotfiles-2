# ── vsc: open VS Code on remote worktree ─────────────
[[ -f "$HOME/dotfiles/config.sh" ]] && source "$HOME/dotfiles/config.sh"

# Disable Claude Code auto title (we set it via hooks)
export CLAUDE_CODE_DISABLE_TERMINAL_TITLE=1

vsc() {
    local branch="${1:?usage: vsc <branch>}"
    local sanitized="${branch//[\/.]/-}"
    local remote_dir="${REMOTE_REPO}-${sanitized}"

    code --remote "ssh-remote+${CLUSTER}" "$remote_dir"

    # Check for PR on remote and open it in VS Code's GitHub PR extension
    # Run in background to avoid blocking the terminal
    (
        # Query PR from the remote repository
        local pr_url
        pr_url=$(ssh "${CLUSTER}" "cd '$remote_dir' && gh pr view --json url -q '.url'" 2>/dev/null)
        if [[ -n "$pr_url" ]]; then
            sleep 5  # Give VS Code time to connect to remote
            open "vscode://github.vscode-pull-request-github/open-pull-request-changes?uri=${pr_url}"
        fi
    ) &
}

# ── gwt: worktree management (local mode) ────────────
gwt() {
    local out
    out="$(command gwt "$@")" || { echo "$out"; return 1; }
    if [[ -d "$out" ]]; then cd "$out"; else [[ -n "$out" ]] && echo "$out"; fi
}

[[ -f "$HOME/.local/share/gwt/gwt-completion.bash" ]] && source "$HOME/.local/share/gwt/gwt-completion.bash"

# ── Kitty CWD tracking via precmd ────────────────────
# Emit OSC 7 after every command so kitty knows current directory
__kitty_osc7() {
    printf '\e]7;file://localhost%s\a' "$PWD"
}

# Add to precmd hooks (zsh) or PROMPT_COMMAND (bash)
if [[ -n "$ZSH_VERSION" ]]; then
    autoload -Uz add-zsh-hook
    add-zsh-hook precmd __kitty_osc7
elif [[ -n "$BASH_VERSION" ]]; then
    if [[ -z "$PROMPT_COMMAND" ]]; then
        PROMPT_COMMAND="__kitty_osc7"
    elif [[ "$PROMPT_COMMAND" != *"__kitty_osc7"* ]]; then
        PROMPT_COMMAND="__kitty_osc7;${PROMPT_COMMAND}"
    fi
fi

# ── SSH shortcuts ─────────────────────────────────────
alias rno='kitten ssh rno'

# ── Command shortcuts ─────────────────────────────────
alias cld='claude'
