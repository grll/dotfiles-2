#!/bin/bash
# Send desktop notification via Kitty OSC 99 (works over SSH)
# Receives Claude Code hook JSON on stdin

[[ -z "$SSH_TTY" ]] && exit 0

input=$(cat)
type=$(echo "$input" | jq -r '.notification_type // ""')
dir=$(basename "$(echo "$input" | jq -r '.cwd // ""')")

case "$type" in
    permission_prompt) msg="Waiting for permission in $dir" ;;
    idle_prompt) msg="Ready for input in $dir" ;;
    *) msg="$type in $dir" ;;
esac

printf '\e]99;;%s\e\\' "$msg" > "$SSH_TTY"
