# Framework File Versioning Convention

Every file managed by the Weft framework includes
a version header at the top. This header tells the VS Code extension
whether it owns the file and what version it is.

---

## Header Format

```markdown
<!-- framework-version: 1.0.0 -->
<!-- managed: true -->
```

Both lines are required on managed files. They must be the first
two lines of the file, before any other content.

---

## Fields

**`framework-version`**
The version of the framework this file was written for.
Uses semantic versioning: `major.minor.patch`.

- `major` — breaking changes to the file's structure or behavior
- `minor` — new capabilities added, backward compatible
- `patch` — fixes, clarifications, wording improvements

**`managed`**
Whether the VS Code extension owns this file and will update it
when new versions ship.

- `true` — the extension manages this file. Users who want to
  customize it should copy and rename it. The original stays
  managed and receives updates.
- `false` — this file is user-owned. The extension will never
  overwrite it. (Used for files generated per-project, like
  `pipeline.config.json` and `product-brief.md`.)

---

## Which Files Are Managed

All files in `.claude/` are managed:
- `.claude/commands/*.md`
- `.claude/builders/*.md`
- `.claude/builders/architect/*.md`
- `.claude/checklists/*.md`

These files are generated per-project and are NOT managed:
- `pipeline.config.json`
- `product-brief.md`
- `brand.md`
- `CLAUDE.md`
- `PRODUCT_CONTEXT.md`
- `DECISIONS.md`
- `pipeline/` (all runtime artifacts)

---

## How Updates Work

When the VS Code extension ships an updated version of a managed
file, it:

1. Reads the `framework-version` header of the installed file
2. Compares against the latest available version
3. If newer: overwrites the file with the updated version
4. If the user has renamed the file (indicating customization):
   leaves it untouched
5. Shows the user a changelog of what improved

The user is always told what changed. Nothing is overwritten silently.

---

## Adding a New Stack

When adding a new supported stack to the framework:

1. Create the new checklist file in `.claude/checklists/`
   with the standard version header (`managed: true`)
2. Add the stack to `pipeline.config.schema.md` valid values
3. Add the component library mapping to the design system table
4. Set the initial version to `1.0.0`

No other files need to change.
