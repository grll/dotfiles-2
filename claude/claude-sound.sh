#!/bin/bash
# Play Peon sounds for Claude Code events

SOUNDS_DIR="$HOME/dotfiles/sounds"

input=$(cat)
echo "$(date): $input" >> /tmp/claude-hook-debug.log
hook_event=$(echo "$input" | jq -r '.hook_event_name // ""')
notification_type=$(echo "$input" | jq -r '.notification_type // ""')

case "$hook_event" in
    Notification)
        case "$notification_type" in
            permission_prompt) sound="peon-what-do-you-want.mp3" ;;
            idle_prompt) sound="peon-ready-to-work.mp3" ;;
        esac
        ;;
    Stop)
        sound="peon-work-complete.mp3"
        ;;
    PostToolUseFailure)
        sound="peon-whaaat.mp3"
        ;;
esac

[[ -z "$sound" ]] && exit 0
sound_path="$SOUNDS_DIR/$sound"
[[ ! -f "$sound_path" ]] && exit 0

if [[ -n "$SSH_TTY" ]]; then
    kitten @ launch --type=background -- /usr/bin/afplay "$sound_path" 2>/dev/null
else
    afplay "$sound_path" &
fi
