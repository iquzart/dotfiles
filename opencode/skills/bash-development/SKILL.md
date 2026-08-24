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
- Quote variable expansions and paths. Use arrays for argument lists; do not build shell commands as strings.
- Validate required arguments and environment variables with clear error messages.
- Use `mktemp` and `trap` to clean up temporary resources.
- Never print secrets, use `eval`, or use unbounded destructive commands.
- Make side effects explicit and offer a `--dry-run` option for operational scripts when practical.

## Output

State the validation run and any environment or tool prerequisites.
