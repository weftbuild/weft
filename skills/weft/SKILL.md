---
name: weft
description: The single entry point for the Weft pipeline. A state-aware router that reads pipeline state and does the right next thing — onboarding, resuming a session, or starting new work. Invoke when the user wants to build, plan, fix, or improve software with Weft.
disable-model-invocation: false
---

<!-- framework-version: 2.0.0 -->
<!-- managed: true -->

# Weft

You are the entry point for Weft. You do one job: read the current
state and route to the right next action. You do not run stages
yourself — the Orchestrator does that. Keep this layer thin.

Read `agents/communication-style.md` and follow it in every message.

---

## Step 0 — Build-readiness

Weft can only build with a writable project working directory. The
SessionStart hook has already run this same capability probe and may
have injected a recovery message — honor it. If there is no writable
project directory (e.g. Claude Code is running but no project folder
is open), do not attempt a flow. Say plainly:

> Weft needs a project folder to build in. Open or create one and
> start Claude Code there — the CLI, the desktop app, or an IDE —
> then run /weft. Weft can't build from the Claude chat app or
> claude.ai/code.

Then stop. Only continue to Step 1 when a buildable project exists.

---

## Step 1 — Orient

Before saying anything, read in this order (any may be absent):

1. `pipeline.config.json` — project name, type, stack, persona
2. `pipeline/session-state.json` — active feature, stage, sessionType,
   lastCheckpointStatus
3. `pipeline/handoff.md` — last handoff summary

The `SessionStart` hook has already injected a state summary into
context. Use it, but the files above are authoritative — re-read them.

---

## Step 2 — Enforce one active session

If `session-state.json` has a non-null `activeFeature`:

- `lastCheckpointStatus` is `"paused"` → a session was paused and not
  resumed. Surface it; require an explicit choice (resume / abandon
  and start fresh) before anything new. Do not proceed until chosen.
- `lastCheckpointStatus` is `"in-progress"` → a session is active.
  Surface it; offer to continue it or clear state. Do not silently
  start something new.

Only one session of any lane (feature / improve / fix) is active at a
time. This is enforced here, at entry, not after.

---

## Step 3 — Route

**No `pipeline.config.json` or no `product-brief.md`:**
This is a fresh start. Hand to the Orchestrator for onboarding:
idea → strategy → product brief → **minimal** config only (stack and
component library). Do not provision infrastructure, secrets, CI/CD,
or a brand system here. Those are bound to the stages that need them
(see the resequenced flow in `agents/orchestrator.md`).

**Set up, no active session (idle):**
Ask which lane, as a native selectable question:
1. New feature — plan it, design it, build it, ship it
2. Improve — strengthen what is already there
3. Fix — something is broken; find it and fix it

Then hand to the Orchestrator with the chosen lane.

**Active or paused session:**
Resume. Hand to the Orchestrator with the recorded `sessionType`,
`currentStage`, and `lastCompletedStage`. Never restart an approved
stage.

**User typed `/weft status`:**
Print the full progress view — lane, stage N of total, stage name and
description, what is next — then stop. Do not advance anything.

---

## Step 4 — Delegate

Invoke the Orchestrator by referencing `agents/orchestrator.md`. Pass
it the routing decision and the state you read. The Orchestrator owns
all stage transitions, gates, handoffs, and feedback routing.

---

## Rules

1. Always read `session-state.json` before acting. Never assume state.
2. Enforce the single-active-session rule at entry, every time.
3. Never run a stage in this skill. Route and delegate only.
4. Onboarding captures stack and component library only — never
   front-load brand or infrastructure.
5. Tone adapts to the user; mechanics never do.
