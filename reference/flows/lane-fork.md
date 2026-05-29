<!-- framework-version: 2.0.0 -->
<!-- managed: true -->

# Lane fork

The first-class routing flow. When `/weft` runs on a project that
has `pipeline.config.json` and `product-brief.md` but no active
session, present this modal — **verbatim** — and route on the
user's selection.

This file is the canonical copy. Do **not** invent alternative
phrasings ("Which lane do you want to start?" / "Pick a workflow" /
"Lane do you want to open next?" / etc.).

---

## Lead-in (in chat, before the modal)

One short, warm opener from The Guide. Acknowledge state (is this
fresh, or coming after a previous shipped feature?) and let the
modal carry the question.

**Fresh idle state** (no prior feature shipped):

> **Weft** · The Guide
>
> Let's get started.

**After shipping a previous feature** (the last entry in
`ROADMAP.md` Shipped section):

> **Weft** · The Guide
>
> Welcome back. [Last feature] is shipped. What's next?

Keep it to one short opener. Do **not** include internal vocabulary
("State is clean", "Routing to the lane-choice question",
"pipeline is idle"). Skip any pre-modal reasoning narration
entirely — the user sees the opener and the modal, nothing else.

---

## The modal

Render via the native question UI (AskUserQuestion). Use **these
exact field values** verbatim:

- **header**: `Guide`
- **question** (fresh idle): `How can Weft help you today?`
- **question** (resume after a shipped feature): `What would you like to do next?`
- **options** (exactly three; the native UI adds *Other*
  automatically):

  1. **label**: `New Feature`
     **description**: `Plan → Design → Build → Ship.`
  2. **label**: `Improve`
     **description**: `Strengthen something already shipped (design polish, copy, refactor).`
  3. **label**: `Fix`
     **description**: `Something is broken — find the root cause and fix it.`

Do **not** add `Other` to the explicit options. Do **not** add any
other middle options.

---

## Routing

Map the user's selection to the next flow:

| Selection | Flow |
|---|---|
| New Feature | `reference/flows/feature.md` |
| Improve | `reference/flows/maintain.md` |
| Fix | `reference/flows/fix.md` |
| Other (native UI) | Ask in chat what they need; route accordingly. Common cases: abandon a paused feature, request a checkpoint, surface a question outside the three lanes. |

---

## Forbidden in user-facing text

The user does **not** see internal vocabulary:
- No `"lane"` — the routing concept lives inside the spec; the
  user sees three plain choices.
- No `"The Orchestrator"` — Orchestrator-direct moments use
  **The Guide**.
- No flow-spec file names (`feature.md`, `fix.md`, `maintain.md`).
- No internal reasoning narration ("State is clean", "Routing to
  the lane-choice question", "pipeline is idle").
