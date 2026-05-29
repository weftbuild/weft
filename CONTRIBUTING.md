# Contributing to Weft

Thank you for your interest in contributing. This document covers
how to report issues, propose improvements, and submit changes.

---

## What Can Be Contributed

**Bug reports and clarifications**
If a builder prompt produces unexpected behavior, or if instructions
are ambiguous or contradictory, open an issue describing what happened
and what you expected.

**New stack support**
Adding a new supported stack requires exactly three things:
1. A security checklist file in `reference/checklists/`
   following the existing checklist format
2. An update to `reference/pipeline.config.schema.md` adding the
   new valid values
3. A component library mapping entry in the design system table

Stack additions that include all three are welcome as pull requests.

**Prompt improvements**
If a builder prompt can be made clearer, more flexible, or better
suited to a specific use case, open an issue first describing the
improvement and why it matters. This keeps the discussion focused
before any code is written.

**Bug fixes**
Fixes to existing prompts that correct incorrect behavior are
welcome directly as pull requests with a clear description of
what was wrong and what the fix does.

---

## What Cannot Be Contributed

- Changes to core design decisions (recorded in
  `reference/plugin-migration.md`) without opening an issue and
  reaching consensus first
- Agent framework dependencies — Weft is intentionally built on
  structured prompts, subagents, and file conventions, not
  orchestration libraries
- Features that require external services the framework doesn't
  already support
- Changes that break the file naming convention
  (lowercase with hyphens, no exceptions)

---

## Opening an Issue

Use the issue templates provided in `.github/ISSUE_TEMPLATE/`:
- **Bug report** — unexpected behavior in a builder or command
- **Stack request** — adding support for a new stack
- **Prompt improvement** — suggestion for making a builder better
- **Feature request** — new capability not currently in the framework

---

## Submitting a Pull Request

1. Fork the repo and create a branch from `main`
2. Make your changes following the conventions below
3. Test your changes by running the affected flow via `/weft` in a
   real Claude Code session against a test project
4. Submit the PR with a clear description of what changed and why

**PR requirements:**
- One change per PR — don't bundle unrelated fixes
- Per-file `framework-version` headers are informational; the
  authoritative version is `.claude-plugin/plugin.json`
- File naming must follow the lowercase-with-hyphens convention
- Builder prompts read specific files, produce specific output, and
  return a structured completion hand-back — the Orchestrator renders
  gates; builders never do. Gate language stays surface-agnostic.

---

## Code of Conduct

Be direct, be honest, and be kind. Disagreement is fine.
Condescension is not.

---

## Questions

Open an issue with the label `question`. We'll do our best
to respond promptly.
