---
name: branch
description: Create a new git branch with a descriptive name. Takes an optional description to convert into a branch name, or infers the name from current unstaged changes. Invoke when the user wants to create a branch, start a new feature, or begin work on a task.
argument-hint: "[description of the work]"
disable-model-invocation: true
---

# Create a New Branch

Create and switch to a new git branch named `guillaumeraille/<short-description>`.

## Step 1: Determine the branch name

### If the user provided a description (`$ARGUMENTS` is non-empty)

Convert the description into a short, hyphen-separated branch name:

1. Extract the core intent in 2-5 words.
2. Use lowercase, hyphen-separated words.
3. Strip filler words (the, a, an, for, with, and, to, in, on, of) unless they are essential to meaning.
4. Use imperative mood: `add-auth`, not `adding-auth` or `added-auth`.

### If no description was provided

1. Run `git diff` to inspect unstaged changes.
2. If there are no unstaged changes, run `git diff --staged` to check staged changes.
3. If there are still no changes, stop and ask the user to describe the work.
4. Analyze the diff and infer a 2-5 word summary of what the changes accomplish.

## Step 2: Format the branch name

The final branch name MUST follow this format:

```
guillaumeraille/<2-5-hyphenated-words>
```

Rules:
- Always prefix with `guillaumeraille/`.
- Use 2-5 lowercase words separated by hyphens.
- No special characters, no uppercase, no underscores.
- Be specific: `add-jwt-auth` not `update-code`.
- No type prefixes like `feat/` or `fix/` — just describe the change.

Examples:

| Description | Branch name |
|---|---|
| "Add dark mode support to the settings page" | `guillaumeraille/add-dark-mode-settings` |
| "Fix the race condition in batch API" | `guillaumeraille/fix-batch-race-condition` |
| "Refactor database connection pooling" | `guillaumeraille/refactor-db-connection-pooling` |
| "Update README with install instructions" | `guillaumeraille/update-readme-install` |
| *(inferred from diff adding tests)* | `guillaumeraille/add-unit-tests` |

## Step 3: Create and switch to the branch

```bash
git checkout -b guillaumeraille/<branch-name>
```

## Step 4: Confirm

Display:
- The branch name that was created.
- A one-line summary of what the branch is for.
