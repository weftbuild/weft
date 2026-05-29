<!-- framework-version: 2.0.0 -->
<!-- managed: true -->

# Provisioning (optional, on-demand)

**This is not a required step.** Weft used to provision all
infrastructure up front here, before the user had seen anything.
That has been decomposed. Provisioning is now **just-in-time**: each
piece is set up at the moment the stage that needs it runs.

- Backend + secrets → provisioned at the Engineer stage, when code
  first needs them.
- CI/CD, deployment target, production secrets → provisioned at the
  Deployer stage, when shipping.
- Component library → set from the stack at onboarding.
- Brand / design system → established in the Designer stage (Path B),
  not before.

Most users never need this command — just run `/weft` and Weft will
prompt for each piece exactly when it becomes relevant, already
motivated by an immediate need.

---

## Optional power-user use

If you explicitly want to provision infrastructure ahead of time
(e.g. you know you'll need the backend and want it ready before the
build stage), this flow can do that on demand.

Read `product-brief.md` and `pipeline.config.json`, then invoke the
Cloud Architect for the scopes the user asks for:
`agents/cloud-architect.md`

Pass the specific scope(s) requested — `cicd`, `backend`,
`deployment`, or `component-library`. The Cloud Architect provisions
only the requested scope and is idempotent: any scope already
provisioned (its config field is populated) is skipped.

This is never required and never gates feature work. If the user runs
it with no specific request, explain that provisioning is automatic
just-in-time and point them to `/weft`.
