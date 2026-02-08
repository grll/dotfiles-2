---
name: pr
description: Create a GitHub pull request with a well-crafted title and description by analyzing the current branch's changes. Invoke when the user wants to open a PR, submit their work for review, or push and create a pull request.
argument-hint: "[target-branch]"
disable-model-invocation: true
allowed-tools: Bash(git *), Bash(gh *)
---

# Create a Pull Request

Create a GitHub pull request for the current branch, targeting `$ARGUMENTS` if provided (default: the repo's default branch).

## Prerequisites check

Before anything, verify the environment is ready:

```
gh auth status
```

If `gh` is not authenticated, stop and tell the user to run `gh auth login`.

## Step 1: Determine branches and gather raw context

1. **Identify the current branch**:
   ```
   git branch --show-current
   ```
   If on `main` or the default branch, stop and tell the user to create a feature branch first.

2. **Determine the target branch**:
   - If the user passed an argument (`$ARGUMENTS`), use it as the target branch.
   - Otherwise, detect the repo default branch:
     ```
     gh repo view --json defaultBranchRef --jq '.defaultBranchRef.name'
     ```

3. **Ensure the branch is pushed and up to date**:
   ```
   git push -u origin HEAD
   ```

4. **Gather the diff against the target branch** (this is your primary input for writing the description):
   ```
   git diff <target-branch>...HEAD
   ```
   If the diff is very large (>5000 lines), also use a stat summary to get an overview first:
   ```
   git diff <target-branch>...HEAD --stat
   ```
   Then selectively read the most important files from the full diff.

5. **Gather the commit history on this branch**:
   ```
   git log <target-branch>..HEAD --format="%h %s%n%b" --no-merges
   ```

6. **Check for an existing PR template** in the repo:
   ```
   cat .github/pull_request_template.md 2>/dev/null || cat .github/PULL_REQUEST_TEMPLATE.md 2>/dev/null || echo "No PR template found"
   ```

## Step 2: Analyze the changes

Before writing anything, study the diff carefully and identify:

- **What category of change is this?** (feature, bug fix, refactor, docs, tests, chore, performance, CI, etc.)
- **What is the high-level intent?** Why do these changes exist? What problem do they solve?
- **What are the key modifications?** Group related file changes by concept (not by filename).
- **Are there breaking changes?** API changes, config changes, migration requirements, removed functionality.
- **Are there notable design decisions?** Trade-offs made, alternatives rejected, patterns adopted.
- **What testing was done?** New tests added, existing tests modified, test coverage gaps.

## Step 3: Write the PR title

Follow **Conventional Commits** format:

```
<type>(<scope>): <concise description>
```

Rules for the title:
- **type**: one of `feat`, `fix`, `docs`, `test`, `refactor`, `perf`, `chore`, `ci`, `style`, `build`, `revert`
- **scope**: optional, the area/module affected (e.g., `auth`, `api`, `db`, `ui`)
- **description**: imperative mood, lowercase, no period, max ~60 chars
- Be specific about *what* changed, not just *where*

Examples:
- `feat(auth): add stateless JWT session handling`
- `fix(api): prevent race condition in batch endpoint`
- `refactor(db): extract query builder into dedicated module`
- `update code`
- `fix bug`
- `WIP`

If there is a BREAKING CHANGE, append an exclamation mark after the type/scope, like `feat(api)!: redesign pagination response format`

## Step 4: Write the PR description

Write the description as **conversational prose aimed at a reviewer who lacks context**. The description must be self-contained — a reader should understand the change without opening the diff or a ticket.

### Structure

Use this structure, but **omit sections that don't apply** (e.g., skip "Screenshots" for backend-only changes, skip "Breaking Changes" if there are none). Don't include empty sections.

```markdown
## Summary
<!-- 2-5 sentences: what this PR does and why. This is the most important section. -->

## Changes
<!-- What specifically changed, grouped by concept. Use prose, not file lists. -->

## Motivation
<!-- Why this change? Previous behavior vs new behavior. Alternatives considered. -->
<!-- Omit if the Summary already covers the "why" sufficiently. -->

## How to Test
<!-- Step-by-step: commands to run, pages to visit, expected outcomes. -->

## Breaking Changes
<!-- Only if applicable. What breaks, migration steps, who is affected. -->

## Notes
<!-- Deployment steps, open questions, known limitations, follow-up work. -->
```

### Writing rules

- **Summary** is mandatory. Lead with the *what* and *why* in 2-5 clear sentences. This is the section most people will read.
- **Show, don't just tell**: include code snippets, CLI output examples, or API request/response samples when they clarify the change.
- **Group changes by concept**, not by file. If a feature touches models, views, and tests, describe the feature once — don't list each file.
- **Explain the "why"**: rationale, trade-offs, and alternatives considered have the highest long-term value. What seems obvious today will be puzzling in a year.
- **Flag breaking changes and known limitations upfront**, never buried.
- **Include testing instructions** so reviewers know how to verify the change works.
- **Keep it proportional**: a 5-line typo fix gets a 2-line description. A major refactor gets a thorough write-up with context and design rationale.
- **Link related issues** using GitHub auto-close keywords: `Closes #123`, `Fixes #456`, `Relates to #789`.
- Do NOT pad the description with boilerplate or empty checklist items. Only include sections with actual content.
- Do NOT just dump commit messages. Commit history explains *what changed over time*; the PR description explains *the net result and why*.

### Real-world examples to emulate

**Small bug fix** (inspired by [kubernetes/kubernetes#77347](https://github.com/kubernetes/kubernetes/pull/77347)):

> **Title:** `fix(cli): correct Successful Job History Limit in describe output`
>
> ## Summary
>
> `kubectl describe cronjobs` displays the wrong value for Successful Job History Limit — it shows `0` regardless of the actual setting. This fixes the field mapping so the correct limit is displayed.
>
> Fixes #77345

**Medium feature** (inspired by [vercel/next.js#68102](https://github.com/vercel/next.js/pull/68102)):

> **Title:** `feat(router): add <Form> component with client-side navigation`
>
> ## Summary
>
> Introduces `<Form>`, a form component integrated with the Next.js router. It has two modes: when `action` is a URL path, it performs a client-side navigation encoding form fields as search params (a progressively enhanced GET form). When `action` is a function, it behaves like a standard `<form>` executing the action on submit.
>
> ## Changes
>
> The component prefetches the target route's loading state on mount, then on submit intercepts the default browser behavior to navigate via `router.push`. Notable props: `replace` (use `router.replace` instead of `push`) and `scroll` (control scroll restoration), mirroring the `<Link>` API.
>
> ## How to Test
>
> ```jsx
> <Form action="/search">
>   <input name="q" />
>   <button type="submit">Search</button>
> </Form>
> ```
> Submit the form and verify the browser URL updates to `/search?q=...` without a full page reload.

**Large infrastructure change** (inspired by [vllm-project/vllm#20059](https://github.com/vllm-project/vllm/pull/20059)):

> **Title:** `perf(core)!: decouple full cudagraph from compilation, add FA2/FlashInfer support`
>
> ## Summary
>
> Decouples CUDA graph capture from torch.compile so full cudagraph works without compilation in v1. Introduces a new `cudagraph_mode` CLI flag with five modes (`NONE`, `PIECEWISE`, `FULL`, `FULL_DECODE_ONLY`, `FULL_AND_PIECEWISE`) to replace the existing `use_cudagraph` and `full_cuda_graph` flags. The most powerful mode, `FULL_AND_PIECEWISE`, reduced ITL for Triton attention by 38% on small LLMs compared to piecewise-only on main.
>
> ## Changes
>
> Three new core components drive the implementation: `CUDAGraphMode` (enum defining the five modes), `CUDAGraphWrapper` (manages capture/replay lifecycle), and `CUDAGraphDispatcher` (routes batches to the right graph at runtime based on a `BatchDescriptor`). Full cudagraph modes are compatible with speculative decode's validation phase for FA2/3 and Triton attention.
>
> ## Motivation
>
> Piecewise cudagraph still incurs CPU overhead for batch sizes that aren't captured. Full cudagraph eliminates this for decode, but the previous implementation was tightly coupled to `torch.compile`, making it fragile and backend-specific. This PR separates the concerns so any attention backend can opt in to full cudagraph independently. See RFC #20283 for the full design discussion.
>
> ## Breaking Changes
>
> `use_cudagraph` and `full_cuda_graph` flags are deprecated in favor of `cudagraph_mode`. Existing configs will continue to work via automatic mapping but will emit a deprecation warning.
>
> ## Notes
>
> FlashMLA support is deferred to a follow-up PR. NCCL memory buffer trade-offs for large-scale disaggregated setups (e.g. 96P144D) are documented in #18242.

## Step 5: Check for an existing PR

Before creating, check if a PR already exists for this branch:
```
gh pr view --json number,url 2>/dev/null
```
If a PR already exists, ask the user if they want to update its title/description instead of creating a new one.

## Step 6: Create the PR

Use `gh pr create` with the title and body:

```
gh pr create \
  --base <target-branch> \
  --title "<title>" \
  --body "<body>"
```

Important:
- Pass `--base` with the target branch.
- Do NOT use `--fill` — always provide an explicit `--title` and `--body`.
- Do NOT add any `Co-Authored-By` trailers or similar attribution to the PR description.
- Write the body to a temp file and use `--body-file` if the description is long or contains characters that are hard to escape in shell:
  ```
  gh pr create --base <target-branch> --title "<title>" --body-file /tmp/pr-body.md
  ```

## Step 7: Confirm

After creating the PR, display:
- The PR URL
- The title
- A brief summary of what was included

Clean up any temp files created.
