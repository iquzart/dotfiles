---
description: Create a project-specific Containerfile and companion files using container-development.
agent: platform-engineer
---

Load the `container-development` skill with the skill tool before starting. Follow its Create or Optimize workflow and the target repository's local instructions. Resolve the skill's scripts, assets, and references from its loaded base directory, not the target repository.

1. Confirm the target repository and build-context directory from the request context. If missing or ambiguous, ask the user. Do not assume the global OpenCode configuration directory is the target.
2. Inspect the project to determine its stack, service name, build and start commands, ports, dependencies, and existing container files. Ask only for required information that cannot be established from the repository. If a Containerfile or Dockerfile already exists, follow the Optimize workflow and report findings before proposing changes.
3. Present the proposed files, scope, risks, validation plan, and rollback plan. Include Containerfile, .dockerignore, and a companion Makefile; merge existing companion files rather than replacing them. Add compose.yaml or .env.example only when required by the skill. Ask for explicit approval before writing files or running the scaffold, and wait for the user's reply.
4. After approval, follow the skill's creation or approved optimization workflow in the confirmed target directory. Use verified image tags and digests, never latest or invented digests; multi-stage builds with a minimal runtime; a numeric non-root USER; exec-form ENTRYPOINT/CMD; and standard OCI labels with dynamic ARGs declared late in the final stage. Never put secrets in ARG, ENV, or COPY; use BuildKit secret mounts for build-time secrets. Do not add HEALTHCHECK to the Containerfile. For compose, follow the skill's pinning, resource limits, healthchecks, dependency ordering, network, volume, and secret requirements. Never overwrite or rename existing files without approval, and do not modify application code or tooling scripts.
5. With required execution approval, run the skill's check.py against the target directory and hadolint against the Containerfile if available. Require no Blocker or Major findings, inspect remaining findings, and verify all image pins and placeholders. Flag missing base-image update automation. For optimization, obtain the required execution approval before make size and report before/after results. Do not otherwise build, run, scan, push, deploy, commit, or open a PR without separate authorization.
6. Report the files changed, validation results, unresolved assumptions, and the final diff. Explicitly identify any validation that was not performed.

Request context: $ARGUMENTS
