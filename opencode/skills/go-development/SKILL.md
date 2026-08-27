---
name: go-development
description: Go applications, libraries, CLIs, APIs, tests, modules, and debugging. Use when writing, editing, reviewing, or debugging ordinary Go code; use golang-pro for concurrency, gRPC, profiling, generics, or advanced Go design.
---

# Go Development

## Project Intake (new project/service only)

Before scaffolding a new Go service, ask the user:

1. **Tracing** — Enable OpenTelemetry tracing? (yes/no, default no)
2. **Metrics** — Enable Prometheus metrics? (yes/no, default yes)
3. **Persistence** — Does this service need a database? If yes, which (PostgreSQL, etc.) and does it need migrations?
4. **Cache** — Does this service need a cache layer (Redis, etc.)?
5. **API style** — REST only, or REST + gRPC?
6. **Auth** — Does this service need JWT/session auth, or is it internal/unauthenticated?
7. **Deployment target** — Container only, or also needs Helm chart / Kubernetes manifests? (route to platform-engineer if the latter)

Use the answers to decide which `internal/adapters/*` packages to scaffold — don't generate cache, database, or auth code the service doesn't need.

## Standard Structure (hexagonal)

Use this layout for every new service unless the user specifies otherwise:

```
cmd/api/main.go              # entrypoint: wiring, graceful shutdown
internal/
  core/
    entities/                # domain types
    repositories/            # interfaces (ports) the domain depends on
    services/                # domain services (e.g. jwt_service.go)
  app/usecases/               # application logic, orchestrates core + ports
  adapters/
    http/
      handlers/               # one file per resource + health/version/metrics
      middleware/              # logging, metrics, (tracing if enabled)
      router/                  # route composition
      routes/                  # api_routes.go, system_routes.go
      dto/                     # request/response shapes
      server/                  # http.Server setup, graceful shutdown
    database/<engine>/         # connection, migration, repository impls
    cache/<engine>/            # connection, repository impls
  meta/
    logger.go                  # slog setup
    metrics.go                  # Prometheus registry/handlers
    tracing.go                  # OTel setup (present but no-op if disabled)
  config/config.go
migrations/
infra/                          # grafana-datasources.yaml, otel-collector.yaml, prometheus.yaml, tempo.yaml
docs/                           # swagger/OpenAPI
Containerfile
docker-compose.yaml
Makefile
```

Keep `core` free of framework/adapter imports — it must not know about HTTP, Postgres, or Redis directly, only through `repositories` interfaces.

## Observability Requirements

**Endpoints** — group under a single `/system` route prefix, separate from `/api`:

- `GET /system/version`
- `GET /system/health/ready`
- `GET /system/health/live`
- `GET /system/metrics`

Register all four from one `system_routes.go`, mounted once in `router.go` — don't scatter them across handler files.

**Logging** — `slog` with JSON handler by default.

- If tracing is enabled for the service, inject `trace_id` into every log record via a `slog.Handler` wrapper that reads the trace ID from context — not by manually adding it at each call site.
- If tracing is disabled, logs must not reference or fail on a missing trace context.

**Metrics** — expose via `/system/metrics` in Prometheus format. Wire request-duration/count middleware at the router level (`middleware/metrics.go`), not per-handler.

**Tracing** — OTel, toggled by config (`config.TracingEnabled` or equivalent). When disabled, `meta/tracing.go` should provide a no-op tracer so the rest of the codebase never needs `if tracingEnabled` checks scattered around — one place decides, everywhere else just calls the tracer.

**Graceful shutdown** — `cmd/api/main.go` must:

- Listen for `SIGINT`/`SIGTERM`
- Stop accepting new requests, drain in-flight ones with a bounded timeout (`http.Server.Shutdown(ctx)`)
- Close database/cache connections and flush the OTel exporter (if tracing enabled) before exiting

## Workflow

1. On a new project: run Project Intake questions above, then scaffold using the Standard Structure, including only the adapters the answers call for.
2. On an existing project: inspect `go.mod`, package layout, and established test conventions before editing.
3. Make the smallest idiomatic change and run `gofmt` on modified Go files.
4. Run focused `go test` commands and `go vet` when practical.

## Rules

- Handle errors explicitly and add context with `%w` when returning them.
- Accept `context.Context` as the first argument for request-scoped or blocking operations.
- Keep exported APIs small and document exported identifiers when project conventions require it.
- Avoid new interfaces until there is a consumer boundary that needs one.
- Do not introduce goroutines without a defined lifecycle, cancellation behavior, and error path.
- Do not change module dependencies without a concrete requirement.
- Do not put HTTP, database, or cache types in `internal/core` — only in `internal/adapters`.
- Do not hardcode `/system` or `/api` route registration inline in `main.go` — always compose via `router.go`.

## Escalation

Load `golang-pro` for goroutines, channels, gRPC, generics, benchmarks, pprof, race conditions, or performance-sensitive design.
