# Containerfile reference

## Contents

1. Engine and naming
2. Structure
3. Base image selection
4. Layers and caching
5. Process handling
6. Labels
7. Health checks
8. .dockerignore
9. Size

## 1. Engine and naming

- Write files that work on **Docker (BuildKit) and Podman/Buildah**. Comment any engine-specific syntax.
- MUST name the build file `Containerfile` unless the platform requires `Dockerfile` (managed build services, or tooling that only detects that name; Dependabot's Docker updater is keyed to `Dockerfile` names, so verify before standardizing). Never keep both in one repo.
- Ignore file: `.dockerignore` (read by Docker and Podman). Do not keep both `.dockerignore` and `.containerignore` (Podman prefers `.containerignore`, causing silent divergence). Use `Containerfile.dockerignore` (BuildKit per-file ignore) only when a repo has multiple build files needing different ignore rules.
- Compose file: see `compose.md`.

## 2. Structure

MUST use at least two stages: a build stage with the full toolchain, and a minimal runtime stage receiving only the artifact and runtime dependencies. Nothing from the build toolchain reaches the final image.

Start from `assets/Containerfile.generic`, `.go`, or `.node`. Order inside a stage:

1. `FROM` (pinned, from a global `ARG` so tag and digest live in one place)
2. `WORKDIR`
3. dependency manifests, then dependency install
4. source copy, then build
5. runtime stage: `COPY --from=build --chown=<uid>:<gid>`, `USER`, `EXPOSE`, `ENTRYPOINT`
6. dynamic label `ARG`s and `LABEL` last

Document runtime constraints with a comment in the runtime stage, for example `# Runtime notes: supports --read-only; writable: /tmp`.

## 3. Base image selection

Choose in this order for the **runtime** stage:

1. Static binary (Go, Rust musl, etc.) on `scratch` or a distroless `static` image.
2. Dynamically linked compiled app on distroless `base`/`cc` or a `-slim` Debian image.
3. Interpreted apps (Python, Node, Ruby) on `-slim` Debian-based images.
4. `-alpine` only when the app is tested on it. Alpine uses musl: glibc-linked binaries break, many prebuilt Python wheels are unavailable, and DNS/locale behavior differs.

A full OS image (`ubuntu`, `debian` non-slim) needs a stated reason, such as a genuine need for a shell or package manager.

## 4. Layers and caching

- Copy dependency manifests (`go.mod`/`go.sum`, `package.json`/lockfile, etc.) and install dependencies **before** copying the source, so the dependency layer caches when only application code changes.
- Use BuildKit cache mounts for package caches: `RUN --mount=type=cache,target=<cache-dir> ...` (works in Podman/Buildah too).
- Clean package-manager caches in the **same** `RUN` layer they were created in. For apt: `apt-get install --no-install-recommends ...` then `rm -rf /var/lib/apt/lists/*`.
- Use `COPY`, not `ADD`. `ADD` only to auto-extract a local tarball. For remote files use `RUN curl` with a checksum verification, never `curl | sh`.
- In stages that pipe commands in `RUN`, set `SHELL ["/bin/bash", "-o", "pipefail", "-c"]` (hadolint DL4006).
- Vendored dependencies (for example Go's `vendor/`): build with `-mod=vendor` and do not ignore `vendor/`.

## 5. Process handling

- **Exec-form** `ENTRYPOINT` and `CMD` (`["bin","arg"]`), never shell form, so the app is PID 1 and receives signals.
- One process per container. Multiple processes are a compose/orchestration decision.
- If the app doesn't handle `SIGTERM` or doesn't reap children, run with an init: `init: true` (compose), `--init` (`run`; the Makefile does this), or `tini` in the image. Set `STOPSIGNAL` if the app expects a signal other than `SIGTERM`.
- `EXPOSE` every listening port, as documentation for people and tooling.
- `ARG` is build-time only (version pins, flags). `ENV` for runtime config is set by orchestration, not hardcoded. Never use either for secrets.

## 6. Labels

Every image sets these OCI labels:

```
org.opencontainers.image.source       literal  https://github.com/<org>/<repo>
org.opencontainers.image.title        literal
org.opencontainers.image.description  literal
org.opencontainers.image.version      ARG VERSION
org.opencontainers.image.revision     ARG REVISION
org.opencontainers.image.created      ARG CREATED
```

- Declare the dynamic `ARG`s **in the final stage, at the end**. An `ARG` declared in an earlier stage is invisible to later stages unless redeclared, and a changing value (`created`, `revision`) placed early invalidates the cache for every later layer.
- Values are passed by the Makefile locally and by the CI workflow (owned by `platform-engineer`) in pipelines.
- Equivalent alternative: CI applies labels with `--label` flags or `docker/metadata-action`. Keep the static labels in the file and note that dynamic ones are applied at build time.

## 7. Health checks

Containerfiles MUST NOT contain a `HEALTHCHECK` instruction. Health is defined where it is consumed: `healthcheck:` in compose (see `compose.md`) and the orchestration platform's own probes. As a side benefit this avoids the Podman/OCI-format problem where `HEALTHCHECK` is silently dropped.

Document the contract with a comment next to `EXPOSE`, for example `# Health: GET :8080/healthz` or `# Health: /app/svc healthcheck (defined in compose)`.

Distroless and scratch images have no shell, `curl`, or `wget`, so a `curl -f` check cannot run. Do not add a shell or curl to the runtime image just for this. Prefer a `healthcheck` subcommand in the app binary (exits 0/1) and call it from compose in exec form: `test: ["CMD", "/app/svc", "healthcheck"]`.

## 8. .dockerignore

MUST exist. Baseline is `assets/dockerignore`. It excludes at least `.git`, `.env*` (keeping `!.env.example`), key and credential files and directories, build output, and editor/OS files.

- Exclude `node_modules` (rebuild inside the container).
- Exclude `vendor` **only if** dependencies are fetched during the build. Go projects that commit `vendor/` must not exclude it. Check the repo before adding it.

## 9. Size

Record image size at review (`make size`). Flag an increase of more than 20% versus the previous release, or a runtime image above any budget the repo states. A sudden jump usually means a stray cache, a copied `node_modules`, or a full OS base.
