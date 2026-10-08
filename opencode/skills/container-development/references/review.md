# Review and optimize reference

Use in the **Optimize** workflow, and for the final verification of the **Create** workflow.

## Contents

1. Procedure
2. Report format and severities
3. Optimization checklist
4. Before/after summary

## 1. Procedure

1. Run `python scripts/check.py <path>`. It covers the mechanical rules. Then review by hand what a script can't judge (base-image fit, layer order, whether `vendor` should be ignored).
2. Run `hadolint <file>` if installed. It works regardless of filename. Local linting is in scope; executing image vulnerability scans is not.
3. Merge the findings into one report, ordered by severity.
4. **Flag, don't silently fix.** Report first, then apply fixes only after the user agrees. The three most common regressions are `latest`, running as root, and missing OCI labels.
5. Re-run `check.py` after the changes.

## 2. Report format and severities

One line per finding:

`[Severity] <file>:<line> - <issue> - <fix>`

| Severity | Examples |
|---|---|
| **Blocker** | `latest` or untagged base, unresolved `<version>`/`<digest>` placeholder, root user in runtime stage, secrets in `ARG`/`ENV`/`COPY`, missing `.dockerignore` |
| **Major** | `HEALTHCHECK` in a Containerfile, missing OCI labels, non-numeric `USER`, shell-form `ENTRYPOINT`/`CMD`, single-stage build, no digest-update automation, missing Makefile, compose without limits, healthchecks, or healthy-dependency ordering, compose without a named network |
| **Minor** | Tag not digest-pinned, Alpine without testing, missing `--no-install-recommends` or apt list cleanup, `ADD` instead of `COPY`, `COPY . .` before dependency install, no `EXPOSE`, no init/`STOPSIGNAL`, compose ports on `0.0.0.0`, missing `cap_drop`/`no-new-privileges`, service named `app`/`web`, size growth |

End with a count per severity.

## 3. Optimization checklist

Work through these in order when the goal is "smaller" or "faster":

**Size**
- Is the runtime base the smallest one that works? (`containerfile.md` section 3.) Static binary to `scratch`/distroless static is usually the biggest win.
- Does anything from the build toolchain reach the final image? Copy only the artifact.
- Production dependencies only in the runtime stage (`npm ci --omit=dev`, `pip install --no-cache-dir`, no dev packages).
- Package caches and apt lists cleaned in the same `RUN`.
- `.dockerignore` keeps the build context small (check the "Sending build context" size).
- Strip binaries where appropriate (`-ldflags="-s -w"`, `-trimpath` for Go).

**Cache and build speed**
- Dependency manifests are copied and dependencies installed before the source copy.
- Dynamic label `ARG`s are in the final stage, at the end.
- BuildKit cache mounts for package-manager and compiler caches.
- Stages that don't depend on each other can build in parallel (separate `FROM` stages, BuildKit builds them concurrently).
- Frequently changing files come last in each stage.

**Runtime**
- Read-only root filesystem works, with a tmpfs for the paths that need writing.
- Init in place if the app doesn't handle signals.

Do not apply an optimization that changes behavior (base image family, musl vs glibc) without calling it out and, where possible, testing it.

## 4. Before/after summary

When optimizing, report: image size before and after (`make size`), build time for a cold and a warm build if measured, the findings fixed by severity, and anything intentionally left (with the reason).
