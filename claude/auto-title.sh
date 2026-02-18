#!/bin/bash
# Auto-generate session title from first user prompt using Haiku
# Called by UserPromptSubmit hook
# Sets both the kitty tab title and the Claude Code session name

# Env vars (CLAUDE_CODE_USE_VERTEX, etc.) are inherited from parent shell.
# Just ensure claude CLI is in PATH.
export PATH="$HOME/.local/bin:$PATH"

# Guard against recursive invocation: the child `claude -p` triggers
# UserPromptSubmit again, which would re-run this script infinitely.
[[ -n "${_AUTO_TITLE_RUNNING:-}" ]] && exit 0
export _AUTO_TITLE_RUNNING=1

input=$(cat)
session_id=$(echo "$input" | jq -r '.session_id // ""')
transcript=$(echo "$input" | jq -r '.transcript_path // ""')
prompt=$(echo "$input" | jq -r '.prompt // ""')

# Skip if missing data
[[ -z "$prompt" || -z "$session_id" || -z "$transcript" ]] && exit 0

# Skip short prompts (likely confirmations like "y", "ok", etc.)
[[ ${#prompt} -lt 10 ]] && exit 0

# Skip if session already has a custom title
grep -q '"custom-title"' "$transcript" 2>/dev/null && exit 0

# Run in background to avoid blocking prompt processing
(
    # Use claude CLI with haiku to generate a short title
    # Unset CLAUDECODE to allow running from within a Claude Code session
    truncated=$(echo "$prompt" | head -c 500)
    title=$(CLAUDECODE= claude -p --model haiku \
        "Generate a 2-4 word lowercase title summarizing this task, with words separated by hyphens. Reply with ONLY the title, no quotes, no explanation. Examples: fix-auth-bug, add-jwt-tokens, refactor-db-queries

Task: $truncated" 2>/dev/null)

    [[ -z "$title" ]] && exit 0

    # Clean up: trim whitespace, remove surrounding quotes/punctuation
    title=$(echo "$title" | sed 's/^[""'"'"']*//;s/[""'"'"']*$//' | xargs)
    [[ -z "$title" ]] && exit 0

    # Append custom-title to session JSONL (same format as /rename)
    jq -nc --arg t "$title" --arg s "$session_id" \
        '{type: "custom-title", customTitle: $t, sessionId: $s}' >> "$transcript"

    # Update kitty tab title
    printf '\033]0;CC: %s\007' "$title" > /dev/tty 2>/dev/null
) &

exit 0
