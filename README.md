# dotfiles

Kitty + tmux + git-worktree workflow for a remote dev cluster.

**Kitty opens 4 tabs:** remote (kitten ssh → tmux), local shell, notion (Claude), linear (Claude).
On the remote, `gwt` manages git worktrees as tmux sessions. `vsc` opens VS Code locally from inside remote tmux. `notify` sends macOS notifications from remote.

## Setup

```bash
git clone git@github.com:USERNAME/dotfiles.git ~/dotfiles
cp ~/dotfiles/config.example.sh ~/dotfiles/config.sh
vi ~/dotfiles/config.sh   # set CLUSTER (ssh host) and REMOTE_REPO (repo path)
```

**Remote** (ssh into cluster first):
```bash
~/dotfiles/remote/install.sh
# → gwt, completion, tmux.conf, bashrc block
# ⚠ follow prompts: PATH, fzf, tmux
# log out and SSH back in
```

**Local** (laptop):
```bash
~/dotfiles/local/install.sh
# → vsc/gwt in shell rc, kitty session, kitty dotfiles.conf (remote control +
#   notifications + startup session), ssh.conf (forward_remote_control for $CLUSTER),
#   include directive in kitty.conf
# restart kitty
```

Kitty prerequisite: `~/.config/kitty/kitty.conf` must exist (create empty if needed).

## What you get

| Feature | How | Where |
|---|---|---|
| 4-tab kitty startup | `kitty-dotfiles.conf` → `startup_session sessions/work.conf` | local |
| `kitten ssh` to cluster | `kitty-work.conf` — shell integration, clipboard, terminfo, remote control | local→remote |
| Tmux auto-attach on SSH | `bashrc-gwt.sh` — attaches/creates `main` session | remote |
| `gwt` worktree manager | `gwt <branch>`, `gwt -b <branch>`, `gwt -d <branch>`, `gwt -l` | both |
| `vsc [branch]` | Opens VS Code connected to remote dir; no args = cwd, with arg = worktree | both (local: `bashrc-local.sh`, remote: `bashrc-gwt.sh`) |
| `notify [msg]` | macOS notification via `kitten @` remote control | remote (tmux) |
| Cmd finish notifications | `notify_on_cmd_finish unfocused 15.0` — local tabs only | local |
| Kitty passthrough in tmux | `allow-passthrough on` in `tmux.conf` — enables clipboard/notifications through tmux | remote |

## File map

```
config.example.sh          # CLUSTER, REMOTE_REPO — cp to config.sh
local/
  install.sh               # local setup: symlinks, kitty conf, ssh.conf generation
  bashrc-local.sh          # vsc (local version), gwt wrapper with cd
  kitty-dotfiles.conf      # remote control, notify_on_cmd_finish, startup_session
  kitty-work.conf          # kitty session: 4 tabs (remote, local, notion, linear)
  ssh.conf                 # template — install.sh generates real one with $CLUSTER
remote/
  install.sh               # remote setup: gwt, completion, tmux, bashrc
  bashrc-gwt.sh            # tmux auto-attach, gwt completion, vsc, notify
  tmux.conf                # prefix C-a, mouse, fzf session picker, passthrough
  gwt                      # git worktree ↔ tmux session manager
  gwt-completion.bash      # bash completion for gwt
```

## gwt usage

```
gwt                       # fzf pick session (remote) or worktree (local)
gwt <branch>              # switch to existing worktree/session
gwt -b <branch> [base]    # create worktree + session (default base: origin/main)
gwt -d <branch>           # remove worktree + kill session
gwt -l                    # list worktrees + sessions
```

Creates worktrees at `$REMOTE_REPO-<sanitized-branch>`. Symlinks `.venv` and `.claude` from main repo. On remote, each worktree gets its own tmux session.

## Security note

`forward_remote_control yes` in `ssh.conf` gives the remote host full access to local kitty (launch processes, read clipboard). Only enabled for `$CLUSTER`.
