#!/bin/bash
# Send silent notification for local Claude Code events using kitten notify
# Remote uses remote/claude-notify.sh with Kitty OSC 99

[[ -n "$SSH_TTY" ]] && exit 0  # Skip on remote (handled by remote/claude-notify.sh)

input=$(cat)
hook_event=$(echo "$input" | jq -r '.hook_event_name // ""')
notification_type=$(echo "$input" | jq -r '.notification_type // ""')
dir=$(basename "$(echo "$input" | jq -r '.cwd // ""')")

case "$hook_event" in
    Notification)
        case "$notification_type" in
            permission_prompt) msg="Waiting for permission in $dir" ;;
            idle_prompt) msg="Ready for input in $dir" ;;
            *) exit 0 ;;
        esac
        ;;
    Stop)
        msg="Task complete in $dir"
        ;;
    PostToolUseFailure)
        msg="Error in $dir"
        ;;
    *)
        exit 0
        ;;
esac

# Silent notification using kitten notify (--sound silent suppresses system sound)
kitten notify --sound silent "Claude Code" "$msg"
