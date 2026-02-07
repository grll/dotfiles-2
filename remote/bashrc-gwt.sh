# ── shell utilities for remote sessions ──
[[ -f "$HOME/dotfiles/config.sh" ]] && source "$HOME/dotfiles/config.sh"

# ── terminal title: host:branch (or host:dir) ──
__git_branch() {
    git rev-parse --abbrev-ref HEAD 2>/dev/null
}

__set_title() {
    local branch=$(__git_branch)
    local context="${branch:-${PWD##*/}}"
    printf '\033]0;%s:%s\007' "${HOSTNAME%%.*}" "$context"
}

PROMPT_COMMAND="__set_title${PROMPT_COMMAND:+;$PROMPT_COMMAND}"

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
