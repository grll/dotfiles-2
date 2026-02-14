# dotfiles

Kitty + tmux + git-worktree workflow for a remote dev cluster, with Claude Code integration.

**Kitty opens 4 tabs:** home, slack, notion, linear.
`Cmd+G` picks git worktrees as new tabs (local or remote via SSH). `vsc` opens VS Code on the remote. `notify` sends macOS notifications from remote. Claude Code hooks provide tab titles, desktop notifications, and Peon sound effects.

## Setup

```bash
git clone git@github.com:USERNAME/dotfiles.git ~/dotfiles
cp ~/dotfiles/config.example.sh ~/dotfiles/config.sh
vi ~/dotfiles/config.sh   # set CLUSTER (ssh host), REMOTE_REPO (repo path), LOCAL_HOME
```

**Remote** (ssh into cluster first):
```bash
~/dotfiles/remote/install.sh
# → bashrc, bin scripts, claude skills + hooks
# ⚠ follow prompts: fzf
# log out and SSH back in
```

**Local** (laptop):
```bash
~/dotfiles/local/install.sh
# → shell rc, kitty session + config, ssh.conf, gwt, claude skills + hooks
# restart kitty
```

Kitty prerequisite: `~/.config/kitty/kitty.conf` must exist (create empty if needed).

## What you get

| Feature | How | Where |
|---|---|---|
| 4-tab kitty startup | `kitty-dotfiles.conf` → `startup_session sessions/work.conf` | local |
| `kitten ssh` to cluster | `ssh.conf` — shell integration, clipboard, terminfo, remote control | local→remote |
| Tmux auto-attach on SSH | `bashrc-gwt.sh` — attaches/creates `main` session | remote |
| `Cmd+G` worktree picker | `tab-picker.sh` — fzf picker, opens worktree in a new tab (local or remote) | local |
| `Cmd+T` smart new tab | `new-tab.sh` — new tab in same dir, works for local and remote tabs | local |
| `gwt` worktree manager | `gwt <branch>`, `gwt -b`, `gwt -d`, `gwt -l` | both |
| `vsc [branch]` | Opens VS Code connected to remote worktree; auto-opens active PR | both |
| `notify [msg]` | macOS notification via `kitten @` remote control | remote |
| Cmd finish notifications | `notify_on_cmd_finish unfocused 15.0` — local tabs only | local |
| Claude Code hooks | Tab titles, desktop notifications, Peon sounds on events | both |
| Claude Code skills | `/commit` (conventional commits), `/pr` (GitHub PRs) | both |

## File map

```
config.example.sh          # CLUSTER, REMOTE_REPO, LOCAL_HOME — cp to config.sh
claude/
  claude-hooks.json         # shared hooks: tab titles, notifications, sounds
  claude-title.sh           # set terminal tab title to branch + PR number
  claude-notify.sh          # local desktop notifications via kitten notify
  claude-sound.sh           # play Peon sounds for Claude Code events
  skills/
    commit/SKILL.md         # /commit — conventional commits format
    pr/SKILL.md             # /pr — GitHub PR with structured description
sounds/
  peon-ready-to-work.mp3    # idle prompt
  peon-what-do-you-want.mp3 # permission prompt
  peon-work-complete.mp3    # task complete
  peon-whaaat.mp3           # error
local/
  install.sh               # local setup: shell rc, kitty conf, ssh.conf, claude
  bashrc-local.sh          # vsc, gwt wrapper, kitty CWD tracking, aliases
  kitty-dotfiles.conf      # remote control, notifications, startup session, keybindings
  sessions/work.conf       # kitty session: 4 tabs (home, slack, notion, linear)
  tab-picker.sh            # Cmd+G — fzf worktree picker, create/switch/delete
  new-tab.sh               # Cmd+T — smart new tab (same dir, local or remote)
  ssh.conf                 # template — install.sh generates with $CLUSTER
remote/
  install.sh               # remote setup: bashrc, bin scripts, claude
  bashrc-gwt.sh            # tmux auto-attach, smart titles, gwt, vsc, notify, aliases
  bin/vsc                  # VS Code launcher with PR auto-open
  claude-hooks.json        # remote-specific hooks (notify + sound over SSH)
  claude-notify.sh         # remote notifications via OSC 99 escape sequence
```

## Cmd+G worktree picker

The worktree picker (`tab-picker.sh`, bound to `Cmd+G`) opens an fzf overlay:

```
Enter           switch to worktree (opens in new tab)
Alt+Enter       create worktree — accepts: branch, branch@base, branch@#PR, #PR
Ctrl+D          delete worktree(s) — supports batch selection
```

Creates worktrees at `$REMOTE_REPO-<sanitized-branch>`. Symlinks `.venv` and `.claude` from main repo.

## Security note

`forward_remote_control yes` in `ssh.conf` gives the remote host full access to local kitty (launch processes, read clipboard). Only enabled for `$CLUSTER`.
