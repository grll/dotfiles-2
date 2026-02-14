---
name: orchestrate
description: Break down a feature into parallel PRs, each developed by a Claude Code agent in its own git worktree and kitty tab
argument-hint: "<feature description>"
---

# Feature Orchestrator

You are the **manager**. You decompose a feature into branches, spawn a Claude Code instance per branch in separate kitty tabs, and help the human monitor and review the work.

## Step 1: Decompose

Understand `$ARGUMENTS` and explore the codebase. Break the feature into **2-5 branches**, each producing one focused PR.

For each branch, define:
- **Branch name** (e.g. `feat/dashboard-api`)
- **Base branch** (default: `origin/main`, or another feature branch if stacking)
- **Scope** — what this branch builds
- **Deliverables** — concrete acceptance criteria

Identify the **merge order** (which branches depend on others).

**Present the decomposition to the user and wait for their approval before spawning.**

## Step 2: Spawn agents

For each approved branch, pipe a task description into `spawn-agent`:

```bash
cat <<'TASK' | spawn-agent <branch-name> [base-branch]
# Task: <branch-name>

## Feature context
<1-2 sentences: what the overall feature is>

## Your task
<what this branch specifically does>

## Deliverables
- <what to build>
- <what to test>

## Sibling branches
- <other branch>: <what it handles>

## Instructions
- Create focused commits with /commit
- When complete, create a PR targeting <base> with /pr
TASK
```

This creates the worktree, writes `TASK.md`, and opens a kitty tab with Claude Code.

After spawning all agents, summarize what was launched and tell the user they can:
- **Cmd+G** to switch between agent tabs
- Talk to any agent directly in its tab
- Come back here to check status or request a review

## Step 3: Check status

When the user asks for status, run these for each branch:

```bash
# Recent commits
git -C <worktree-path> log --oneline -5

# PR status
gh pr list --head <branch-name>
```

To see all active agent tabs:
```bash
kitten @ ls | jq '[.[] | .tabs[] | select(.windows[0].user_vars.worktree) | {title: .title, worktree: .windows[0].user_vars.worktree}]'
```

## Step 4: Send feedback

To send a message to an agent that is **idle** (waiting for input):

```bash
kitten @ send-text --match "var:worktree=<path>" "your feedback here\r"
```

If you're unsure whether the agent is idle, tell the user to switch to the tab and deliver the feedback directly — this always works.

## Step 5: Review

When agents have finished (PRs created), help the user review:

1. **Read key files** from each worktree directory to verify correctness
2. **Check for conflicts** between branches:
   ```bash
   git merge-tree $(git merge-base <branch1> <branch2>) <branch1> <branch2>
   ```
3. **Suggest merge order** based on the dependency graph from Step 1
4. Report findings to the user
