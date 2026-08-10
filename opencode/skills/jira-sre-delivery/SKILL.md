---
name: jira-sre-delivery
description: Jira SRE Delivery and SRE_Kanban issue creation with mandatory Resolution=ToDo. Use when creating Tasks or Epics in this workspace via MCP.
---

# Jira SRE Delivery Skill

Use this skill for Jira issue creation in SRE Delivery / SRE_Kanban.

## Scope

- Applies to creating `Task` and `Epic` issues for the SRE Delivery workspace.
- Always use the Atlassian MCP tools for create and validation.

## Required Rule

- `Resolution` is mandatory on creation and must be set to `ToDo`.
- On every issue create call, include resolution in `additional_fields`.

## Default Create Payload Pattern

Use `mcp-atlassian_jira_create_issue` and include:

```json
{
  "project_key": "<SRE_DELIVERY_PROJECT_KEY>",
  "summary": "<title>",
  "issue_type": "Task or Epic",
  "description": "<markdown>",
  "additional_fields": "{\"resolution\":{\"name\":\"ToDo\"}}"
}
```

## Project/Board Resolution Workflow

If project key is not known at runtime:

1. Use `mcp-atlassian_jira_search_projects` with query `SRE Delivery`.
2. If needed, use `mcp-atlassian_jira_get_agile_boards` to find `SRE_Kanban` and confirm the board project.
3. Use the resolved project key for all creates.

## Error Handling

- If Jira rejects `resolution` due to option mismatch, fetch allowed values:
  1. `mcp-atlassian_jira_get_project_issue_types`
  2. `mcp-atlassian_jira_get_create_fields`
  3. `mcp-atlassian_jira_get_field_options` for the resolution field
- Retry create with the exact allowed resolution value that maps to ToDo.

## Guardrails

- Do not create Task/Epic without `Resolution=ToDo`.
- Keep issue body concise and actionable.
- Preserve user-provided summary and description text.
