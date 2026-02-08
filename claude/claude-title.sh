#!/bin/bash
# Set/restore tab title for Claude Code sessions
# Called by SessionStart and SessionEnd hooks

input=$(cat)
event=$(echo "$input" | jq -r '.hook_event_name // ""')
cwd=$(echo "$input" | jq -r '.cwd // ""')

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

case "$event" in
    SessionStart)
        if [[ -n "$branch" && "$branch" != "HEAD" ]]; then
            title=$(format_branch "$branch")
            pr=$(get_pr "$branch")
            [[ -n "$pr" && "$pr" != "0" ]] && title="$title #$pr"
            printf '\033]0;CC: %s\007' "$title"
        else
            # Fallback: show directory name
            printf '\033]0;CC: %s\007' "$(basename "$cwd")"
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
                printf '\033]0;%s:%s\007' "$CLUSTER" "$title"
            else
                printf '\033]0;%s\007' "$title"
            fi
        else
            printf '\033]0;%s\007' "$(basename "$cwd")"
        fi
        ;;
esac
