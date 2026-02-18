---
name: aerospace
description: Manage macOS windows and workspaces using the AeroSpace tiling window manager CLI. Use to move windows between workspaces, query layout state, arrange tiled windows, and coordinate multi-window workflows alongside kitty.
user-invocable: false
allowed-tools: Bash
---

# AeroSpace Window Management

AeroSpace is an i3-like tiling window manager for macOS. All windows are automatically tiled. You control it via the `aerospace` CLI.

## Workspace Layout

| Workspace | Monitor | Purpose |
|-----------|---------|---------|
| 1 | BenQ 1 (left) | Code: VS Code |
| 2 | BenQ 2 (middle) | Browser: Chrome |
| 3 | MacBook | Communication: Slack, Mail, Messages |
| 4 | BenQ 1 (left) | Notes: Notion |
| 5 | MacBook | Planning: Linear, Calendar |
| 6 | MacBook | Agents: Claude Code sessions |
| 9 | BenQ 2 (middle) | Terminal: Claude Code sessions (2x2) |

Kitty has **no auto-assignment rule** — new kitty OS windows land on the currently focused workspace and are tiled automatically.

## Core Patterns

### Identify yourself

Before manipulating other windows, know your own AeroSpace window ID so you never accidentally move yourself:

```bash
MY_AERO_ID=$(aerospace list-windows --focused --format '%{window-id}')
```

### Query windows

```bash
# All windows (human-readable)
aerospace list-windows --all --format '%{window-id}|%{app-name}|%{window-title}|%{workspace}'

# All kitty windows
aerospace list-windows --all --app-bundle-id net.kovidgoyal.kitty \
  --format '%{window-id}|%{window-title}|%{workspace}'

# Windows on a specific workspace
aerospace list-windows --workspace 9 --format '%{window-id}|%{app-name}|%{window-title}'

# Count windows on a workspace
aerospace list-windows --workspace 9 --count

# JSON output for complex parsing
aerospace list-windows --all --json
```

### Move a newly launched kitty window to a workspace

When the kitty skill launches an OS window, it lands on the focused workspace. To move it elsewhere:

```bash
# 1. Snapshot existing kitty window IDs
BEFORE=$(aerospace list-windows --all --app-bundle-id net.kovidgoyal.kitty --format '%{window-id}')

# 2. Launch the kitty window (from kitty skill)
KITTY_WIN_ID=$(kitten @ launch --type=os-window --keep-focus --hold \
  --title "my-task" -- bash -c 'your-command')

# 3. Wait for AeroSpace to register it
sleep 0.5

# 4. Find the new AeroSpace window ID (the one not in BEFORE)
AERO_WIN_ID=$(aerospace list-windows --all --app-bundle-id net.kovidgoyal.kitty \
  --format '%{window-id}' | grep -v -F "$BEFORE" | head -1 | tr -d ' ')

# 5. Move to target workspace (does NOT move focus)
aerospace move-node-to-workspace --window-id "$AERO_WIN_ID" 9
```

For simpler cases where the title is unique, find by title directly:

```bash
sleep 0.5
AERO_WIN_ID=$(aerospace list-windows --all --app-bundle-id net.kovidgoyal.kitty \
  --format '%{window-id}|%{window-title}' | grep "my-task" | head -1 | cut -d'|' -f1 | tr -d ' ')
aerospace move-node-to-workspace --window-id "$AERO_WIN_ID" 9
```

### Distribute multiple windows across workspaces

When launching several kitty windows (e.g., via orchestrate), move them to the right workspace:

```bash
# Launch 3 agent windows, collect their AeroSpace IDs, move to workspace 9
for branch in feat/api feat/ui feat/tests; do
  KITTY_ID=$(kitten @ launch --type=os-window --keep-focus --hold \
    --title "agent-$branch" -- bash)
  sleep 0.5
  AERO_ID=$(aerospace list-windows --all --app-bundle-id net.kovidgoyal.kitty \
    --format '%{window-id}|%{window-title}' | grep "agent-$branch" | head -1 | cut -d'|' -f1 | tr -d ' ')
  aerospace move-node-to-workspace --window-id "$AERO_ID" 9
done

# Balance all windows on workspace 9 to equal sizes
aerospace balance-sizes --workspace 9
```

### Change layout

```bash
# Toggle tiling direction on current workspace
aerospace layout tiles horizontal vertical

# Set a specific window to vertical tiles
aerospace layout --window-id "$AERO_WIN_ID" v_tiles

# Switch to accordion (stacked, one visible at a time)
aerospace layout accordion horizontal vertical

# Balance all window sizes on a workspace
aerospace balance-sizes --workspace 9
```

### Resize windows

```bash
# Resize a specific window
aerospace resize --window-id "$AERO_WIN_ID" width +200
aerospace resize --window-id "$AERO_WIN_ID" height -100

# Smart resize (grows in the "natural" direction)
aerospace resize --window-id "$AERO_WIN_ID" smart +100
```

### Focus a specific window

```bash
# Focus by AeroSpace window ID (switches workspace automatically)
aerospace focus --window-id "$AERO_WIN_ID"

# Directional focus (within current workspace)
aerospace focus left
aerospace focus right
```

### Rearrange window position within a workspace

```bash
# Move a window directionally within its workspace
aerospace move --window-id "$AERO_WIN_ID" left
aerospace move --window-id "$AERO_WIN_ID" right
```

### Query workspaces and monitors

```bash
# Which workspace am I on?
aerospace list-workspaces --focused --format '%{workspace}'

# Non-empty workspaces
aerospace list-workspaces --all --format '%{workspace}' --empty no

# Workspaces on a specific monitor
aerospace list-workspaces --monitor 2 --format '%{workspace}'

# List monitors
aerospace list-monitors --format '%{monitor-id}|%{monitor-name}'
```

## Command Reference

| Command | Key flags | Description |
|---------|-----------|-------------|
| `list-windows` | `--all`, `--workspace W`, `--focused`, `--app-bundle-id`, `--format`, `--json`, `--count` | Query windows |
| `list-workspaces` | `--all`, `--focused`, `--monitor M`, `--empty [no]`, `--format` | Query workspaces |
| `list-monitors` | `--format` | Query monitors |
| `move-node-to-workspace` | `--window-id ID`, `--focus-follows-window` | Move window to workspace |
| `layout` | `--window-id ID`, `h_tiles\|v_tiles\|tiles\|accordion\|floating` | Change layout |
| `balance-sizes` | `--workspace W` | Equalize window sizes |
| `resize` | `--window-id ID`, `smart\|width\|height`, `+/-N` | Resize window |
| `focus` | `--window-id ID`, `left\|right\|up\|down` | Focus window or direction |
| `move` | `--window-id ID`, `left\|right\|up\|down` | Reorder window in tiling |
| `workspace` | name or `next\|prev` | Switch workspace |
| `flatten-workspace-tree` | — | Reset layout nesting |

Format variables: `%{window-id}`, `%{app-name}`, `%{window-title}`, `%{workspace}`, `%{monitor-id}`, `%{monitor-name}`.

## Rules

- **Never move the focused window** unless explicitly asked — that's your own Claude Code session. Always use `--window-id` targeting a different window.
- **Always use `--window-id`** for `move-node-to-workspace`, `layout`, `resize`, and `move` when acting on other windows. Without it, the command acts on the focused window (yours).
- **`move-node-to-workspace` does NOT follow focus** by default — this is what you want. Only add `--focus-follows-window` if you intend to switch to that workspace.
- **Use `balance-sizes`** after adding or removing windows on a workspace to restore equal tiling.
- **New kitty OS windows land on the focused workspace** since kitty has no auto-assignment rule. Move them with the snapshot pattern above if they belong elsewhere.
- **Prefer workspace 9** for terminal/agent windows and **workspace 6** for additional agent sessions, matching the user's layout conventions.
- **`sleep 0.5`** after `kitten @ launch` before querying AeroSpace — the window needs time to register.
- **Kitty app bundle ID** is `net.kovidgoyal.kitty` — use this with `--app-bundle-id` to filter.
