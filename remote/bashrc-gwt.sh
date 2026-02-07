# ── shell utilities for remote sessions ──
[[ -f "$HOME/dotfiles/config.sh" ]] && source "$HOME/dotfiles/config.sh"

# ── terminal title: cluster:path (for worktree picker integration) ──
__set_title() {
    printf '\033]0;%s:%s\007' "${CLUSTER:-${HOSTNAME%%.*}}" "$PWD"
}

# Append to PROMPT_COMMAND safely
if [[ -z "$PROMPT_COMMAND" ]]; then
    PROMPT_COMMAND="__set_title"
elif [[ "$PROMPT_COMMAND" != *"__set_title"* ]]; then
    PROMPT_COMMAND="__set_title;${PROMPT_COMMAND}"
fi

# Clean up any double semicolons from other scripts (pure.bash + zoxide issue)
PROMPT_COMMAND="${PROMPT_COMMAND//;;/;}"

# ── vsc: open VS Code (works locally and remotely) ──
vsc() {
    local dir="${1:-$(pwd)}"
    if [[ -n "$SSH_CONNECTION" ]]; then
        if ! kitten @ ls &>/dev/null; then
            echo "error: kitty remote control not available (use kitten ssh)" >&2
            return 1
        fi
        kitten @ launch --type=background -- code --remote "ssh-remote+${CLUSTER}" "$dir"
    else
        code "$dir"
    fi
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
