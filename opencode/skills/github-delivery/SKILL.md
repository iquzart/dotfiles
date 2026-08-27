---
name: github-delivery
description: GitHub repositories, pull requests, GitHub Actions delivery pipelines, release promotion, and deployment governance. Use for software delivery workflows.
---
# GitHub Delivery

## Scope boundary

Use this skill for environments, branch protection, release orchestration, and deployment governance. Use `github-development` to author GitHub Actions workflow YAML and action configuration.

Preserve branch and environment protection, least-privilege permissions, provenance, promotion gates, and rollback paths. Use `github-development` for strict workflow generation. Production delivery requires approval.

Here is a clean README-ready version:

# Commit Message Convention

All commits generated or applied by an AI agent must be clearly identifiable as AI-generated.

The commit message format is determined by the **current Git branch name**, not by the task description.

## Commit Message Format

There are two possible formats depending on whether the current branch contains an SRE ticket ID.

### 1. Branch Contains a Ticket ID

If the branch name starts with an SRE ticket ID pattern:

```text
SRE-<number>_...
```

the ticket ID **must be included as the primary prefix** of the commit message.

The AI-authorship marker is placed at the end.

```text
[SRE-<number>] <commit message> [AI-generated]
```

#### Example

Branch:

```text
SRE-4367_version_bump_dev
```

Commit:

```text
[SRE-4367] Bump service version to 1.4.2 [AI-generated]
```

### 2. Branch Does Not Contain a Ticket ID

If the branch name does not start with an SRE ticket ID pattern, **do not invent or infer a ticket ID**.

In this case, the AI-authorship marker is used as the prefix:

```text
[AI-generated] <commit message>
```

#### Example

Branch:

```text
fix/readme-typo
```

Commit:

```text
[AI-generated] Fix typo in README
```

## Agent Identification

Where possible, the agent that generated the commit may also be identified.

### With Ticket ID

```text
[SRE-4367] Bump service version to 1.4.2 [AI-generated][agent:platform-engineer]
```

### Without Ticket ID

```text
[AI-generated][agent:platform-engineer] Bump service version to 1.4.2
```

This is recommended when multiple platform agents are working on the same repository, as it provides traceability of which agent generated the change.

## Rules

1. **Always inspect the current branch name** before creating a commit.
2. If the branch starts with `SRE-<number>_`, extract the ticket ID from the branch.
3. **Never fabricate a ticket ID** based on the task description or other context.
4. If an SRE ticket ID exists, it **must remain at the beginning** of the commit message.
5. If no ticket ID exists, use `[AI-generated]` as the commit message prefix.
6. Every commit generated or applied by an AI agent **must contain an AI-authorship marker**.
7. Do not represent an AI-generated commit as human-authored.
8. When agent identification is enabled, include the responsible agent using:

   ```text
   [agent:<agent-name>]
   ```

9. Keep the actual commit description concise and follow the repository's normal commit-message style.

## Reference Formats

| Branch                      | Commit Message                                            |
| --------------------------- | --------------------------------------------------------- |
| `SRE-4367_version_bump_dev` | `[SRE-4367] Bump service version to 1.4.2 [AI-generated]` |
| `SRE-5120_redis_config`     | `[SRE-5120] Update Redis configuration [AI-generated]`    |
| `fix/readme-typo`           | `[AI-generated] Fix typo in README`                       |
| `feature/update-monitoring` | `[AI-generated] Add monitoring configuration`             |

### With Agent Identification

```text
[SRE-4367] Bump service version to 1.4.2 [AI-generated][agent:platform-engineer]
```

```text
[AI-generated][agent:platform-engineer] Add monitoring configuration
```

## Important

The ticket prefix and AI marker serve different purposes:

* `[SRE-4367]` → identifies the associated work item.
* `[AI-generated]` → identifies the commit as AI-generated.
* `[agent:platform-engineer]` → identifies the agent responsible for the change.

All three can be used together when applicable.
