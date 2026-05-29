<!-- framework-version: 2.0.0 -->
<!-- managed: true -->

# Fix flow

The fix lane. One continuous flow, Stages 1 → 6, from a broken
behavior to a shipped-and-recorded fix. There is no session
boundary: the user runs `/weft`, the Orchestrator routes here, and
runs the sequence. Pause is *available* at every gate, never
*forced*. `/weft` resumes.

This lane is for confirmed or suspected regressions, bugs, and
broken behavior. It is not for new features. It is not for
improvements.

Read `agents/communication-style.md` before producing any output.

The Orchestrator executes this spec. It has already oriented and
enforced the single-active-session rule (see `agents/orchestrator.md`
→ *On Session Start*). Gates are rendered by the Orchestrator per
*Gate Format* — this file supplies the gate options as data, it
does not render prompts.

---

## Inputs

Files this lane references most: `pipeline.config.json`,
`PRODUCT_CONTEXT.md`, `CLAUDE.md`. All read at session start;
trust the in-memory copy (see Orchestrator → *On Session Start*).

---

## Start / resume

**Fresh fix start** (no active session in `session-state.json`):

- Ask the user what is broken. Specifically. *"Tell me what's
  happening, what you expected, and what you see instead."*
- As soon as the user describes the bug, write
  `session-state.json`: `activeFeature` = a short kebab-case name
  for the fix (e.g. `abandon-button-not-copying`),
  `sessionType: "fix"`, `currentStage: 1`,
  `lastCompletedStage: 0`, `lastCheckpointStatus: "in-progress"`,
  `awaitingHuman: null`, `confirmedArtifacts: []`, `createdAt` /
  `updatedAt` = now. Write this BEFORE invoking Stage 1.

**Resume** (active or paused fix): resume at `currentStage`.
Never re-run an approved stage. Tell the user what was already
done and what comes next, in plain English.

---

## Stage data (used by The Guide for the bridge message)

This is the canonical source for the bridge message tracker line
between stages. The Orchestrator (as The Guide) reads this table
when constructing the tracker after a stage completes. See
`agents/orchestrator.md` → *Stage transition — the bridge message*
for format.

| # | Role | Tagline (tracker form) | Macro-stage |
|---|---|---|---|
| 1 | The Evaluator | finding the real cause, not just the symptom | Strategy |
| 2 | The Engineer | building it for real | Build |
| 3 | The Tester | checking it actually works | Build |
| 4 | The Auditor | keeping security, data, and privacy solid | Build |
| 5 | The Deployer | getting it live without anything breaking | Build |
| 6 | The Chronicler | updating the project memory for what comes next | Build |

**Total: 6 steps.** Tracker is integrated into the bridge
narrative — *"Next up: The [Role] (Step N of 6), [tagline]."* No
ASCII bar, no separate code block. See `agents/orchestrator.md`
→ *Stage transition — the bridge message* for the full format.

**Completion sentence** (in the final bridge, after Stage 6
Chronicler is approved): *"Your fix is shipped."* The branded
sign-off (*"From broken to fixed. That's the Weft process."*)
fires immediately after the closeout-gate is approved — see
`agents/orchestrator.md` → *Final close — branded sign-off*.

---

## Stages

Each stage follows the same shape: a specific, Weft-voiced
Orchestrator opening tied to *this* fix (not a generic description
of what the stage does), invocation of the stage's agent with the
right context, the agent's work, and a gate on completion. On
gate approval, update `session-state.json` atomically
(`lastCompletedStage`, `currentStage`,
`lastCheckpointStatus: "approved"`, `awaitingHuman: null`,
`confirmedArtifacts`), produce the handoff, and advance.

Fixes are urgent — keep openings tight. Get to the problem.

---

### Stage 1 — The Evaluator

**Orchestrator opening.** Frame what The Evaluator will do for
*this* bug: confirm it's real, reproduce it, scope it cleanly.
Reference the user's actual description, not a generic
description of triage. Keep it to 2 sentences.

**Invoke:** `agents/evaluator.md`

**Pass context:**
- The user's description of what is broken
- `pipeline.config.json` for stack
- `PRODUCT_CONTEXT.md` for how the product is supposed to work

**Gate on completion:**
- summary: *"The bug brief for [fix name] is ready for review."*
- gateOptions: *Continue to The Engineer* · *Save progress and
  resume later*

**On approval:** write `pipeline/[fix-name]/bug-brief.md`, update
session-state, produce handoff, advance to Stage 2.

---

### Stage 2 — The Engineer

**Orchestrator opening.** Bug is confirmed and scoped. Frame what
The Engineer will do — read the bug brief and fix the actual root
cause (not a workaround). Reference the specific bug.

**Invoke:** `agents/engineer.md`

**Pass context:**
- The approved `bug-brief.md`
- `pipeline.config.json` for stack and conventions
- `CLAUDE.md` for project conventions
- `PRODUCT_CONTEXT.md` for codebase context

**Gate on completion:**
- summary: *"The fix for [fix name] is implemented and ready for
  review."*
- gateOptions: *Continue to The Tester* · *Save progress and
  resume later*

**On approval:** update session-state, produce handoff, advance to
Stage 3.

---

### Stage 3 — The Tester

**Orchestrator opening.** Briefly note what The Tester will do for
this fix — verify the bug is gone AND check for regressions in
adjacent functionality. Reference the test runner from
`pipeline.config.json`.

**Invoke:** `agents/qa.md`

**Pass context:**
- The code changes from Stage 2
- The `bug-brief.md` reproduction steps
- `pipeline.config.json` for the test runner

**QA loop:** The Tester runs tests including the bug's repro. If
anything fails, The Engineer attempts a fix. Loop runs up to
**3 times**. If tests still fail after 3 attempts, it is a
**Type 2 failure** — stop and involve the user.

**Gate on pass:**
- summary: *"Verification passed for [fix name]. The bug is fixed
  and no regressions detected."*
- gateOptions: *Continue to The Auditor* · *Save progress and
  resume later*

**On approval:** update session-state, produce handoff, advance to
Stage 4.

---

### Stage 4 — The Auditor

**Orchestrator opening.** Most fixes pass The Auditor quickly.
Frame this as fast due diligence: does the fix introduce any new
security surface or change a trust boundary? Note which checklist
applies based on `pipeline.config.json`.

**Invoke:** `agents/security.md`

**Pass context:**
- The code changes from Stage 2
- `pipeline.config.json` to determine which checklist to load
- The `bug-brief.md` for context

**Critical or High findings → Type 2 failure.** Do not present the
standard gate. Stop and walk the user through resolution.
Deployment is blocked until resolved. No exceptions.

**Gate on pass or pass-with-notes:**
- summary: *"Security review complete for [fix name]. [One
  sentence summary of outcome.]"*
- gateOptions: *Continue to The Deployer* · *Save progress and
  resume later*

**On approval:** update session-state, produce handoff, advance to
Stage 5.

---

### Stage 5 — The Deployer

**Orchestrator opening.** The fix goes live. Briefly note staging
verification before production. Production deploy is a destructive
action and requires explicit confirmation.

**Invoke:** `agents/deployment.md`

**Pass context:**
- `pipeline.config.json` for deployment target and environments
- The `bug-brief.md` for what to verify on staging
- The code changes from Stage 2

**Production deploy is a destructive action.** The Deployer
presents production deployment as the Orchestrator's *Destructive
Action* gate (see `agents/orchestrator.md` → *Destructive Actions*),
never as a routine gate. The user must explicitly confirm.

**Gate on completion:** The Deployer produces its own
post-health-check confirmation. Standard structure:
- summary: *"[fix name] is live in production."*
- gateOptions: *Continue to The Chronicler* · *Save progress and
  resume later*

**On approval:** update session-state, produce handoff, advance to
Stage 6.

---

### Stage 6 — The Chronicler

**Orchestrator opening.** The fix is shipped. Keep this opening
brief — the user is close to done. The Chronicler records what
was broken, what was changed, and whether any prior decision was
touched or reversed.

**Invoke:** `agents/context-update.md`

**Pass context:**
- The `bug-brief.md` and the code changes from Stage 2
- Current `PRODUCT_CONTEXT.md`, `CLAUDE.md`, `DECISIONS.md`

**Gate on completion:** The Chronicler presents what was updated
in chat. Once the user signals done, the bridge message fires:

> **Weft** · The Guide
>
> The Chronicler updated the project memory. Your fix is shipped.

Then the closeout gate fires:
- summary: *"The [fix name] is shipped."*
- gateOptions: *Close the fix out* · *Save progress and resume
  later*

**On *Close the fix out*:** write the unified closeout to
`session-state.json`:
- `activeFeature: null`
- `currentStage: null`
- `lastCompletedStage: 6`
- `lastCheckpointStatus: "approved"`
- `sessionType: null`
- `awaitingHuman: null`

Then write the final `handoff.md`:
- *What We Accomplished* — what was broken and how it was fixed,
  in plain English
- *What Has Been Saved* — the bug-brief plus the code changes
- *Where We Are* — fix complete
- *Resume Prompt* — run `/weft` to start the next thing

**Then post the branded sign-off** per `agents/orchestrator.md`
→ *Final close — branded sign-off*:

> **Weft** · The Guide
>
> From broken to fixed. That's the Weft process.
>
> When you're ready to build the next thing, run **/weft**.
>
> — Weft

The fix is complete.

---

## Rules

1. **Never skip a stage.** The Auditor runs even for text-only
   fixes.
2. **Resume from `session-state.json`** if a fix is in progress.
   Never restart an approved stage.
3. **One feature/fix/improvement at a time.** The Orchestrator
   enforces single-active-session before this flow starts.
4. **QA loop is 3 attempts max**, then Type 2.
5. **Security Critical/High always blocks deployment.** No
   exceptions.
6. **Production deploy requires explicit confirmation** via the
   Destructive Action gate — never on a routine gate.
7. **The fix is not complete until Stage 6 is approved.** A
   shipped fix without updated context is an incomplete run.
8. **Pause is available at every gate; it is never forced.** No
   command to re-invoke — `/weft` resumes.
9. **Fix sessions are urgent.** Keep openings tight. Get to the
   problem.
