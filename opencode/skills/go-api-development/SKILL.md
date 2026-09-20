---
name: go-api-development
description: Build, test, review, and scaffold Go Chi REST APIs with bootstrap lifecycle management, DTOs, system health endpoints, Prometheus metrics, and optional OpenTelemetry tracing. Use for new Go HTTP services, API routes, handlers, request/response DTOs, or API observability; use golang-pro for concurrency, gRPC, profiling, generics, or advanced Go design.
---

# Go API Development

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

Use this layout for every new service unless the user specifies otherwise. The generic Chi template includes HTTP, configuration, bootstrap, logging, metrics, tracing, and ping packages; add domain packages only when the service needs them:

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
- Defer `bootstrap.Dependencies.Close()` so the OTel exporter is flushed before exiting

## Chi Boilerplate Template

Use `assets/chi-boilerplate/` only for a new REST service built with Chi. It is a generic baseline, not an auth server.

**Included**:

- `cmd/api/main.go` using the load-config, bootstrap-initialize, defer-close, and `server.New(...).Run()` lifecycle
- `internal/bootstrap` for logger and optional tracing lifecycle management
- `GET /api/v1/ping` as a complete handler, DTO, route, and use-case example
- JSON `slog` request logging, Prometheus request metrics, optional OpenTelemetry HTTP tracing, and graceful HTTP shutdown
- `GET /system/version`, `GET /system/health/live`, `GET /system/health/ready`, and `GET /system/metrics`
- `Containerfile`, `docker-compose.yaml`, `Makefile`, `.env.example`, and a router endpoint test

**Excluded**:

- Authentication, JWTs, users, roles, sessions, and identity-provider configuration
- Databases, Redis, migrations, cache adapters, and persistence dependencies
- Swagger/OpenAPI generation and application-specific domain models

Do not replace the template's `main.go` lifecycle for a new service. Keep bootstrap as the composition and cleanup boundary; add optional infrastructure there only when the intake confirms it is required.

Scaffold with:

```bash
scripts/new-chi-service.sh \
  --module github.com/acme/orders \
  --name orders \
  --destination ../orders \
  --port 8080
```

The command requires an absent destination and validates the module, service name, and port. It copies the template, replaces `{{MODULE_PATH}}`, `{{SERVICE_NAME}}`, and `{{SERVICE_PORT}}`, runs `gofmt`, and runs `go mod tidy`. Follow it with `go test ./...` and `go vet ./...`.

## Workflow

1. On a new Chi REST service: run Project Intake questions above, then scaffold with `scripts/new-chi-service.sh --module <module-path> --name <service-name> --destination <path>`.
2. Keep the template's bootstrap-based startup lifecycle. Add an adapter only when the intake answers require it.
3. Start the first API vertical slice from `GET /api/v1/ping`; retain the `/system/version`, `/system/health/live`, `/system/health/ready`, and `/system/metrics` endpoints.
4. On an existing project: inspect `go.mod`, package layout, and established test conventions before editing.
5. Make the smallest idiomatic change and run `gofmt` on modified Go files.
6. Run focused `go test` commands and `go vet` when practical.

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
