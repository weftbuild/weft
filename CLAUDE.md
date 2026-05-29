# CLAUDE.md — Weft (plugin repo)

This is the Weft source repo. Weft is a Claude Code plugin that runs
a structured software-delivery pipeline behind a single `/weft`
command. A Claude session in **this** repo is *developing the
plugin* — not running the pipeline.

---

## Repo structure

- `.claude-plugin/plugin.json` — plugin manifest (authoritative version)
- `.claude-plugin/marketplace.json` — distribution manifest
- `skills/weft/SKILL.md` — the single `/weft` router
- `agents/*.md` — Orchestrator + stage builders (subagents)
- `reference/flows/*.md` — per-lane flow specs the Orchestrator runs
- `reference/checklists/*.md` — security checklists
- `reference/architect-paths/*.md` — paths the Architect can recommend
- `reference/examples/` — example `pipeline.config.json` shapes
- `reference/*.schema.md` — schema specs for runtime state and config
- `hooks/` `scripts/` `bin/` — SessionStart hook + scripts

## Conventions when editing the plugin

- Lowercase-with-hyphens filenames, no exceptions.
- Gates are the Orchestrator's job. Builders never render gates —
  they return a structured completion hand-back. Gate language is
  surface-agnostic: no "type 1", no terminal/panel assumptions.
- Flow logic lives once — the Orchestrator + `reference/flows/`.
  There is exactly one user entry, `/weft`. No user-invokable
  commands.
- Per-file `framework-version` headers are informational; the
  authoritative version is `.claude-plugin/plugin.json`.
- Keep prompt files lean. A bloated agent loses signal in noise.
