---
name: commit
description: Create a git commit following Conventional Commits 1.0.0 specification. Use this skill when the user asks to commit changes, make a commit, or save their work.
---

# Commit Command

Create a git commit with a concise message following the Conventional Commits 1.0.0 specification.

## Instructions

1. Run `git diff --staged` to see the staged changes
2. If nothing is staged, run `git diff` to see unstaged changes and stage the relevant files
3. Analyze the changes and create a commit message following the specification below

## Conventional Commits Specification

The commit message MUST follow this structure:

```
<type>[optional scope][optional !]: <description>

[optional body]

[optional footer(s)]
```

### Rules (from specification)

1. Commits MUST be prefixed with a type (feat, fix, etc.), followed by an OPTIONAL scope, an OPTIONAL exclamation mark for breaking changes, and a REQUIRED terminal colon and space
2. The type `feat` MUST be used for new feature additions
3. The type `fix` MUST be used for bug fixes
4. An optional scope MAY be provided in parentheses after the type (e.g., `fix(parser):`)
5. A description MUST immediately follow the colon and space after the type/scope prefix
6. A longer body MAY be provided after a blank line following the description
7. An exclamation mark before the colon indicates a BREAKING CHANGE
8. BREAKING CHANGE: in the footer is equivalent to the exclamation mark in the prefix
9. Additional types beyond `feat` and `fix` are permitted (e.g., `docs`, `refactor`, `test`, `chore`, `build`, `ci`, `perf`, `style`)

### Common Types

- `feat`: A new feature
- `fix`: A bug fix
- `docs`: Documentation changes
- `style`: Formatting, whitespace (no code change)
- `refactor`: Code change that neither fixes a bug nor adds a feature
- `perf`: Performance improvement
- `test`: Adding or updating tests
- `build`: Build system or dependency changes
- `ci`: CI configuration changes
- `chore`: Maintenance tasks

### Commit Message Guidelines

- Keep the description concise (ideally under 50 characters)
- Use imperative mood: "add" not "added", "fix" not "fixed"
- Do not capitalize the first letter of the description
- Do not end the description with a period

## Examples

```
feat: add user authentication endpoint
```

```
fix(api): handle null response in fetch handler
```

```
docs: update installation instructions in README
```

```
refactor: extract validation into separate module
```

```
build: upgrade pytorch to 2.1.0
```

```
feat(dataloader): add streaming dataset support
```

```
feat!: remove deprecated config options

BREAKING CHANGE: config.legacy_mode no longer supported
```

```
fix(parser): prevent infinite loop on malformed input

The parser now validates input length before processing.

Reviewed-by: Alice
Refs: #123
```

## Bad Examples (avoid these)

- `feat: Add new feature for user authentication with JWT tokens and refresh token support` - too long
- `Fixed the bug` - no type prefix, past tense, vague
- `feat: Add user auth.` - should not capitalize, should not end with period
- `updated files` - no type, vague

## Execution

After analyzing the diff, create the commit:

```bash
git commit -m "<type>[scope]: <description>"
```

Do NOT use `--no-verify` unless explicitly requested by the user.

**IMPORTANT:** Do NOT add any `Co-Authored-By` or similar trailers to the commit message.
