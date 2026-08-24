---
name: python-development
description: Python applications, libraries, CLIs, tests, typing, packaging, and debugging. Use when writing, editing, reviewing, or debugging Python code.
---

# Python Development

## Workflow

1. Inspect `pyproject.toml`, dependency lock files, and existing test conventions first.
2. Make the smallest typed change that fits the repository's architecture.
3. Run the project's formatter, linter, type checker, and focused tests when configured.

## Rules

- Follow the Python version and package manager already used by the project.
- Add type annotations to public functions and non-obvious internal boundaries.
- Raise specific exceptions with actionable context; do not catch broad exceptions without re-raising or handling them.
- Keep I/O at application boundaries and make business logic testable without network or filesystem dependencies.
- Use `pathlib` for filesystem paths and parameterized database APIs for database access.
- Do not add dependencies without a concrete need or hardcode credentials and environment-specific values.

## Testing

- Add or update focused tests when behavior changes.
- Prefer pytest conventions when the repository uses pytest; otherwise preserve the existing framework.
