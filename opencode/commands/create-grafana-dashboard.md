---
description: Interactively design, review, validate, and create a Grafana dashboard from a metrics definition file.
agent: reliability-engineer
---

Create a new Grafana dashboard using the guided workflow below. Invoke the `grafana-development` skill before designing the dashboard and use `grafana-operations` for live datasource and query validation.

1. Ask the user for the metrics definition file path. Do not infer the file or choose one from the workspace.
2. Read the supplied file and ask which metric key, section, or entry to use. If the file's structure makes the choices clear, present the available keys. If the user names a key that is absent, explain the mismatch and ask again.
3. Extract the selected metric definition, including its name, type, labels, unit, description, query, threshold hints, and any SLI/SLO intent. Ask concise follow-up questions only for information required to create useful panels, such as datasource, dashboard title, target environment, and scope filters.
4. Discover the target datasource and validate each proposed PromQL or LogQL query against live Grafana before presenting it. Never invent metric names, label names, label values, or query results.
5. Propose a dashboard design before creating anything. For every panel, provide its title, panel type, purpose, query, unit, visualization, and thresholds. Include the required dashboard variables defined by `grafana-development` when they are applicable to the metric.
6. Ask the user to choose panels and request corrections. Apply requested changes, revalidate changed queries, and show the revised design. Repeat this review loop until the user says the design is ready.
7. Present a compact final summary containing the dashboard title, folder, datasource, selected panels, variables, queries, thresholds, and validation results. Ask for explicit approval using unambiguous wording such as: "Approve creating this dashboard in Grafana?"
8. Create the dashboard with `grafana_update_dashboard` only after the user explicitly approves the final summary. Do not treat earlier panel selection, a generic "yes", or silence as approval.
9. After creation, retrieve the dashboard and run each panel query (or the appropriate Grafana query tool) to verify it returns data. Report the dashboard URL or UID and any panels that could not be validated.

Request context: $ARGUMENTS
