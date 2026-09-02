---
name: helm-delivery
description: Helm release lifecycle across environments — install, upgrade, rollback, and uninstall of existing releases. Use when operating or changing an existing Helm release; use `helm-development` to author or edit chart templates/values structure.
---
# Helm Delivery

## Scope boundary

Use this skill to operate existing Helm releases across environments — install, upgrade, rollback, uninstall, and promotion between environments. Use `helm-development` to author or restructure charts, templates, and values schemas. If a release operation reveals the chart itself needs a template/logic change, stop and hand that off rather than patching templates from here.

## Pre-change inspection (required before any mutating command)

Before proposing any install/upgrade/rollback/uninstall, gather and present:

1. **Current state** — `helm list`, `helm get values`, `helm get manifest`, `helm history` for the target release.
2. **Drift check** — diff the currently deployed manifest against what's in source control for this release; flag if they don't match (someone changed it out-of-band).
3. **Proposed change** — `helm diff` (or `helm template` + manual diff if the diff plugin isn't available) between current release and the proposed values/chart version.
4. **Chart validation** — `helm lint` and `helm template --validate` against the target chart version.
5. **Dependency check** — confirm chart dependencies (subcharts, CRDs) are compatible with the target cluster/environment version.

## Change proposal format

Before requesting approval for any install, upgrade, uninstall, or rollback, state:

- **Release / environment / namespace** targeted
- **Current version → target version** (chart version and app version)
- **Values diff** — what's actually changing, not just "values updated"
- **Validation results** — lint/template output, drift check result
- **Rollback target** — the exact prior revision number to roll back to if this fails, confirmed to exist in `helm history` before proceeding
- **Blast radius** — what breaks if this goes wrong (e.g. does this release have dependents?)

## Rules

- Never run `helm upgrade`, `helm install`, `helm uninstall`, or `helm rollback` without completing pre-change inspection and getting explicit approval first — these are exactly the commands gated behind approval in the platform-engineer permission config; do not attempt to work around that by chaining flags.
- Production releases require explicit human approval regardless of how low-risk the change appears.
- If drift is detected between deployed state and source control, stop and report it — do not proceed with a change layered on top of unknown out-of-band modifications.
- Promote changes through environments in order (dev → staging → prod, or whatever the team's defined path is) — do not apply directly to a higher environment to "save time," even under approval, unless explicitly instructed otherwise for that specific change.
- After any successful operation, record the new revision number and what changed. Update documentation inseparable from the release when needed; hand off cross-repository release and changelog work to `technical-writer` via Core.

## Escalation

If a rollback fails or the release is stuck in a `pending-upgrade` / `failed` state that standard `helm rollback` does not resolve, **escalate to Core for approval and proceed with the appropriate manual Helm state recovery** rather than automatically escalating to the `reliability-engineer`.

Manual recovery may include inspecting and, where required, **manually correcting Helm release state stored in Kubernetes secrets**, after first validating the release history, values, rendered manifests, and dependencies. Any manual state modification must be performed carefully and only after confirming the affected release and recovery target.

Before any `install`, `upgrade`, `uninstall`, `rollback`, or manual recovery action, describe the release, values change, validation results, current release state, and rollback/recovery target and obtain the required approval.
