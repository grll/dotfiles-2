#!/bin/bash
# Send desktop notification via Kitty OSC 99 (works over SSH)
# Receives Claude Code hook JSON on stdin

input=$(cat)
notification_type=$(echo "$input" | jq -r '.notification_type // "notification"')
cwd=$(echo "$input" | jq -r '.cwd // ""')
dir=$(basename "$cwd")

# Map notification types to user-friendly messages
case "$notification_type" in
    permission_prompt)
        title="Claude Code"
        body="Waiting for permission in $dir"
        ;;
    idle_prompt)
        title="Claude Code"
        body="Ready for input in $dir"
        ;;
    *)
        title="Claude Code"
        body="$notification_type in $dir"
        ;;
esac

# Base64 encode for OSC 99
title_b64=$(echo -n "$title" | base64 -w0)
body_b64=$(echo -n "$body" | base64 -w0)
sound_b64=$(echo -n "system" | base64 -w0)

# Send OSC 99 notification with sound
# i=claude-notify: notification id
# e=1: payload is base64 encoded
# s=: sound name (base64)
# d=0/1: done flag (0=more coming, 1=complete)
printf '\033]99;i=claude-notify:e=1:d=0:p=title;%s\033\\' "$title_b64"
printf '\033]99;i=claude-notify:e=1:d=0:p=body;%s\033\\' "$body_b64"
printf '\033]99;i=claude-notify:e=1:s=%s:d=1;;\033\\' "$sound_b64"
