---
description: Generate a Containerfile (plus .dockerignore and Makefile, optionally compose) for this project
agent: platform-engineer
---

Load the `container-development` skill with the skill tool and follow its **Create** workflow to containerize the current project.

User arguments (may be empty): `$ARGUMENTS`

The skill lives in `~/.config/opencode/skills/container-development`. Call its scripts by full path.

Steps:

1. Inspect the project root (`go.mod`, `package.json`, existing `Containerfile`/`Dockerfile`, `compose.yaml`, `Makefile`, `.dockerignore`). If a Containerfile or Dockerfile already exists, do not overwrite it. Switch to the skill's **Optimize** workflow and tell the user.
2. Run `python ~/.config/opencode/skills/container-development/scripts/scaffold.py` with the user's flags. Fill in any missing `--name`, `--lang`, `--port`, `--org`, and `--repo` from the project.
   It creates `Containerfile`, `.dockerignore` and `Makefile` (plus `compose.yaml` and `.env.example` with `--compose`) and skips any file that already exists.
3. Adapt values and build commands in place, preserving the template's instruction order. Keep exactly one OCI `ARG`/`LABEL` block immediately after the runtime `FROM`, with `ENTRYPOINT` and any `CMD` at the end.
4. Replace every `<version>`, `<NN>` and `<digest>` placeholder with a real, current pinned tag and digest. Look them up; never invent digests. Set the description label if it is still a placeholder.
5. If the project already had a `Makefile`, merge the targets from `~/.config/opencode/skills/container-development/assets/makefile` into it instead of replacing it.
6. Verify with `python ~/.config/opencode/skills/container-development/scripts/check.py .` (resolve all Blockers and Majors) and `hadolint Containerfile` if installed. Confirm the generated Containerfile still follows the template order in step 3.
7. Reply with the files created or skipped, the values the user must confirm (port, entrypoint, pinned versions), and any remaining findings.
