#!/bin/bash
# Send silent notification for Claude Code events
# Detects context (local vs SSH) and uses the appropriate delivery mechanism:
# - Local: kitten notify
# - Remote (SSH): Kitty OSC 99 escape sequences

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

if [[ -n "$SSH_TTY" ]]; then
    # Silent notification via Kitty OSC 99 (s=c2lsZW50 is Base64 for "silent")
    printf '\e]99;s=c2lsZW50;;%s\e\\' "$msg" > "$SSH_TTY"
else
    # Silent notification using kitten notify (--sound silent suppresses system sound)
    kitten notify --sound silent "Claude Code" "$msg"
fi
