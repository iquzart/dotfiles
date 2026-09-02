---
name: grafana-development
description: Grafana dashboard JSON, PromQL, thresholds, colors, and template variables (datasource, namespace, service, interval). Use when creating or editing dashboards in this repo.
---

# Grafana Dashboard Skill

## Scope boundary

Use this skill to build and author dashboard artifacts. Use `grafana-operations` to query live data and investigate during incidents.

Use this skill when creating or updating Grafana dashboard JSON files in this repository.

## Scope

- This repository is dashboard-only.
- Treat these as primary maintained artifacts:
  - `cluster-capacity-overview-v1.json`
  - `namespace-capacity-dashboard-v1.json`
- Do not treat `session-ses_2036.md` as executable config.

## Required Variables (All Dashboards)

Every dashboard must include these template dropdown variables:

1. `datasource`
2. `namespace`
3. `service`
4. `interval`

Recommended defaults:

- `datasource`: Prometheus datasource variable
- `namespace`: query-backed label values
- `service`: query-backed label values filtered by namespace when possible
- `interval`: interval variable suitable for rate windows and aggregations

## Color and Threshold Conventions

Preserve this palette across dashboards:

- Normal/info: `#429ac2`
- Warning: `#fa6400`
- Critical: `#c4162a` (or `dark-red` where already used)

## Other Colours for Time series panels

- #8E3BB8
- #1f61c4

Apply thresholds by metric meaning:

- Risk metrics: low is good, high is bad
- Efficiency/headroom metrics: allow inverted thresholds when appropriate

## Dashboard Design Conventions

- Keep KPI stat panels scannable; prefer `colorMode: background` for headline KPIs.
- Prefer panel types by intent:
  - `stat`: headline KPIs / binary signals
  - `timeseries`: trends / forecasting
  - `bargauge` or `piechart`: distributions
  - `table`: top offenders and drilldown lists

## PromQL Safety Rules

- Use `${datasource}` for panel datasource references.
- Keep `cluster`, `namespace`, and `service` filters aligned with variables.
- Preserve container exclusions when applicable:
  - `container!=""`
  - `container!="POD"`
- Be careful with Container Platform-specific `label_replace` node pool extraction patterns.

## Identity and Defaults (When Editing Existing Dashboards)

- Keep UID and title stable unless explicitly asked to fork.
- Preserve schema and refresh conventions already used in this repo.
- Preserve intentional default time ranges unless explicitly asked to change.

## Fast Validation

Validate JSON after changes:

```bash
jq empty cluster-capacity-overview-v1.json namespace-capacity-dashboard-v1.json
```

Prefer semantic diffs (PromQL, variables, thresholds) over formatting-only churn.
