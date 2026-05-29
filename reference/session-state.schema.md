# session-state.json + handoff.md — Schema Specification

These two files are the Orchestrator's memory. They live in `/pipeline/`
and are written at the end of every stage, on every `/checkpoint` call,
and on every "Save & Pause" action. They are read at the start of every
session and by the VS Code panel at all times.

Neither file is committed to GitHub by default. They are runtime state,
not project config. Add `/pipeline/session-state.json` and
`/pipeline/handoff.md` to `.gitignore`.

---

## session-state.json

### Purpose
Tracks the exact position of the active feature in the pipeline.
The Orchestrator reads this at session start to know where to resume.
The VS Code panel reads this to display project status.

### Schema

| Field | Type | Valid Values | Notes |
|---|---|---|---|
| `activeFeature` | string or null | Any | Lowercase with hyphens. Matches the folder name in `/pipeline/`. null when no feature is in progress. |
| `entryPath` | string | `new` `migration` | Copied from pipeline.config.json. Never changes within a project. |
| `currentStage` | integer or null | `1`–`9` | The stage currently in progress. null if no active feature. |
| `lastCompletedStage` | integer or null | `1`–`9` | The last stage that received explicit user approval. null if no stage has been completed yet. |
| `lastCheckpointStatus` | string | `approved` `in-progress` `paused` | `approved` = stage completed cleanly. `in-progress` = stage started, not yet completed. `paused` = /checkpoint was called mid-stage. |
| `confirmedArtifacts` | array of strings | File names | List of artifact files that have been approved by the user. Empty array when no artifacts confirmed yet. |
| `createdAt` | string | ISO 8601 datetime | Set when the feature was first started. Never updated. |
| `updatedAt` | string | ISO 8601 datetime | Updated on every write. |

### Rules for the Orchestrator

1. **Read session-state.json at the start of every session** before
   invoking any builder.
2. **Write session-state.json after every gate approval** and on every
   `/checkpoint` call.
3. **`currentStage` and `lastCompletedStage` are different.**
   `currentStage` is what is happening now. `lastCompletedStage` is the
   last thing the user approved. They may differ if a stage is in
   progress.
4. **`activeFeature` is null between features.** When a feature ships
   completely, reset `activeFeature` to null and `currentStage` to null
   before the next feature begins.
5. **`confirmedArtifacts` grows forward, never shrinks.** Once an
   artifact is approved it stays in the list even if a later stage is
   re-entered.

---

## handoff.md

### Purpose
The human-readable record of the last session handoff. Written by the
Orchestrator in plain English — no jargon, readable by any persona.
The VS Code panel reads this file to populate the last handoff summary
and the re-entry prompt for the Resume button.

### Structure

handoff.md always has exactly four sections in this order. Section
headings are fixed — the VS Code panel reads them by heading name.

```
## What We Accomplished
[Plain-English summary of what was decided or built. No jargon.
1–3 sentences for most stages. Longer only if genuinely complex.]

## What Has Been Saved
[Explicit list of files written this session and where they live.
Bullet list. Full relative paths from repo root.]

## Where We Are
[Current position in the pipeline. Stage number, builder name,
session number. One or two sentences maximum.]

## Resume Prompt

To resume this session: copy the prompt below and paste it at the start
of your next Claude Code conversation. Or hit Resume in the VS Code
pipeline panel.

---

[A single copy-paste prompt the user can drop into Claude Code chat
to resume exactly where they left off. Specific, not generic.
Includes: project name, last completed stage, next stage, instruction
to load session-state.json.]
```

### Rules for the Orchestrator

1. **Overwrite handoff.md completely on every write.** It always
   reflects the most recent handoff only. It is not a log.
2. **Keep language simple.** Non-technical users read this. Avoid
   stage numbers in the "What We Accomplished" section — use plain
   descriptions instead.
3. **The Resume Prompt must be specific.** Not "run /new-feature"
   — but the exact context needed to pick up without any reconstruction.
4. **Write handoff.md and session-state.json in the same operation.**
   They should never be out of sync.
