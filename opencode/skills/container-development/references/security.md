# Security reference

Rule tiers: **MUST** is never broken (Blocker or Major in review). **SHOULD** is the default; deviating needs a one-line comment in the file explaining why.

## Contents

1. MUST rules
2. Secrets
3. Pinning and update automation
4. SHOULD rules

## 1. MUST rules

- **Never `latest`** for any base image, including third-party images in compose. Pin a version, and a digest (`image:tag@sha256:...`) for production images.
- **Run as non-root with a numeric UID.** Set `USER <uid>:<gid>` before `ENTRYPOINT`. Kubernetes `runAsNonRoot` cannot verify a non-numeric username such as `USER app`. Numeric IDs also work on `scratch`, which has no `/etc/passwd`. Use the base image's built-in non-root ID where it has one (distroless `nonroot` is 65532; the Node images' `node` user is 1000); otherwise 10001.
- **No secrets in `ARG`, `ENV`, or `COPY`,** in any stage.
- **`.dockerignore` exists.**
- **No `HEALTHCHECK` instruction** (see `containerfile.md`).
- **Exec-form `ENTRYPOINT` and `CMD`.**

## 2. Secrets

Secrets baked into the final image are visible in `docker history` and the filesystem. Secrets in an earlier build stage don't ship in the final image, but they persist in the local build cache, in any exported or shared CI cache, and in any pushed image of that stage (for example one built with `--target build`). So the rule applies to every stage.

For build-time secrets (private registries, private dependencies) use a BuildKit secret mount:

```dockerfile
RUN --mount=type=secret,id=npmrc,target=/root/.npmrc npm ci
```

built with `--secret id=npmrc,src=$HOME/.npmrc`. For private git dependencies use `RUN --mount=type=ssh`.

Runtime secrets are injected by the platform at runtime, never at build time. For local compose, use `env_file` pointing to a gitignored `.env` and commit a `.env.example` with placeholders only.

## 3. Pinning and update automation

Digest pinning without an update process produces stale, vulnerable base images. Whenever you pin:

- Confirm Renovate or Dependabot covers the Containerfile and compose file. Dependabot's Docker updater keys off `Dockerfile` names, so a `Containerfile` may need Renovate or a custom manager; verify.
- If there is no automation, flag it as a Major finding and offer a minimal config. Don't add one unprompted if the team uses a different tool.

## 4. SHOULD rules

- **Minimal runtime base** (selection order is in `containerfile.md`).
- **No unnecessary packages:** no debug tools, editors, or package-manager caches in the runtime stage.
- **Read-only root filesystem where feasible.** Comment it in the runtime stage and mirror it with `read_only: true` plus `tmpfs` in compose and `--read-only --tmpfs /tmp` in the Makefile `run` target.
- **Drop capabilities and block privilege escalation** at run time: `cap_drop: [ALL]`, `no-new-privileges` (compose and Makefile `run`).
- **Bind published ports to loopback** for local dev unless other machines must reach the service.
- **Signals:** use an init when the app doesn't handle `SIGTERM` (see `containerfile.md`).
