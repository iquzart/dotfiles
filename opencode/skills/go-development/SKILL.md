---
name: go-development
description: Build, test, review, and debug ordinary Go applications, libraries, CLIs, modules, and packages. Use for idiomatic Go code, errors, contexts, interfaces, dependency management, and tests. Use go-api-development for Chi HTTP APIs and service scaffolding; use golang-pro for concurrency, gRPC, profiling, generics, or advanced Go design.
---

# Go Development

## Workflow

1. Inspect `go.mod`, package layout, and existing test conventions before editing.
2. Make the smallest idiomatic change that satisfies the requirement.
3. Run `gofmt` on modified Go files.
4. Run focused `go test` commands; run `go vet` when practical.

## Rules

- Return errors explicitly and wrap errors that cross a package boundary with `%w` when context helps.
- Accept `context.Context` as the first argument for request-scoped or blocking work.
- Keep package APIs small; add interfaces only for a real consumer boundary.
- Keep exported identifiers documented when project conventions or `golint`-style tooling require it.
- Do not introduce goroutines without defined ownership, cancellation, completion, and error handling.
- Do not add dependencies or change `go.mod` without a concrete requirement.
- Prefer table-driven tests where multiple input/output cases are being verified.
- Preserve existing project conventions over generic preferences.

## Routing

- Load `go-api-development` for Chi REST services, HTTP handlers, DTOs, health endpoints, metrics, tracing, or the Chi boilerplate.
- Load `golang-pro` for goroutines, channels, gRPC, generics, benchmarks, pprof, race conditions, or performance-sensitive design.
