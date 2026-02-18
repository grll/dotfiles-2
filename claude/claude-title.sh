#!/bin/bash
# Set/restore tab title for Claude Code sessions
# Called by SessionStart and SessionEnd hooks

input=$(cat)
event=$(echo "$input" | jq -r '.hook_event_name // ""')
cwd=$(echo "$input" | jq -r '.cwd // ""')

session_name=$(echo "$input" | jq -r '.session_name // ""')

cd "$cwd" 2>/dev/null || exit 0

# Get branch info
branch=$(git rev-parse --abbrev-ref HEAD 2>/dev/null)

# Format branch (extract ticket ID like SOL-3295)
format_branch() {
    local b="$1"
    b="${b#*/}"  # Strip user/ prefix
    if [[ "$b" =~ ^([a-zA-Z]+-[0-9]+) ]]; then
        echo "${BASH_REMATCH[1]^^}"
    else
        echo "$b"
    fi
}

# Get cached PR number (non-blocking)
get_pr() {
    local b="$1"
    local cache="$HOME/.cache/tab-title/${b//\//__}"
    [[ -f "$cache" ]] && cat "$cache"
}

# Output to /dev/tty to bypass Claude's stdout capture
set_title() {
    printf '\033]0;%s\007' "$1" > /dev/tty 2>/dev/null || true
}

case "$event" in
    SessionStart)
        # Prefer session name (set by /rename or auto-title) for resumed sessions
        if [[ -n "$session_name" ]]; then
            set_title "CC: $session_name"
        elif [[ -n "$branch" && "$branch" != "HEAD" ]]; then
            title=$(format_branch "$branch")
            pr=$(get_pr "$branch")
            [[ -n "$pr" && "$pr" != "0" ]] && title="$title #$pr"
            set_title "CC: $title"
        else
            # Fallback: show directory name
            set_title "CC: $(basename "$cwd")"
        fi
        ;;

    SessionEnd)
        # Restore normal title
        if [[ -n "$branch" && "$branch" != "HEAD" ]]; then
            title=$(format_branch "$branch")
            pr=$(get_pr "$branch")
            [[ -n "$pr" && "$pr" != "0" ]] && title="$title #$pr"
            # Remote: prefix with cluster, Local: just title
            if [[ -n "${CLUSTER:-}" ]]; then
                set_title "$CLUSTER:$title"
            else
                set_title "$title"
            fi
        else
            set_title "$(basename "$cwd")"
        fi
        ;;
esac
