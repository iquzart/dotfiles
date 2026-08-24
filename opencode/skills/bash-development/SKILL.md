---
name: bash-development
description: Bash shell scripts, CLI automation, POSIX portability, ShellCheck, and safe command handling. Use when writing, editing, reviewing, or debugging Bash scripts.
---

# Bash Development

## Workflow

1. Read the existing script and its callers before editing.
2. Prefer Bash only when its process orchestration is simpler than Python or Go.
3. Run `shellcheck` when it is available and execute a focused test or dry run.

## Rules

- Start executable scripts with `#!/usr/bin/env bash` and use `set -euo pipefail` unless an existing compatibility requirement prevents it.
- Begin every script with a concise comment header that states its purpose.
- Structure scripts around a `main` function and invoke it with `main "$@"`.
- Keep functions small and focused so behavior is readable and can be extended without growing a monolithic `main` function.
- Use colored, timestamped logging in the conceptual format `datetime [info] message` (for example, `2026-08-24T12:34:56Z [INFO] deploying service`). Enable color only when the destination is a terminal and color support is available; always retain readable, uncolored output otherwise.
- Quote variable expansions and paths. Use arrays for argument lists; do not build shell commands as strings.
- Validate required arguments and environment variables with clear error messages.
- Use `mktemp` and `trap` to clean up temporary resources.
- Never print secrets, use `eval`, or use unbounded destructive commands.
- Make side effects explicit and offer a `--dry-run` option for operational scripts when practical.

## Output

State the validation run and any environment or tool prerequisites.
