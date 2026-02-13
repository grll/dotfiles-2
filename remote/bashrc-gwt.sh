# ── shell utilities for remote sessions ──
[[ -f "$HOME/dotfiles/config.sh" ]] && source "$HOME/dotfiles/config.sh"

# Disable Claude Code auto title (we set it via hooks)
export CLAUDE_CODE_DISABLE_TERMINAL_TITLE=1

# ── PR cache for tab titles ──
__pr_cache_dir="$HOME/.cache/tab-title"
__pr_cache_stale=300  # 5 minutes

__get_pr_number() {
    local branch="$1"
    # Sanitize branch name for filename (replace / with --)
    local cache_file="$__pr_cache_dir/${branch//\//__}"

    # Check cache
    if [[ -f "$cache_file" ]]; then
        local age=$(( $(date +%s) - $(stat -c %Y "$cache_file" 2>/dev/null || stat -f %m "$cache_file" 2>/dev/null) ))
        local pr_num=$(cat "$cache_file")

        # Refresh in background if stale
        if (( age > __pr_cache_stale )); then
            ( __refresh_pr_cache "$branch" & ) 2>/dev/null
        fi

        [[ -n "$pr_num" && "$pr_num" != "0" ]] && echo "$pr_num"
        return
    fi

    # No cache - trigger async fetch
    ( __refresh_pr_cache "$branch" & ) 2>/dev/null
}

__refresh_pr_cache() {
    local branch="$1"
    # Sanitize branch name for filename (replace / with --)
    local cache_file="$__pr_cache_dir/${branch//\//__}"
    mkdir -p "$__pr_cache_dir"
    local pr_num=$(gh pr view "$branch" --json number -q '.number' 2>/dev/null || echo "0")
    echo "$pr_num" > "$cache_file"
}

# ── Smart title: cluster:branch #PR or cluster:~/path ──
__format_branch() {
    local branch="$1"
    # Strip user/ prefix if present
    branch="${branch#*/}"
    # Check for Linear ticket pattern (e.g., sol-3295-description)
    if [[ "$branch" =~ ^([a-zA-Z]+-[0-9]+) ]]; then
        echo "${BASH_REMATCH[1]^^}"  # Uppercase ticket ID
    else
        echo "$branch"
    fi
}

__set_title() {
    local cluster="${CLUSTER:-${HOSTNAME%%.*}}"
    local title=""

    # Set user variables for local scripts to read
    # Use -w0 to prevent line wrapping on Linux (breaks escape sequence)
    printf '\033]1337;SetUserVar=remote_cwd=%s\007' "$(printf '%s' "$PWD" | base64 -w0)"
    printf '\033]1337;SetUserVar=is_remote=%s\007' "$(printf '1' | base64 -w0)"

    # Check if in git repo
    local git_root branch
    git_root=$(git rev-parse --show-toplevel 2>/dev/null)

    if [[ -n "$git_root" ]]; then
        branch=$(git rev-parse --abbrev-ref HEAD 2>/dev/null)

        if [[ "$branch" == "HEAD" ]]; then
            # Detached HEAD - try to get tracking ref (e.g., remotes/origin/user/branch)
            local ref=$(git describe --all --exact-match HEAD 2>/dev/null)
            if [[ "$ref" == remotes/origin/* ]]; then
                branch="${ref#remotes/origin/}"
            else
                # Fallback to repo name
                branch=""
            fi
        fi

        if [[ -n "$branch" ]]; then
            # Format branch name
            title=$(__format_branch "$branch")

            # Add PR number if cached
            local pr_num=$(__get_pr_number "$branch")
            [[ -n "$pr_num" ]] && title="$title #$pr_num"
        else
            # No branch info - show repo name
            title=$(basename "$git_root")
        fi
    else
        # Not in git - show abbreviated path
        title="${PWD/#$HOME/\~}"
    fi

    printf '\033]0;%s:%s\007' "$cluster" "$title"
    # Emit OSC 7 for Kitty CWD tracking (works with zoxide z)
    builtin printf '\e]7;kitty-shell-cwd://%s%s\a' "$HOSTNAME" "$PWD"
}

# Append to PROMPT_COMMAND safely
if [[ -z "$PROMPT_COMMAND" ]]; then
    PROMPT_COMMAND="__set_title"
elif [[ "$PROMPT_COMMAND" != *"__set_title"* ]]; then
    PROMPT_COMMAND="__set_title;${PROMPT_COMMAND}"
fi

# Clean up any double semicolons from other scripts (pure.bash + zoxide issue)
PROMPT_COMMAND="${PROMPT_COMMAND//;;/;}"

# ── MCP on-demand ─────────────────────────────────────
mcp() {
    case "$1" in
        on)  claude mcp add -s user "${2:?usage: mcp on <name>}" -- "${@:3}" ;;
        off) claude mcp remove -s user "${2:?usage: mcp off <name>}" ;;
        *)   echo "usage: mcp on|off <name> [-- args...]" >&2; return 1 ;;
    esac
}

# ── Command shortcuts ─────────────────────────────────
alias cld='claude'
alias uvsa='uv sync --all-packages --all-groups --all-extras'

# ── notify: send macOS notification via kitty remote control ──
notify() {
    local msg="${*:-Done}"
    if kitten @ ls &>/dev/null; then
        kitten @ launch --type=background -- osascript -e "display notification \"${msg}\" with title \"Terminal\""
    else
        echo ":: ${msg}" >&2
    fi
}

# ── SLURM shortcuts ──
h100() {
    srun --qos=dev --partition=h100 --nodes=1 --pty /bin/bash "$@"
}
