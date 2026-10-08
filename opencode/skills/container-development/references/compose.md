# Compose reference

Template: `assets/compose.yaml` (app plus optional Postgres). Compose is a local/dev tool in this skill.

## File naming

- New projects: `compose.yaml` (the Compose Spec's preferred name).
- Repos that already have `docker-compose.yaml`: keep it. Don't rename without asking.
- No top-level `version:` key.

## MUST

- Service name matches the repo/component name, not `app` or `web`.
- Explicit named network per stack. Don't rely on the default bridge across unrelated stacks.
- No plaintext secrets or real `.env` values in the file or repo. Use `env_file` pointing to a gitignored `.env`, commit a `.env.example` with placeholders, and note that real environments inject variables through their orchestration platform. Never hold production secrets in compose.
- Pinned image tags for every service, including databases and caches. No `latest`.
- `deploy.resources.limits` (cpus and memory) on every service, so constrained behavior is tested early.
- `healthcheck` on every service that others depend on, and dependents use `depends_on: { <svc>: { condition: service_healthy } }`. Started does not mean ready. This is the only place health is defined for local stacks (the Containerfile has no `HEALTHCHECK`).
- Named volumes. No anonymous volumes.

## SHOULD (hardening defaults for locally built services)

- `cap_drop: [ALL]`; add back only what's needed, with a comment
- `security_opt: [no-new-privileges:true]`
- `read_only: true` with `tmpfs: [/tmp]` for paths that must be writable
- `user: "<uid>:<gid>"` where the image doesn't set a numeric user
- `init: true` for apps that don't handle signals
- Ports on loopback for local dev (`"127.0.0.1:8080:8080"`), not `0.0.0.0`

## Notes

- Third-party images (like `postgres`) often need some capabilities back. Add only what the image requires and comment why (the asset does this for Postgres).
- On minimal images the app healthcheck uses exec form with an app subcommand: `test: ["CMD", "/app/svc", "healthcheck"]`. `CMD-SHELL` only works where the image has a shell.
- Use `$$` to escape `$` inside `healthcheck.test` so compose doesn't interpolate it.
- Build args for labels come from the environment (`VERSION`, `REVISION`, `CREATED`) with defaults, so `make up` and plain `compose up` both work.
