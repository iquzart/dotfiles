# Makefile reference

Template: `assets/Makefile`. A `Makefile` is **required** whenever a Containerfile or compose file is created. It gives every project one consistent local interface and documents the exact build invocation, including label `ARG`s.

## Rules

- If a `Makefile` exists, add the targets below to it. Never overwrite it. If a target name collides, prefix the new one (`container-build`) and mention it.
- Targets are local-development conveniences. **No push, scan, sign, or deploy targets.** Those belong to CI/CD. CI may call `make lint` for parity.
- Recipe lines MUST be indented with tabs.
- All settings are overridable with `?=` (for example `make build ENGINE=podman`).
- Include the compose targets only when a compose file exists.
- `make help` is the default goal and lists targets from their `##` comments.

## Targets

| Target | Purpose |
|---|---|
| `help` | List targets (default) |
| `build` | Build locally, passing `VERSION`, `REVISION`, `CREATED` as build args; tags `<image>:<version>` and `<image>:dev` |
| `run` | Run the built image hardened: `--init --read-only --tmpfs /tmp --cap-drop ALL --security-opt no-new-privileges`, port bound to loopback |
| `lint` | `hadolint` on the Containerfile; plus `compose config --quiet` when compose exists |
| `size` | Print the built image size in MB |
| `clean` | Remove locally built images |
| `up`, `down`, `logs`, `ps`, `config` | Compose only. `up` creates `.env` from `.env.example` if missing |

## Variables

| Variable | Default |
|---|---|
| `ENGINE` | `docker` if installed, else `podman` |
| `COMPOSE` | `$(ENGINE) compose` |
| `IMAGE` | the service name |
| `CONTAINERFILE` | `Containerfile` |
| `PORT` | the service port |
| `VERSION` | `git describe --tags --always --dirty`, else `dev` |
| `REVISION` | `git rev-parse HEAD`, else `unknown` |
| `CREATED` | UTC timestamp |

## Merging into an existing Makefile

1. Read the existing file and note its targets and variable names.
2. Append only the missing targets, converting to the project's naming where it already has equivalents.
3. Keep `.PHONY` accurate and don't change the existing default goal.
4. Tell the user which targets were added or renamed.
