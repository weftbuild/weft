<!-- framework-version: 2.0.0 -->
<!-- managed: true -->

# Improve flow

The improve lane. One continuous flow, Stages 1 → 6, from
identifying something that can be better to a shipped-and-recorded
improvement. There is no session boundary: the user runs `/weft`,
the Orchestrator routes here, and runs the sequence. Pause is
*available* at every gate, never *forced*. `/weft` resumes.

This lane runs when existing code needs to be strengthened without
introducing new user-facing behavior. It covers refactors,
architectural improvements, dependency updates, code quality,
versioning, copy polish, design refinement, and convention
compliance.

It is **not** for new features. If the work introduces something a
user can see, hear, or interact with that they couldn't before —
that is the New Feature lane's territory. The Evaluator's
feature-check catches this (see Stage 1).

Read `agents/communication-style.md` before producing any output.

The Orchestrator executes this spec. It has already oriented and
enforced the single-active-session rule (see `agents/orchestrator.md`
→ *On Session Start*). Gates are rendered by the Orchestrator per
*Gate Format* — this file supplies the gate options as data, it
does not render prompts.

---

## Inputs

Files this lane references most: `pipeline.config.json`,
`PRODUCT_CONTEXT.md`, `CLAUDE.md`, `DECISIONS.md`. All read at
session start; trust the in-memory copy (see Orchestrator →
*On Session Start*).

---

## Start / resume

**Fresh improve start** (no active session in
`session-state.json`):

- Ask the user what needs improving. *"Tell me what you'd like to
  strengthen and what's prompting it."*
- As soon as the user describes the improvement, write
  `session-state.json`: `activeFeature` = a short kebab-case name
  for the task (e.g. `update-shadcn-dependencies`),
  `sessionType: "maintain"`, `currentStage: 1`,
  `lastCompletedStage: 0`, `lastCheckpointStatus: "in-progress"`,
  `awaitingHuman: null`, `confirmedArtifacts: []`, `createdAt` /
  `updatedAt` = now. Write this BEFORE invoking Stage 1.

**Resume** (active or paused improve): resume at `currentStage`.
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
| 1 | The Evaluator | scoping the work so it stays an improvement | Strategy |
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
Chronicler is approved): *"Your improvement is shipped."* The
branded sign-off (*"From rough edge to refined. That's the Weft
process."*) fires immediately after the closeout-gate is
approved — see `agents/orchestrator.md` → *Final close — branded
sign-off*.

---

## Stages

Each stage follows the same shape: a specific, Weft-voiced
Orchestrator opening tied to *this* improvement (not a generic
description of what the stage does), invocation of the stage's
agent with the right context, the agent's work, and a gate on
completion. On gate approval, update `session-state.json`
atomically (`lastCompletedStage`, `currentStage`,
`lastCheckpointStatus: "approved"`, `awaitingHuman: null`,
`confirmedArtifacts`), produce the handoff, and advance.

---

### Stage 1 — The Evaluator

**Orchestrator opening.** Frame what The Evaluator will do: confirm
this work belongs in the Improve lane (not a New Feature in
disguise), scope it cleanly, surface any prior decisions being
touched. Reference the user's actual description, not a generic
description of triage.

**Invoke:** `agents/evaluator.md`

**Pass context:**
- The user's description of the improvement
- `pipeline.config.json` for stack
- `PRODUCT_CONTEXT.md` for what the product is
- `DECISIONS.md` for any decisions this work may touch

**Feature check — before the standard gate.** After scoping, the
Evaluator applies the branch rules. If the work introduces
user-facing behavior, new surfaces, or design decisions — anything
a user could see or interact with that they couldn't before — the
Evaluator returns a completion hand-back flagging the boundary
breach:

- summary: *"[task name] is on the boundary of New Feature
  territory. [One sentence on what the user could newly see or
  do.]"*
- gateOptions: *Switch to the New Feature lane* · *Re-scope to
  stay on Improve* · *Save progress and resume later*

The Orchestrator presents this per *Gate Format*. On *Switch*:
clear session state, route to the New Feature lane with a brief
summary of what was scoped. On *Re-scope*: return to scoping with
the constraint explicit. The standard Stage 1 gate is not
presented until the feature-check passes.

**Standard gate on completion** (feature-check passed):
- summary: *"The change brief for [task name] is ready for
  review."*
- gateOptions: *Continue to The Engineer* · *Save progress and
  resume later*

**On approval:** write `pipeline/[task]/change-brief.md`, update
session-state, produce handoff, advance to Stage 2.

---

### Stage 2 — The Engineer

**Orchestrator opening.** Frame what The Engineer will do — read
the change brief and make the agreed improvement. Reference what
is being strengthened specifically (refactor, dependency update,
copy polish, etc.).

**Invoke:** `agents/engineer.md`

**Pass context:**
- The approved `change-brief.md`
- `pipeline.config.json` for stack and conventions
- `CLAUDE.md` for project conventions
- `PRODUCT_CONTEXT.md` for codebase context
- `DECISIONS.md` for any decisions this work touches

**Gate on completion:**
- summary: *"The improvement for [task name] is implemented and
  ready for review."*
- gateOptions: *Continue to The Tester* · *Save progress and
  resume later*

**On approval:** update session-state, produce handoff, advance to
Stage 3.

---

### Stage 3 — The Tester

**Orchestrator opening.** Briefly note what The Tester will do —
confirm the improvement works as described in the change brief
and check for regressions in adjacent functionality. Reference
the test runner from `pipeline.config.json`.

**Invoke:** `agents/qa.md`

**Pass context:**
- The code changes from Stage 2
- The `change-brief.md` for what to verify
- `pipeline.config.json` for the test runner

**QA loop:** The Tester runs tests. If anything fails, The
Engineer attempts a fix. Loop runs up to **3 times**. If tests
still fail after 3 attempts, it is a **Type 2 failure** — stop and
involve the user.

**Gate on pass:**
- summary: *"Verification passed for [task name]. The improvement
  works and no regressions detected."*
- gateOptions: *Continue to The Auditor* · *Save progress and
  resume later*

**On approval:** update session-state, produce handoff, advance to
Stage 4.

---

### Stage 4 — The Auditor

**Orchestrator opening.** Briefly note what The Auditor will do —
check whether the improvement introduces any new security surface
or changes a trust boundary. For dependency updates, this includes
known-vulnerability checks in the new versions.

**Invoke:** `agents/security.md`

**Pass context:**
- The code changes from Stage 2
- `pipeline.config.json` to determine which checklist to load
- The `change-brief.md` for context

**Critical or High findings → Type 2 failure.** Do not present the
standard gate. Stop and walk the user through resolution.
Deployment is blocked until resolved. No exceptions.

**Gate on pass or pass-with-notes:**
- summary: *"Security review complete for [task name]. [One
  sentence summary of outcome.]"*
- gateOptions: *Continue to The Deployer* · *Save progress and
  resume later*

**On approval:** update session-state, produce handoff, advance to
Stage 5.

---

### Stage 5 — The Deployer

**Orchestrator opening.** The improvement goes live. Briefly note
staging verification before production. Production deploy is a
destructive action and requires explicit confirmation.

**Invoke:** `agents/deployment.md`

**Pass context:**
- `pipeline.config.json` for deployment target and environments
- The `change-brief.md` for what to verify on staging
- The code changes from Stage 2

**Production deploy is a destructive action.** The Deployer
presents production deployment as the Orchestrator's *Destructive
Action* gate (see `agents/orchestrator.md` → *Destructive Actions*),
never as a routine gate. The user must explicitly confirm.

**Gate on completion:** The Deployer produces its own
post-health-check confirmation. Standard structure:
- summary: *"[task name] is live in production."*
- gateOptions: *Continue to The Chronicler* · *Save progress and
  resume later*

**On approval:** update session-state, produce handoff, advance to
Stage 6.

---

### Stage 6 — The Chronicler

**Orchestrator opening.** The improvement is shipped. Keep this
opening brief — the user is close to done. The Chronicler records
what changed, why, and whether any prior decision was touched or
reversed. This step is load-bearing — improvements that touch
prior decisions must be chronicled or the project record silently
rots.

**Invoke:** `agents/context-update.md`

**Pass context:**
- The `change-brief.md` and the code changes from Stage 2
- Current `PRODUCT_CONTEXT.md`, `CLAUDE.md`, `DECISIONS.md`

**Gate on completion:** The Chronicler presents what was updated
in chat. Once the user signals done, the bridge message fires:

> **Weft** · The Guide
>
> The Chronicler updated the project memory. Your improvement is
> shipped.

Then the closeout gate fires:
- summary: *"The improvement to [task name] is shipped."*
- gateOptions: *Close the improvement out* · *Save progress and
  resume later*

**On *Close the improvement out*:** write the unified closeout to
`session-state.json`:
- `activeFeature: null`
- `currentStage: null`
- `lastCompletedStage: 6`
- `lastCheckpointStatus: "approved"`
- `sessionType: null`
- `awaitingHuman: null`

Then write the final `handoff.md`:
- *What We Accomplished* — what was strengthened and why, in plain
  English
- *What Has Been Saved* — the change-brief plus the code changes;
  flag any `DECISIONS.md` entries updated
- *Where We Are* — improvement complete
- *Resume Prompt* — run `/weft` to start the next thing

**Then post the branded sign-off** per `agents/orchestrator.md`
→ *Final close — branded sign-off*:

> **Weft** · The Guide
>
> From rough edge to refined. That's the Weft process.
>
> When you're ready to build the next thing, run **/weft**.
>
> — Weft

The improvement is complete.

---

## Rules

1. **Never skip a stage.** The Auditor runs even for text-only
   changes.
2. **Resume from `session-state.json`** if an improvement is in
   progress. Never restart an approved stage.
3. **One feature/fix/improvement at a time.** The Orchestrator
   enforces single-active-session before this flow starts.
4. **The Evaluator is the scope gate.** If the work grows during
   any stage and starts looking like a feature, stop and surface
   it. Do not silently expand scope.
5. **QA loop is 3 attempts max**, then Type 2.
6. **Security Critical/High always blocks deployment.** No
   exceptions.
7. **Production deploy requires explicit confirmation** via the
   Destructive Action gate — never on a routine gate.
8. **The improvement is not complete until Stage 6 is approved.**
   A shipped improvement without updated context is an incomplete
   run — especially when prior decisions are touched.
9. **Pause is available at every gate; it is never forced.** No
   command to re-invoke — `/weft` resumes.
