---
description: Generate a Containerfile (plus .dockerignore and Makefile, optionally compose) for this project
agent: platform-engineer
---

Load the `container-development` skill with the skill tool and follow its **Create** workflow to containerize the current project.

User arguments (may be empty): `$ARGUMENTS`

The skill lives in `~/.config/opencode/skills/container-development`. Call its scripts by full path.

Steps:

1. Inspect the project root (`go.mod`, `package.json`, existing `Containerfile`/`Dockerfile`, `compose.yaml`, `Makefile`, `.dockerignore`). If a Containerfile or Dockerfile already exists, do not overwrite it. Switch to the skill's **Optimize** workflow and tell the user.
2. Run the scaffold script, passing the user's arguments through. It auto-detects language, service name, org and repo when they are not given:
   `python ~/.config/opencode/skills/container-development/scripts/scaffold.py $ARGUMENTS`
   It creates `Containerfile`, `.dockerignore` and `Makefile` (plus `compose.yaml` and `.env.example` with `--compose`) and skips any file that already exists.
3. Adapt the generated Containerfile to the real project: build command, binary or script name, entrypoint, dependency manifests, exposed port, and whether `vendor/` is committed. Keep every rule in the skill (numeric non-root `USER`, no `HEALTHCHECK`, OCI labels, exec-form `ENTRYPOINT`).
4. Replace every `<version>`, `<NN>` and `<digest>` placeholder with a real, current pinned tag and digest. Look them up; never invent digests. Set the description label if it is still a placeholder.
5. If the project already had a `Makefile`, merge the targets from `~/.config/opencode/skills/container-development/assets/Makefile` into it instead of replacing it.
6. Verify with `python ~/.config/opencode/skills/container-development/scripts/check.py .` (resolve all Blockers and Majors) and `hadolint Containerfile` if installed.
7. Reply with the files created or skipped, the values the user must confirm (port, entrypoint, pinned versions), and any remaining findings.
