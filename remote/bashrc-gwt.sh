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

# ── Zoxide + Kitty integration ────────────────────────
# Wrap z to ensure Kitty CWD update via OSC 7
z() {
    echo "DEBUG z called with args: $*" >> /tmp/z-debug.log
    echo "DEBUG __zoxide_z exists: $(type -t __zoxide_z 2>&1)" >> /tmp/z-debug.log
    __zoxide_z "$@" 2>> /tmp/z-debug.log
    local ret=$?
    echo "DEBUG __zoxide_z returned: $ret, PWD=$PWD" >> /tmp/z-debug.log
    builtin printf '\e]7;kitty-shell-cwd://%s%s\a' "$HOSTNAME" "$PWD"
    return $ret
}

# ── vsc: open VS Code (works locally and remotely) ──
vsc() {
    local dir="${1:-$(pwd)}"
    if [[ -n "$SSH_CONNECTION" ]]; then
        if ! kitten @ ls &>/dev/null; then
            echo "error: kitty remote control not available (use kitten ssh)" >&2
            return 1
        fi
        # Use full path since kitty background doesn't have user's PATH
        kitten @ launch --type=background -- /opt/homebrew/bin/code --remote "ssh-remote+${CLUSTER}" "$dir"
    else
        code "$dir"
    fi
}

# ── Command shortcuts ─────────────────────────────────
alias cld='claude'

# ── notify: send macOS notification via kitty remote control ──
notify() {
    local msg="${*:-Done}"
    if kitten @ ls &>/dev/null; then
        kitten @ launch --type=background -- osascript -e "display notification \"${msg}\" with title \"Terminal\""
    else
        echo ":: ${msg}" >&2
    fi
}
