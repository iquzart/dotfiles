---
name: go-development
description: Go applications, libraries, CLIs, APIs, tests, modules, and debugging. Use when writing, editing, reviewing, or debugging ordinary Go code; use golang-pro for concurrency, gRPC, profiling, generics, or advanced Go design.
---

# Go Development

## Workflow

1. Inspect `go.mod`, package layout, and established test conventions before editing.
2. Make the smallest idiomatic change and run `gofmt` on modified Go files.
3. Run focused `go test` commands and `go vet` when practical.

## Rules

- Handle errors explicitly and add context with `%w` when returning them.
- Accept `context.Context` as the first argument for request-scoped or blocking operations.
- Keep exported APIs small and document exported identifiers when project conventions require it.
- Avoid new interfaces until there is a consumer boundary that needs one.
- Do not introduce goroutines without a defined lifecycle, cancellation behavior, and error path.
- Do not change module dependencies without a concrete requirement.

## Escalation

Load `golang-pro` for goroutines, channels, gRPC, generics, benchmarks, pprof, race conditions, or performance-sensitive design.
