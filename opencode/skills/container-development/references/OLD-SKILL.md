---
name: container-development
description: Authoring Dockerfiles, Containerfiles, and docker-compose files with security hardening, best practices, and standard labeling. Use when creating or reviewing a container build definition or a compose stack; not for CI/CD pipeline logic, image scanning execution, or Kubernetes manifests.
---

# Container Development

## Naming convention

Use `Containerfile` as the standard filename for this team unless the target platform/tooling specifically requires `Dockerfile` (e.g. a managed build service that only recognizes that name). Do not mix both in the same repo. `docker-compose.yaml` (not `.yml`) for compose files, for consistency across projects.

## Structure (multi-stage build)

Every container build should use at least two stages:

1. **Build stage** — full toolchain (compiler, package manager), produces the artifact.
2. **Runtime stage** — minimal base image, copies only the built artifact and runtime dependencies from the build stage. Nothing from the build toolchain should reach the final image.

```
# Build stage
FROM <language-build-image>:<pinned-version> AS build
WORKDIR /src
COPY . .
RUN <build command>

# Runtime stage
FROM <minimal-runtime-base>:<pinned-version>
COPY --from=build /src/<artifact> /app/<artifact>
USER <non-root-user>
EXPOSE <port>
ENTRYPOINT ["/app/<artifact>"]
```

## Security

- **Never use `latest`** for any base image tag — pin to a specific version or digest (`image:tag@sha256:...` for full reproducibility).
- **Run as non-root.** Create a dedicated user in the build (or use a base image that already ships one, e.g. `nonroot` variants) and set `USER` before `ENTRYPOINT`. Never leave the default root user in the runtime stage.
- **Minimal base images.** Prefer distroless, `-alpine`, or `-slim` variants for the runtime stage. Only use a full OS base image if the runtime genuinely needs shell/package-manager access (and if so, question why).
- **No secrets in layers.** Never `COPY` or `ARG` secrets, credentials, or `.env` files into any stage — even the build stage, since intermediate layers persist in image history unless using BuildKit secret mounts (`RUN --mount=type=secret`). Secrets are injected at runtime, not build time.
- **`.dockerignore` is mandatory.** Every project must have one excluding `.git`, `.env*`, local secrets, `node_modules`/`vendor` (rebuild inside container instead of copying from host), and any credentials directories.
- **No unnecessary packages.** Don't install debugging tools, editors, or package manager caches in the runtime stage. Clean up build-time package manager caches within the same `RUN` layer they were created in, not a separate layer.
- **Read-only filesystem where feasible.** If the app doesn't need to write to disk at runtime, document that the container can run with `--read-only` and mount only the specific writable paths it needs (e.g. `/tmp`).
- **Healthcheck defined.** Include a `HEALTHCHECK` instruction (or document that orchestration-level health checks are used instead — don't silently omit both).

## Best practices

- **Layer ordering for cache efficiency:** copy dependency manifests (`go.mod`/`go.sum`, `package.json`, etc.) and install dependencies *before* copying the rest of the source, so dependency layers cache across builds when only application code changes.
- **One process per container.** Don't use the container as a general-purpose VM; if multiple processes are genuinely needed, that's a docker-compose/orchestration decision, not a single-image decision.
- **Explicit `EXPOSE`.** Document every port the container listens on, even though `EXPOSE` doesn't enforce anything — it's documentation for the next person (and for compose/K8s tooling that reads it).
- **Build args vs. env vars.** Use `ARG` only for build-time values (version pins, build flags). Use `ENV` (set at runtime via orchestration, not hardcoded) for runtime configuration. Never use `ARG` for anything secret — it's visible in `docker history`.
- **Keep the image small.** Check final image size as part of review; a sudden jump usually means a stray cache or unnecessary layer crept in.

## Standard OCI labels

Every image must set these labels for traceability back to source:

```
LABEL org.opencontainers.image.source="https://github.com/<org>/<repo>"
LABEL org.opencontainers.image.revision="<git-sha, injected at build time via ARG>"
LABEL org.opencontainers.image.version="<semver or tag, injected at build time via ARG>"
LABEL org.opencontainers.image.created="<build timestamp, injected at build time via ARG>"
LABEL org.opencontainers.image.title="<service name>"
LABEL org.opencontainers.image.description="<short description>"
```

Inject `revision`/`version`/`created` via `ARG` passed from the CI workflow (owned by `platform-engineer` in `github-development`/`github-delivery`), not hardcoded — this keeps the Containerfile itself environment-agnostic while every built image is traceable to an exact commit.

## docker-compose standards

- **Service naming** — match the service name to the repo/component name, not generic names like `app` or `web`.
- **Networks** — define an explicit named network per stack; don't rely on the default bridge network across unrelated stacks.
- **Secrets/env** — never commit plaintext secrets or `.env` files with real values into the compose file or repo. Use `env_file` pointing to a gitignored local file for local dev, and document that real environments inject env vars through the orchestration platform (Kubernetes secrets, not compose, in staging/prod).
- **Resource limits** — set `deploy.resources.limits` (cpu/memory) even for local compose stacks, so behavior under constraint is tested early, not discovered in production.
- **Dependency ordering** — use `depends_on` with `condition: service_healthy` (requires a `healthcheck` on the dependency), not just startup-order `depends_on`, since process-started does not mean service-ready.
- **Volumes** — name volumes explicitly; avoid anonymous volumes that make cleanup and debugging harder.

## Rules

- Do not put build/scan/push logic in the Containerfile itself — that belongs in the GitHub Actions workflow (`github-development`) or delivery pipeline (`github-delivery`), not here.
- Do not reference Kubernetes-specific concerns (resource requests/limits at the pod level, liveness/readiness probe paths) in this skill — align the container's `HEALTHCHECK`/`EXPOSE` with what `kubernetes-operations` expects, but manifest authoring lives there, not here.
- Flag (don't silently fix) any existing Containerfile found using `latest`, running as root, or missing OCI labels during review — these are the most common regressions.

## Escalation

For build performance issues (slow builds, cache invalidation debugging, BuildKit-specific features like cache mounts across CI runners), route to `platform-engineer`'s broader CI/CD context rather than treating it as a container-development-only concern.
