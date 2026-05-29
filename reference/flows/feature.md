<!-- framework-version: 2.0.0 -->
<!-- managed: true -->

# Feature flow

The new-feature lane. One continuous flow, Stages 1 → 9, from idea
to deployed-and-recorded. There is no session boundary and no
re-invoke: the user runs `/weft`, the Orchestrator routes here and
runs the sequence; the user can pause at any gate ("Save progress
and resume later") and resume later with `/weft`. Pause is
*available* everywhere, never *forced* anywhere.

The Orchestrator executes this spec. It has already oriented and
enforced the single-active-session rule (see `agents/orchestrator.md`
→ *On Session Start*). Gates are rendered by the Orchestrator per
*Gate Format* — this file supplies the gate options as data, it
does not render prompts.

---

## Inputs

Before the first stage, confirm onboarding has produced:
`pipeline.config.json`, `product-brief.md`, `CLAUDE.md`,
`PRODUCT_CONTEXT.md`. If any is absent, route back to onboarding
rather than starting the flow.

Also read `ROADMAP.md` if it exists.

---

## Start / resume

**Fresh feature start** (no active feature in `session-state.json`):

- If `ROADMAP.md` has items in "Up Next", reference the first item
  rather than asking cold: *"Your roadmap suggests starting with
  [feature 1]. Want that, or something else first?"* Always
  acknowledge the roadmap before asking — every run, not just the
  first.
- Otherwise, ask the user what feature they want to build.
- As soon as the user confirms a feature, write `session-state.json`:
  `activeFeature` = name (kebab-case), `sessionType: "feature"`,
  `currentStage: 1`, `lastCompletedStage: 0`,
  `lastCheckpointStatus: "in-progress"`, `awaitingHuman: null`,
  `confirmedArtifacts: []`, `createdAt` / `updatedAt` = now.
  Write this BEFORE invoking Stage 1 so orientation reflects the
  stage immediately.

**Resume** (active or paused feature): resume at `currentStage`.
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
| 1 | The Strategist | making sure it's worth building | Strategy |
| 2 | The Planner | turning it into a clear plan | Strategy |
| 3 | The Architect | working out how it's built | Design |
| 4 | The Designer | making it something you'd want to use | Design |
| 5 | The Engineer | building it for real | Build |
| 6 | The Tester | checking it actually works | Build |
| 7 | The Auditor | keeping security, data, and privacy solid | Build |
| 8 | The Deployer | getting it live without anything breaking | Build |
| 9 | The Chronicler | updating the project memory for what comes next | Build |

**Total: 9 steps.** Tracker is integrated into the bridge
narrative — *"Next up: The [Role] (Step N of 9), [tagline]."* No
ASCII bar, no separate code block. See `agents/orchestrator.md`
→ *Stage transition — the bridge message* for the full format.

**Completion sentence** (in the final bridge, after Stage 9
Chronicler is approved): *"Your feature is shipped."* The branded
sign-off (*"From idea to real product. That's the Weft process."*)
fires immediately after the closeout-gate is approved — see
`agents/orchestrator.md` → *Final close — branded sign-off*.

---

## Stages

Each stage follows the same shape: a specific, Weft-voiced
Orchestrator opening tied to *this* feature and project (not a
generic description of what the stage does), invocation of the
stage's agent with the right context, the agent's work, and a gate
on completion. On gate approval, update `session-state.json`
atomically (`lastCompletedStage`, `currentStage`,
`lastCheckpointStatus: "approved"`, `awaitingHuman: null`,
`confirmedArtifacts`), produce the handoff, and advance.

---

### Stage 1 — The Strategist

**Orchestrator opening.** Introduce Stage 1 in a way that is
specific to this project and this feature. Reference what you know
from the product brief and product context. Explain what The
Strategist will do and what the user should expect. Keep it to 2–3
sentences.

**Invoke:** `agents/product-strategist.md`

**Pass context:**
- This is a *feature run*, not a founding run
- The feature name or description the user provided
- Contents of `product-brief.md` for the alignment check

**Gate on completion:**
- summary: *"The strategic brief for [feature name] is ready for review."*
- gateOptions: *Continue to The Planner* · *Save progress and
  resume later*

**On approval:** write `pipeline/[feature]/strategic-brief.md`,
update session-state, produce handoff, advance to Stage 2.

---

### Stage 2 — The Planner

**Orchestrator opening.** Briefly introduce what The Planner will
do with the approved strategic brief. Reference the specific
feature — not a generic description of what a PRD is.

**Invoke:** `agents/pm.md`

**Pass context:**
- The approved `strategic-brief.md`
- `product-brief.md` for product context
- `PRODUCT_CONTEXT.md` for existing features and conventions

**Gate on completion:**
- summary: *"The PRD for [feature name] is ready for review."*
- gateOptions: *Continue to The Architect* · *Save progress and
  resume later*

**On approval:** write `pipeline/[feature]/prd.md`, update
session-state, produce handoff, advance to Stage 3.

---

### Stage 3 — The Architect

**Orchestrator opening.** Introduce the Architect stage. Note
which detection path applies (greenfield, migration, or
incremental) based on whether a `schema.md` already exists in the
project. Be specific — tell the user what the Architect will be
looking at and what it will produce.

**Invoke:** `agents/architect.md`

**Pass context:**
- The approved `prd.md`
- `pipeline.config.json` for stack information
- Any existing `schema.md` at the project root or in prior feature
  folders — the Architect uses this to determine its path

**Gate on completion:**
- summary: *"The schema design for [feature name] is ready for review."*
- gateOptions: *Continue to The Designer* · *Save progress and
  resume later*

**On approval:** write `pipeline/[feature]/schema.md` and any
migration files, update session-state, produce handoff, advance to
Stage 4.

---

### Stage 4 — The Designer

**Orchestrator opening.** This is the emotional payoff of the
planning arc. Frame it that way. The user is about to see their
idea rendered visually for the first time. Keep the opening warm
and anticipatory — this is an exciting moment, not a procedural
step.

**Invoke:** `agents/uiux-designer.md`

**Pass context:**
- The approved `prd.md` and `strategic-brief.md`
- `pipeline.config.json` for component library and design tokens
- `pipeline/design-system.md` if it exists — extend rather than
  reinvent (see `agents/uiux-designer.md`)
- Instruction to gather visual tone and references before
  generating

**Stage 4 — gate fires after in-chat iteration.** The Designer
loops on tweaks with the user *in chat* without firing the gate
per tweak; the gate fires only when the user signals the
direction is right. The Designer's own delivery — full `file://`
URL, "this is a starting point, not a final answer" framing,
iteration invitation — lives in `agents/uiux-designer.md`.

- summary: *"The design direction for [feature name] is ready."*
- gateOptions: *Continue to The Engineer* · *Save progress and
  resume later*

**On approval:** write `pipeline/[feature]/design-spec.md` and
`pipeline/[feature]/design.html`. On the first feature, the
Designer also establishes `pipeline/design-system.md` (canonical
brand/design source). Update session-state, produce handoff,
advance to Stage 5.

---

### Stage 5 — The Engineer

**Orchestrator opening.** This is where the feature gets built.
Frame it with the right energy — the planning is done, the design
is approved, now it becomes real. Reference what The Engineer
will be reading and what they'll produce.

**Invoke:** `agents/engineer.md`

**Pass context:**
- All Stage 1–4 artifacts
- `pipeline.config.json` for stack and conventions
- `CLAUDE.md` for project conventions
- `PRODUCT_CONTEXT.md` for existing codebase context
- `pipeline/design-system.md` for the canonical design system

**Gate on completion:**
- summary: *"The code for [feature name] is ready for review."*
- gateOptions: *Continue to The Tester* · *Save progress and
  resume later*

**On approval:** update session-state, produce handoff, advance to
Stage 6.

---

### Stage 6 — The Tester

**Orchestrator opening.** Briefly explain what The Tester will do
for this feature. Reference the test runner from
`pipeline.config.json`. Note that The Tester has a 3-attempt loop
— if tests fail, The Engineer and The Tester work through it
together before escalating.

**Invoke:** `agents/qa.md`

**Pass context:**
- The code written in Stage 5
- `prd.md` acceptance criteria — these are what The Tester
  verifies against
- `pipeline.config.json` for the test runner

**QA loop:** The Tester runs tests. If tests fail, The Engineer
attempts a fix. This loop runs up to **3 times**. If tests still
fail after 3 attempts, it is a **Type 2 failure** — stop and
involve the user.

**Gate on pass:**
- summary: *"Testing passed for [feature name]. All tests are green."*
- gateOptions: *Continue to The Auditor* · *Save progress and
  resume later*

**On approval:** update session-state, produce handoff, advance to
Stage 7.

---

### Stage 7 — The Auditor

**Orchestrator opening.** Introduce the security review. Note
which checklist will be loaded based on the backend in config.
Frame it as due diligence that protects the user's product — not
a bureaucratic gate.

**Invoke:** `agents/security.md`

**Pass context:**
- The code written in Stage 5
- `pipeline.config.json` to determine which checklist to load
- All prior-stage artifacts for context on what was built

**Critical or High findings → Type 2 failure.** Do not present the
standard gate. Stop and walk the user through resolution. Deployment
is blocked until resolved. No exceptions.

**Gate on pass or pass-with-notes:**
- summary: *"Security review complete for [feature name]. [One
  sentence summary of outcome.]"*
- gateOptions: *Continue to The Deployer* · *Save progress and
  resume later*

**On approval:** update session-state, produce handoff, advance to
Stage 8.

---

### Stage 8 — The Deployer

**Orchestrator opening.** This is the moment the feature goes
live. Frame it accordingly — the work is done, the checks have
passed, now it reaches users. Note that staging verification
happens before production deployment.

**Invoke:** `agents/deployment.md`

**Pass context:**
- `pipeline.config.json` for deployment target and environments
- `prd.md` acceptance criteria (used for staging verification)
- Prior-stage artifacts for context

**Production deploy is a destructive action.** The Deployer
presents production deployment as the Orchestrator's *Destructive
Action* gate (see `agents/orchestrator.md` → *Destructive Actions*),
never as a routine gate. The user must explicitly confirm.

**Gate on completion:** The Deployer produces its own
post-health-check confirmation. Standard structure:
- summary: *"[feature name] is live in production."*
- gateOptions: *Continue to The Chronicler* · *Save progress and
  resume later*

**On approval:** update session-state, produce handoff, advance to
Stage 9.

---

### Stage 9 — The Chronicler

**Orchestrator opening.** The feature is deployed. This final
step makes sure the next session starts with current knowledge.
Keep the opening brief — the user is close to done and doesn't
need a long explanation.

**Invoke:** `agents/context-update.md`

**Pass context:**
- All feature artifacts
- Current `PRODUCT_CONTEXT.md`, `CLAUDE.md`, and `DECISIONS.md`
- `pipeline/design-system.md` (the Chronicler folds any
  design-system extensions back at this stage)
- `ROADMAP.md` (the Chronicler may move the completed feature from
  Up Next to Shipped)

**Gate on completion:** The Chronicler presents what was updated
in chat. Once the user signals done, the bridge message fires:

> **Weft** · The Guide
>
> The Chronicler updated the project memory. Your feature is
> shipped.

Then the closeout gate fires:
- summary: *"[Feature name] is shipped."*
- gateOptions: *Close the feature out* · *Save progress and
  resume later*

**On *Close the feature out*:** write the unified closeout to
`session-state.json`:
- `activeFeature: null`
- `currentStage: null`
- `lastCompletedStage: 9`
- `lastCheckpointStatus: "approved"`
- `sessionType: null`
- `awaitingHuman: null`

Then write the final `handoff.md`:
- *What We Accomplished* — what the feature does in plain English
- *What Has Been Saved* — all artifact files produced
- *Where We Are* — feature complete
- *Resume Prompt* — run `/weft` to start the next feature

**Then post the branded sign-off** per `agents/orchestrator.md`
→ *Final close — branded sign-off*:

> **Weft** · The Guide
>
> From idea to real product. That's the Weft process.
>
> When you're ready to build the next thing, run **/weft**.
>
> — Weft

The feature is complete.

---

## Rules

1. **Never skip a stage.** Every feature runs all nine.
2. **Resume from `session-state.json`** if a feature is in
   progress. Never restart an approved stage.
3. **One feature at a time.** The Orchestrator enforces
   single-active-session before this flow starts.
4. **The Designer gate invites iteration** — it is not a standard
   approval gate; the Designer loops below the gate without
   firing one per tweak.
5. **QA loop is 3 attempts max**, then Type 2.
6. **Security Critical/High always blocks deployment.** No
   exceptions.
7. **Production deploy requires explicit confirmation** via the
   Destructive Action gate — never on a routine gate.
8. **The feature is not complete until Stage 9 is approved.** A
   deployed feature without updated context is an incomplete run.
9. **Pause is available at every gate; it is never forced.** No
   session boundary, no command to re-invoke — `/weft` resumes.
