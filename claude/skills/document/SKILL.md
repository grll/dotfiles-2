---
name: document
description: Explore a codebase or subsystem in detail and produce or update documentation following Diátaxis and best-in-class practices. Invoke when the user asks to document a project, module, or system.
argument-hint: "[path or scope to document, e.g. 'src/training' or 'the GRPO pipeline']"
---

# Document

Generate or update documentation for a codebase, module, or subsystem. Follow the process below exactly.

## Step 1 — Determine scope

Parse the user's request to identify:

- **Target**: path, module, or system to document (default: repo root)
- **Audience**: who will read this (default: senior engineers on the team)
- **Goal**: new docs from scratch, update existing docs, or fill gaps

If the scope is ambiguous, ask one clarifying question before proceeding.

## Step 2 — Deep exploration

Before writing a single line of documentation, thoroughly explore the target:

1. **Map the structure**: Glob for source files, configs, existing docs, tests, and scripts within scope.
2. **Read key files**: Entry points, main modules, configuration, CLI definitions, `__init__.py` files, existing READMEs.
3. **Trace the architecture**: Identify core abstractions, data flow, key interfaces, and external dependencies.
4. **Find existing docs**: Check for `/docs`, `README.md`, `ARCHITECTURE.md`, `ADR/`, inline docstrings, and comments.
5. **Understand conventions**: Note coding patterns, naming schemes, config formats, and testing approach already in use.

Spend adequate time here. The quality of documentation is bounded by the depth of understanding.

## Step 3 — Audit existing documentation

If docs already exist, evaluate them against the Diátaxis framework:

| Type | Question | Status |
|------|----------|--------|
| **How-to** | Are common tasks covered with step-by-step instructions? | |
| **Reference** | Are APIs, configs, and CLIs fully documented? | |
| **Explanation** | Are architectural decisions and design rationale captured? | |
| **Tutorial** | Is there an onboarding path for new team members? | |

Also check for:

- **Freshness**: Is the content current with the code?
- **Accuracy**: Do examples actually work?
- **Gaps**: What questions would a new reader have that aren't answered?

Report your findings to the user before writing.

## Step 4 — Plan the documentation set

Based on the audit, propose a documentation plan. Prioritize by impact:

| Priority | Document | Diátaxis type |
|----------|----------|---------------|
| P0 | README with 60-second quickstart | Landing page |
| P0 | Single runnable example for the primary use case | How-to |
| P1 | Troubleshooting guide for common failures | How-to |
| P1 | Configuration / API reference | Reference |
| P2 | Architecture / Design doc | Explanation |
| P2 | ADRs for key decisions | Explanation |
| P3 | Onboarding tutorial | Tutorial |

Present this plan to the user and confirm before writing.

## Step 5 — Write the documentation

Follow these rules for every document:

### Placement

- Store docs **in the repo**, not externally. Use `/docs` or alongside the modules they describe.
- One purpose, one audience per document. Never mix how-to with explanation or reference with tutorial.

### README (if in scope)

The README answers exactly five questions in under 60 seconds of reading:

1. **What is this?** — One sentence.
2. **Why does it exist?** — One sentence of motivation.
3. **How do I run it?** — A single, copy-pasteable command for the default case.
4. **Where do I find more?** — Links to how-to guides, reference, ADRs.
5. **Who owns this?** — Team, channel, or individual.

The README is a routing table, not a manual. Everything else goes in `/docs`.

### How-to guides

- Task-oriented. Title format: "How to [verb] [noun]".
- Start with prerequisites, then numbered steps, then expected output.
- Include the exact commands or code to run. Every example must be runnable.
- Cover failure modes: "If you see X, check Y first."

### Reference

- Auto-generate from code where possible (docstrings, type hints, CLI help).
- Must be exhaustive. Every parameter, option, and config key documented.
- No explanation or tutorial content. Just facts.
- Use tables for structured information.

### Explanation / Architecture docs

- Answer "why", not "how".
- Cover: problem statement, design, alternatives considered, limitations, operational concerns.
- Use diagrams when they clarify structure or data flow.
- These are hand-written — they require human (or careful AI) judgment.

### ADRs

Store in `/docs/adr/` with this template:

```markdown
# ADR-NNNN: [Decision Title]

## Status
[Proposed | Accepted | Deprecated | Superseded by ADR-NNNN]

## Context
[What is the problem? What constraints exist?]

## Decision
[What was decided and why, in 2-3 sentences.]

## Consequences
- [What becomes easier]
- [What becomes harder]
- [What we're giving up]
```

### Troubleshooting guides

- Organized by symptom, not by cause.
- Format: error message or symptom → likely cause → fix.
- Include environment-specific gotchas.

## Writing style rules

Follow these strictly:

1. **Conciseness is a feature.** Every sentence must carry new information. Delete filler. If a doc exceeds one printed page, it's probably two documents.
2. **Assume intelligence, not knowledge.** Never patronize. Never hand-wave. Explain what the reader needs, skip what they already know.
3. **Front-load critical information.** Don't build up to the point — start with it.
4. **Code over prose.** A runnable example beats a paragraph of explanation. Use before/after diffs to show integration.
5. **Tables over lists for structured data.** Parameters, options, and comparisons belong in tables.
6. **No orphan docs.** Every document must be linked from the README or a parent index.
7. **Freshness signal.** Add `Last verified: YYYY-MM-DD` to every doc. Use today's date.

## Step 6 — Review and iterate

After writing:

1. Verify all code examples are syntactically correct and match the actual codebase.
2. Check all links resolve.
3. Confirm every doc has a clear purpose, audience, and freshness date.
4. Present a summary of what was created or updated, with file paths.
