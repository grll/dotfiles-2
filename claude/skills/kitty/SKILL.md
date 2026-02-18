---
name: kitty
description: Control kitty terminal programmatically via kitten @ remote control. Use to launch windows, run interactive commands, send/receive text, and manage terminal sessions. Handles the constraint that Claude Code has no interactive TTY.
user-invocable: false
allowed-tools: Bash
---

# Kitty Remote Control

You run inside kitty but have **no interactive TTY**. You cannot run interactive programs (REPLs, TUIs, prompts, pagers) directly. Work around this by using `kitten @` to launch separate windows and interact with them.

The environment provides `KITTY_LISTEN_ON` — all `kitten @` commands use it automatically.

## Core Patterns

### Run a command and capture output

Use `--hold` to keep the window open after the command exits so you can read the output.

```bash
# Launch, capture window ID for reliable matching
WINDOW_ID=$(kitten @ launch --type=os-window --keep-focus --hold \
  -- bash -c 'your-command-here')

# Wait for completion, then read output
sleep 2
kitten @ get-text --match "id:$WINDOW_ID" --extent=all

# Clean up
kitten @ close-window --match "id:$WINDOW_ID" --no-response
```

To detect completion, poll for a sentinel or check if the original process is still alive:

```bash
# Sentinel approach: append a marker after the command
WINDOW_ID=$(kitten @ launch --type=os-window --keep-focus --hold \
  -- bash -c 'your-command; echo "::DONE rc=$?"')

# Poll until sentinel appears
while true; do
  OUTPUT=$(kitten @ get-text --match "id:$WINDOW_ID" --extent=all)
  if echo "$OUTPUT" | grep -q "::DONE"; then break; fi
  sleep 1
done

kitten @ close-window --match "id:$WINDOW_ID" --no-response
```

### Interactive session (REPL, shell)

```bash
# Launch a persistent REPL
WINDOW_ID=$(kitten @ launch --type=os-window --keep-focus -- python3)

# Send commands — use $'...\n' to press Enter
kitten @ send-text --match "id:$WINDOW_ID" $'print("hello world")\n'

# Wait for output, then read screen
sleep 1
kitten @ get-text --match "id:$WINDOW_ID"

# Send more, read more, etc.

# Close when done
kitten @ close-window --match "id:$WINDOW_ID" --no-response
```

### Monitor a long-running process

```bash
WINDOW_ID=$(kitten @ launch --type=os-window --keep-focus --hold \
  -- bash -c 'cd /path && npm test')

# Poll output periodically
kitten @ get-text --match "id:$WINDOW_ID" --extent=all

# Check if the original process is still running
kitten @ ls | jq --arg id "$WINDOW_ID" \
  '[.[] | .tabs[] | .windows[] | select(.id == ($id | tonumber)) | .foreground_processes[].pid] | length'
```

### Named windows for cross-session reference

For long-lived or well-known windows, tag with `--var` for matching by name instead of ID:

```bash
kitten @ launch --type=os-window --keep-focus \
  --var "claude_session=devserver" \
  -- bash -c 'npm run dev'

# Later, from anywhere:
kitten @ get-text --match "var:claude_session=devserver" --extent=all
kitten @ send-text --match "var:claude_session=devserver" $'rs\n'
```

This repo's convention: `--var "worktree=$PATH"` for worktree-based windows.

## Command Reference

### launch

```bash
kitten @ launch [options] [-- command args...]
```

| Flag | Description |
|------|-------------|
| `--type=os-window` | New OS window (use this for AeroSpace tiling) |
| `--type=tab` | New tab in current OS window |
| `--type=overlay` | Overlay on current window |
| `--type=background` | Run without a window (for scripts) |
| `--keep-focus` | Don't steal focus from current window |
| `--hold` | Keep window open after command exits |
| `--title "name"` | Set window title |
| `--cwd /path` | Set working directory |
| `--var "key=value"` | Set user variable for matching |
| `--env "KEY=value"` | Set environment variable |

Returns the window ID on stdout.

### send-text

```bash
# Inline (use $'...\n' for Enter)
kitten @ send-text --match "id:$ID" $'command\n'

# From stdin
echo "command" | kitten @ send-text --match "id:$ID" --stdin

# Multi-line paste (bracketed paste mode)
kitten @ send-text --match "id:$ID" --bracketed-paste $'line1\nline2\n'
```

### send-key

```bash
kitten @ send-key --match "id:$ID" Enter
kitten @ send-key --match "id:$ID" ctrl+c
kitten @ send-key --match "id:$ID" Up Up Enter
```

### get-text

```bash
kitten @ get-text --match "id:$ID"
```

| `--extent` value | What it returns |
|------------------|----------------|
| `screen` (default) | Visible screen content |
| `all` | Screen + scrollback buffer |
| `last_cmd_output` | Last command's output (needs shell integration) |
| `last_non_empty_output` | Last non-empty output (needs shell integration) |
| `selection` | Currently selected text |

Omit `--ansi` to get plain text (easier to parse). Add `--ansi` only if you need formatting codes.

### ls

```bash
# Full JSON tree: OS windows → tabs → windows
kitten @ ls

# Find windows by user var
kitten @ ls | jq '.[] | .tabs[] | .windows[] | select(.user_vars.worktree != null)'

# Get focused window
kitten @ ls | jq '.[] | .tabs[] | .windows[] | select(.is_focused)'

# Check if a window still exists
kitten @ ls | jq --arg id "$WINDOW_ID" \
  '[.[] | .tabs[] | .windows[] | select(.id == ($id | tonumber))] | length'
```

### Window lifecycle

```bash
kitten @ focus-window --match "id:$ID"
kitten @ close-window --match "id:$ID" --no-response
kitten @ set-window-title --match "id:$ID" "New Title"
```

## Window Matching

Use `--match` to target windows. Combine with `and`, `or`, `not`, and parentheses.

| Field | Example |
|-------|---------|
| `id` | `id:42` |
| `var` | `var:claude_session=repl` |
| `title` | `title:python` (regex) |
| `cwd` | `cwd:/path/to/dir` |
| `pid` | `pid:12345` |
| `state` | `state:focused` |
| `env` | `env:VIRTUAL_ENV=/path` |

Compound: `"var:claude_session=repl and title:python"`

**Prefer window ID** (`id:$WINDOW_ID`) for ephemeral windows — it's returned by `launch` and is guaranteed unique. Use `var:` matching for long-lived or well-known windows.

## SSH to remote hosts

When SSHing to remote hosts, **always use `kitten ssh` instead of `ssh`**. This copies kitty's terminfo and shell integration to the remote, avoiding broken terminal features (e.g., `--extent=last_cmd_output` won't work without it).

```bash
# Interactive SSH session
WINDOW_ID=$(kitten @ launch --type=os-window --keep-focus \
  -- kitten ssh rno)

# One-shot command on remote
WINDOW_ID=$(kitten @ launch --type=os-window --keep-focus --hold \
  -- kitten ssh rno "cd /path && your-command; echo '::DONE'")
```

This applies everywhere — `kitten @ launch -- kitten ssh ...`, not `kitten @ launch -- ssh ...`.

## Rules

- **Always use `kitten ssh`** instead of `ssh` when connecting to remote hosts.
- **Always use `--keep-focus`** when launching — stay in your own terminal.
- **Always use `--no-response`** on `close-window` — avoids errors if already closed.
- **Always use `--hold`** if you need to read output after a process exits — otherwise the window disappears immediately.
- **Use `--type=os-window`** for AeroSpace tiling compatibility, not `tab`.
- **Capture the window ID** from `launch` stdout and use `id:$WINDOW_ID` for matching. Fall back to `--var` for named sessions.
- **Poll with `get-text`** — there's no push notification for command completion. Use a sentinel marker or poll every 1-2s.
- **Check window existence** before `send-text` / `get-text` if the process might have exited without `--hold`.
- **Use `$'...\n'`** in send-text to include newlines. `\r` also works to press Enter.
- **Never use `--ansi`** with `get-text` unless you specifically need ANSI codes — plain text is easier to parse.
- **Use `--extent=last_cmd_output`** when available (shell integration required in target) to get just the relevant output instead of the entire scrollback.
