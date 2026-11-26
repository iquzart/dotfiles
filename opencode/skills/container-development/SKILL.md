---
name: container-development
description: Create new or optimize existing Containerfiles/Dockerfiles, compose files, .dockerignore, and the companion Makefile, with security hardening, standard OCI labels, and best practices. Use whenever the user mentions containerizing an app, a Containerfile, Dockerfile, docker-compose or compose.yaml, Podman or Docker builds, multi-stage builds, distroless/alpine/slim images, running as non-root, image size, build speed or layer caching, or asks to review, harden, or optimize any container build definition or compose stack, even if they don't name this skill. Always creates a Makefile alongside any new Containerfile or compose file. Not for CI/CD pipeline logic, executing image scans, or Kubernetes manifests.
---

# Container Development

`SKILL_DIR` = `~/.config/opencode/skills/container-development`. Script paths below are relative to it; always call them with the full path (for example `python ~/.config/opencode/skills/container-development/scripts/check.py .`) because the working directory is the user's project. Python 3 is required; PyYAML is optional (compose checks).

Two workflows. Pick one first, then read only the references it points to.

| User intent | Workflow |
|---|---|
| New project, "containerize this", "add a Containerfile/compose" | **Create** |
| Existing Containerfile/Dockerfile/compose: review, harden, shrink, speed up | **Optimize** |

## Create (new project)

1. Detect the stack (Go, Node, other) and the service name, port, and repo from the project.
2. Scaffold from the matching template with the detected project values. The script requires `--name`, defaults to `--lang generic`, and never overwrites existing files:

```bash
   python "$SKILL_DIR/scripts/scaffold.py" --lang go --name my-service \
     --port 8080 --org my-org --repo my-repo
```

   Add `--compose`, `--with-db` (with `--compose`), or `--dest` as needed. If the script can't run, copy from `assets/` by hand. The user can also trigger this with `/generate-containerfile` (below).
3. Adapt the scaffold in place: preserve its instruction order. Keep one contiguous `ARG VERSION` / `ARG REVISION` / `ARG CREATED` / OCI `LABEL` block immediately after the runtime `FROM`. Keep `ENTRYPOINT` and any `CMD` at the end. Replace image placeholders with real pinned tags and digests (look them up; never invent digests) and adapt build commands to the project.
4. Verify: `python $SKILL_DIR/scripts/check.py .` (must report no Blockers or Majors), plus `hadolint Containerfile` if installed. Confirm that the OCI metadata block appears exactly once, immediately after the runtime `FROM`.
5. Tell the user what was created and which values they must confirm.

Deliverables are never just one file:

| File | When |
|---|---|
| `Containerfile` | Always |
| `.dockerignore` | Always |
| `Makefile` | **Always, whenever a Containerfile or compose file is created** |
| `compose.yaml` | When requested, or the service has local dependencies |
| `.env.example` | When compose or the app reads environment variables |
| Base-image update automation | Check Renovate/Dependabot covers the repo; if not, flag it |

If any already exists, extend it. Never overwrite or rename without asking. For an existing `Makefile`, merge the targets from `assets/makefile` instead of replacing it.

## Optimize (existing files)

1. Run `python $SKILL_DIR/scripts/check.py <path>` to get findings, and `hadolint <file>` if available.
2. Read `references/review.md` for the report format and the optimization checklist (size, cache, build speed), then the topic reference for each finding.
3. **Report first, don't silently fix.** List findings as `[Severity] file:line - issue - fix`, ordered by severity. Apply changes only after the user agrees.
4. After approved changes, re-run `check.py` and `make size` and report before/after.

## Non-negotiables

These always apply in both workflows. Detail and rationale are in `references/`.

- Never `latest`; pin tag and digest; keep digests fresh via Renovate/Dependabot.
- Multi-stage build; minimal runtime base.
- Run as non-root with a **numeric** `USER`.
- No secrets in `ARG`, `ENV`, or `COPY`; use BuildKit secret mounts for build-time secrets.
- **No `HEALTHCHECK` in Containerfiles.** Health is defined in compose and the orchestration platform.
- Exec-form `ENTRYPOINT`/`CMD`.
- Standard OCI labels; declare their dynamic `ARG`s in the same stage before the `LABEL`.
- `.dockerignore` exists; `Makefile` exists.
- Compose: pinned images, resource limits, healthchecks with `service_healthy` ordering, named network and volumes, no plaintext secrets.

## Reference index

Read only what the task needs.

| File | Read when |
|---|---|
| `references/containerfile.md` | Writing or restructuring a Containerfile: naming, engine, stages, base image choice, layers, process handling, labels, health contract, `.dockerignore` |
| `references/security.md` | Anything touching users, secrets, pinning, base images, or hardening |
| `references/compose.md` | Writing or reviewing a compose file |
| `references/makefile.md` | Creating or merging the Makefile |
| `references/review.md` | Optimize workflow: severity table, report format, optimization checklist |

## Assets (templates, copied by `scaffold.py`)

| File | Purpose |
|---|---|
| `assets/Containerfile.generic` | Language-agnostic template that passes every rule |
| `assets/Containerfile.go` | Go, static binary on distroless |
| `assets/Containerfile.node` | Node, prod-deps stage plus slim runtime |
| `assets/compose.yaml` | App plus optional Postgres, fully hardened |
| `assets/makefile` | Becomes `Makefile` with local build/run/lint/size/compose targets |
| `assets/dockerignore` | Becomes `.dockerignore` |
| `assets/env.example` | Becomes `.env.example` |

Placeholders in assets use `{{NAME}}`, `{{PORT}}`, `{{ORG}}`, `{{REPO}}`, `{{DESCRIPTION}}`, filled by the script. Image tags use `<version>`/`<digest>` and must be resolved by hand.

## Scripts

| Script | Use |
|---|---|
| `$SKILL_DIR/scripts/scaffold.py` | Create workflow: writes deliverables from assets without overwriting |
| `$SKILL_DIR/scripts/check.py` | Both workflows: static rule checker for Containerfiles and compose files; exit code 1 if any Blocker. Containerfile checks use only the standard library; compose checks need PyYAML and are skipped with a note if it is missing |

## Command

OpenCode loads commands from its own `commands/` directory, not from inside a skill folder, so the command ships separately:

| File | Use |
|---|---|
| `~/.config/opencode/commands/generate-containerfile.md` | `/generate-containerfile [--lang go\|node\|generic] [--name NAME] [--port PORT] [--compose] [--with-db]`: loads this skill and runs the Create workflow end to end |

## Scope

- No build, scan, or push logic in the Containerfile. That belongs to the GitHub Actions workflow (`github-development`) or delivery pipeline (`github-delivery`). The Makefile has no push/scan/deploy targets either.
- No Kubernetes manifests or probe paths here. Keep `EXPOSE`, the documented health contract, and the numeric `USER` consistent with what `kubernetes-operations` expects.
- If a referenced skill (`platform-engineer`, `github-development`, `github-delivery`, `kubernetes-operations`) isn't available, say so, state your assumption, and continue.
- Build performance problems in CI (cache invalidation across runners, BuildKit cache mounts in CI) go to `platform-engineer`.
