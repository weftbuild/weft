<!-- framework-version: 2.0.0 -->
<!-- managed: true -->

# Onboarding flow

The entry point for every new project — starting from scratch or
onboarding an existing codebase. The Orchestrator routes here when
there is no `pipeline.config.json` / `product-brief.md`; the user
runs `/weft`, never a command. Assumes no existing state — no
session-state.json, no config, no product-brief yet. Everything is
created here. Runs once per project (again only on an explicit
start-over).

---

## Flow

This is a fresh project setup.
Normal session-state rules do not apply — there is no state file to
read. Follow the four phases below in order. Do not skip phases.
Do not combine phases.

Read `agents/product-strategist.md` and
`agents/config-generator.md` before proceeding. You will
invoke both during this command.

---

## Phase 1 — Fork

Before anything else, ask the user one question. Nothing else. Do not
introduce the pipeline, do not explain what's coming. Just ask:

---

> **Weft** · The Guide
>
> Welcome to Weft.
>
> Let's start with one quick question to make sure we set things up
> the right way for you.
>
> 1. I have a new idea I want to build — starting from scratch
> 2. I already have something built and want to bring it into Weft
>    to keep improving it

---

Wait for the response. Record the entry path:
- Option 1 → `entryPath: "new"`
- Option 2 → `entryPath: "migration"`

**Why this fork matters — state it, don't just "adapt".** Under the
plugin nothing is dropped into the user's repo, so this is **not**
about file structure (the old reason, now obsolete). It is about
*how much founding and how much codebase-awareness* the run needs:
- `new` — a blank slate. Full founding strategy and design freedom;
  Weft chooses the best-fit stack for the product (nothing to
  detect or respect).
- `migration` — an existing codebase. Less founding; instead,
  detect and **respect** the existing stack, conventions, and
  architecture, and fit the work into what is already there.

All subsequent behavior adapts on this basis.

---

## Phase 2 — Founding Strategy

Invoke The Strategist builder:
`agents/product-strategist.md`

Pass the following context to the builder:
- Entry path selected in Phase 1
- Instruction that this is a founding run, not a feature run
- No existing `product-brief.md` exists yet

The Strategist runs its full founding strategy flow. See the
builder file for detailed instructions.

**This phase ends when:**
- The user has approved a `product-brief.md`
- The document has been written to the repo root

Do not proceed to Phase 3 until `product-brief.md` is approved and
written. Present this gate before moving on:

Hand back to the Orchestrator: summary *"Your product brief is
written and saved."*; gateOptions *Continue to project
configuration* · *Save progress and resume later*. The Orchestrator
presents it per *Gate Format* (two explicit options; the native
UI provides *Other* automatically). Revisions happen in chat with
The Strategist *before* the gate fires.

**On *Continue*:** Write `product-brief.md` to the repo root.
Confirm it has been saved. Proceed to Phase 3.

**On *Save & resume*:** Close per Orchestrator → *Session Handoff
→ After Writing* (one-sentence plain-English summary + run-`/weft`
close; no machine-readable resume prompt in chat). Stop.

---

## Phase 3 — Guided Q&A

Invoke the Config Generator builder:
`agents/config-generator.md`

Pass the following context to the builder:
- Entry path from Phase 1
- The approved `product-brief.md` content — the config should reflect
  the product decisions already made, not contradict them
- Instruction to ask questions one at a time, never in batches

The Config Generator runs its Q&A flow. See the builder file for the
full question set and order.

**Onboarding captures the minimum only.** Weft uses just-in-time
provisioning (Path B): the only configuration gathered here is what
is needed to produce a coherent first design — project name, project
type, frontend stack, and component library. Backend, email/SMS,
deployment target, repo, and secrets are **not** asked here. Each is
captured at the moment the stage that needs it runs (backend/secrets
at the Engineer; CI/CD, deploy target, production secrets at the
Deployer). This keeps the user moving toward seeing their product,
not configuring infrastructure before anything exists.

**Q&A adapts to entry path:**

For `new` projects — the builder confirms project name, type, and
frontend stack (informed by the approved `product-brief.md`) and the
component library that follows from the stack. Nothing else.

For `migration` projects — the builder detects the existing frontend
stack from files present in the repo, presents it as a starting
point, and the user confirms or corrects. Backend and other infra
are detected for reference but not provisioned here.

**This phase ends when:**
- All required questions have been answered
- The builder has enough information to generate a complete config

---

## Phase 4 — Review and Generate

The Config Generator presents the full proposed config as a readable
summary — not raw JSON. Each field is shown with a plain-English note
explaining what it means and why it was set that way.

**Example format:**

---

> Here's your project configuration. Review each item before we
> generate the files.
>
> **Project:** my-todo-app
> *The name your project will be identified by throughout Weft.*
>
> **Type:** web_app
> *A web application with a React frontend, based on your product brief.*
>
> **Frontend:** React + Vite + Tailwind CSS
> *Selected based on your web_app type. The component library
> (shadcn/ui) is installed just-in-time at the build stage.*
>
> **Component library:** shadcn/ui
> *Follows from your frontend stack. Recorded now, installed when
> the Engineer first needs it.*
>
> *Backend, email/SMS, deployment, and repo are intentionally not
> set here — Weft captures each just-in-time at the stage that needs
> it, so you start building instead of configuring infrastructure.*

---

Then hand back to the Orchestrator: summary = the config summary
above; gateOptions *Generate `pipeline.config.json` and start
building* · *Save progress and resume later*. The Orchestrator
presents it per *Gate Format* (two explicit options; the native
UI provides *Other* automatically). Changes to specific fields
happen in chat with The Config Generator *before* the gate fires.

**On *Generate*:** Generate the files (see below).

**On *Save & resume*:** Close per Orchestrator → *Session Handoff
→ After Writing* (one-sentence plain-English summary + run-`/weft`
close). Stop.

---

## File Generation

When the user approves in Phase 4, generate two files:

**1. `pipeline.config.json`** at the repo root.
Follow the schema defined in `agents/config-generator.md`.
All fields present. Unused fields set to null. Stack extensions nested
under `stack`. Timestamps set to current datetime in ISO 8601 format.

**2. `product-brief.md`** — already written in Phase 2.
Confirm it exists at the repo root. Do not overwrite it.

After writing, confirm both files exist. Then present the completion
message:

---

> **Weft** · The Guide
>
> **You're set up.**
>
> Two files have been created in your project:
> - `product-brief.md` — your founding product strategy
> - `pipeline.config.json` — your minimal project configuration
>
> **Your next step is `/weft`.**
>
> There's no separate infrastructure setup to do — Weft provisions
> what each stage needs, when it needs it, so you can start building
> right away. Run `/weft` and we'll begin your first feature.

---

## Rules

1. **Never combine phases.** Phase 1 ends before Phase 2 begins.
   Phase 2 ends before Phase 3 begins. Phase 3 ends before Phase 4.
2. **Never ask multiple questions at once.** One question, wait for
   the answer, then the next.
3. **Never generate files until Phase 4 approval.** Not even
   incrementally.
4. **Always adapt to the entry path.** New and migration projects
   follow different Q&A flows.
5. **The product brief leads the config.** Stack recommendations
   should be consistent with what was approved in product-brief.md.
6. **A clear next step always ends this flow.** The user should
   never finish onboarding wondering what to do next.
