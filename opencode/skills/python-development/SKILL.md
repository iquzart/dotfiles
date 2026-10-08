---
name: python-development
description: Write, edit, review, refactor, and debug Python code, including applications, libraries, CLIs, scripts, tests, type hints, packaging, and dependency management. Use this skill whenever the user works with .py files, pyproject.toml, requirements.txt, pytest, mypy/pyright, ruff, uv, poetry, pip, virtualenvs, or pastes a Python traceback or failing test, even if they don't explicitly say "Python".
---

# Python Development

Follow the conventions already present in the repository. A change that matches
the surrounding code is easier to review and less likely to break things than
one that is "better" in isolation.

## Workflow

1. **Orient before editing.** Check `pyproject.toml` (or `setup.cfg`/`setup.py`),
   lock files (`uv.lock`, `poetry.lock`, `requirements*.txt`), CI config, and
   existing tests. This tells you the Python version, package manager, formatter,
   linter, type checker, and test framework in use.
2. **Reproduce first when fixing bugs.** Write or run a failing test, or a minimal
   script, before changing code. A fix without a reproduction is a guess.
3. **Make the smallest change that solves the problem.** Avoid drive-by
   refactors, renames, or reformatting of unrelated code; they bury the real
   change in the diff.
4. **Verify with the project's own tools.** Run, where configured: formatter,
   linter, type checker, then the focused tests for the changed code before
   the full suite. Use the commands from CI/Makefile/`pyproject.toml` rather
   than assuming defaults.
5. **Report honestly.** State what you ran and the result. If something
   couldn't be run (missing dependency, no tests, no network), say so rather
   than implying it passed.

If the repo has no tooling configured, don't introduce new tools unprompted.
Mention the gap and suggest options.

## Code rules

**Environment and dependencies**

- Match the project's Python version and package manager. Don't use syntax
  or stdlib features newer than the minimum supported version (for example,
  `match` or `X | Y` types on 3.8/3.9).
- Add a dependency only when the standard library or existing dependencies
  can't reasonably do the job. Every dependency is a long-term maintenance
  and supply-chain cost. When you add one, update the manifest and lock file
  the way the project does.

**Typing**

- Annotate public functions, methods, and non-obvious internal boundaries.
  Prefer precise types (`Sequence`, `Mapping`, `Protocol`, `TypedDict`,
  dataclasses) over `Any`.
- Don't silence the type checker with blanket `# type: ignore`; if one is
  unavoidable, scope it and add a short reason.

**Errors and logging**

- Raise specific exceptions with actionable messages (what failed, with which
  input, what the caller can do). Define custom exceptions for library
  boundaries.
- Don't use bare `except:` or swallow `Exception`. Catch the narrowest type, and
  either handle it meaningfully or re-raise (`raise ... from err` to keep the cause).
- Use `logging` rather than `print` in libraries and services; keep `print` for
  CLI output meant for users.

**Structure**

- Keep I/O (network, filesystem, subprocess, clock, randomness) at the edges and
  pass dependencies in, so core logic can be tested without mocks of the world.
- Prefer small functions with clear inputs and outputs over classes with hidden
  state. Use dataclasses or pydantic-style models (if already in the project) for
  structured data.
- Avoid mutable default arguments and import-time side effects.
- Use context managers for files, locks, connections, and temporary resources.
- For async code, don't call blocking functions inside coroutines, and don't mix
  sync and async APIs without a clear boundary.

**Paths, data, and security**

- Use `pathlib` for filesystem paths; avoid string concatenation.
- Use parameterized queries for all database access; never build SQL with
  f-strings or `%` formatting.
- Never pass user input to `shell=True`, `eval`, `exec`, or `pickle.loads`.
  Pass subprocess arguments as a list.
- Never hardcode secrets, tokens, hostnames, or environment-specific paths. Read
  them from environment variables or config, and don't log them.

**Style**

- Defer to the project's formatter and linter over personal preference. When
  none exists, follow PEP 8 and keep naming consistent with nearby code.
- Write docstrings for public APIs in the style the repo already uses. Comment
  the *why*, not the *what*.

## Testing

- Add or update tests whenever behavior changes, including a regression test
  for each bug fix.
- Use pytest conventions if the repo uses pytest (plain `assert`, fixtures,
  `parametrize`, `tmp_path`, `monkeypatch`). Otherwise preserve the existing
  framework (`unittest`, etc.).
- Test behavior, not implementation details. Cover the normal case, edge cases
  (empty, `None`, boundaries), and error paths.
- Keep tests fast and deterministic: no real network, no dependence on the
  current time or test order. Mock only at I/O boundaries.

## Debugging

- Read the full traceback, starting from the bottom, and identify the first frame
  in the project's own code.
- Form a hypothesis, then confirm it with a targeted print, log, debugger
  (`breakpoint()`), or minimal test before changing code.
- Fix the root cause, not the symptom. If you must add a guard, say why the
  bad state occurs.

## Reviewing code

Prioritize in this order: correctness and edge cases, security, error handling,
test coverage, API design and types, then style. Give specific, actionable
comments, and say which are blocking versus optional.
