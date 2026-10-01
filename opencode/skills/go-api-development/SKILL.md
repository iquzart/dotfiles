---

name: go-api-development
description: Build, test, review, and scaffold Go Chi REST APIs with bootstrap lifecycle management, DTOs, system health endpoints, Prometheus metrics, Swagger/OpenAPI, and optional OpenTelemetry tracing. Every new Go API service must be generated from the included scaffold, even when the request does not mention Chi or scaffolding. Use for new Go HTTP services, API routes, handlers, request/response DTOs, or API observability; use golang-pro for concurrency, gRPC, profiling, generics, or advanced Go design
---------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

# Go API Development

Build Go HTTP APIs using the repository's required Chi scaffold and hexagonal architecture.

## Project Intake

For a new service, determine:

1. **Tracing** — Enable OpenTelemetry tracing? Default: no.
2. **Metrics** — Enable Prometheus metrics? Default: yes.
3. **Persistence** — Does the service need a database? If yes, which database and does it need migrations?
4. **Cache** — Does the service need a cache layer such as Redis?
5. **API style** — REST only, or REST + gRPC?
6. **Auth** — JWT/session auth, or internal/unauthenticated?
7. **Deployment target** — Container only, or also Helm/Kubernetes manifests? Route deployment-specific work to `platform-engineer`.

Ask only questions that cannot be determined from the request or repository.

Use the answers to decide which `internal/adapters/*` packages are required. Do not generate unused database, cache, or auth code.

Swagger/OpenAPI is mandatory for every API and is not an intake option.

## New Services

Every new Go API must be generated from the included Chi scaffold:

```bash
scripts/new-chi-service.sh \
  --module <module-path> \
  --name <service-name> \
  --destination <path> \
  --port 8080
```

Port `8080` is mandatory.

The destination must be absent. The script validates the module, service name, and port, copies the template, replaces:

```text
{{MODULE_PATH}}
{{SERVICE_NAME}}
{{SERVICE_PORT}}
```

then runs `gofmt` and `go mod tidy`.

Do not hand-build a new API or replace the scaffold's `main.go` lifecycle.

## Standard Structure

Use this hexagonal structure:

```text
cmd/api/main.go
internal/
  core/
    entities/
    repositories/
    services/
  app/usecases/
  adapters/
    http/
      handlers/
      middleware/
      router/
      routes/
      dto/
      server/
    database/<engine>/
    cache/<engine>/
  meta/
    logger.go
    metrics.go
    tracing.go
  config/config.go
migrations/
infra/
docs/                         # Swagger/OpenAPI
Containerfile
docker-compose.yaml
Makefile
```

The generic scaffold provides the HTTP, configuration, bootstrap, logging, metrics, tracing, Swagger/OpenAPI, and ping baseline. Add domain, database, cache, or auth packages only when required.

Keep `internal/core` free of framework and adapter imports. It must not know about HTTP, PostgreSQL, Redis, or other infrastructure directly. Use repository interfaces for domain dependencies.

## Required API Endpoints

Every new service retains:

```text
GET /api/v1/ping

GET /system/version
GET /system/health/ready
GET /system/health/live
GET /system/metrics
```

Register all `/system` endpoints from one `system_routes.go` and mount them once through `router.go`.

Do not scatter system route registration across handlers or `main.go`.

## HTTP Design

Keep HTTP concerns under:

```text
internal/adapters/http/
```

### Handlers

Handlers should:

1. Parse and validate HTTP input.
2. Convert DTOs to application input.
3. Call the use case.
4. Convert results to response DTOs.
5. Return the HTTP response.

Handlers must not contain business logic.

### DTOs

Keep request/response DTOs under:

```text
internal/adapters/http/dto/
```

Do not expose domain entities directly as API contracts unless intentionally required.

### Routes

Keep route composition separate from handlers.

Do not register `/api` or `/system` routes directly in `main.go`.

## Swagger/OpenAPI

Every API must include an OpenAPI specification and Swagger UI.

Document:

* API endpoints
* request DTOs
* response DTOs
* path parameters
* query parameters
* authentication requirements when applicable
* HTTP status codes
* error responses

Keep the OpenAPI specification synchronized with the implemented API.

Swagger/OpenAPI belongs under:

```text
docs/
```

Do not omit or remove API documentation for a new service.

## Observability

### Logging

Use JSON `slog`.

When tracing is enabled, inject `trace_id` into log records through a `slog.Handler` wrapper that reads the trace ID from context.

Do not manually add trace IDs at individual call sites.

When tracing is disabled, logging must work without trace context.

### Metrics

Expose Prometheus metrics through:

```text
GET /system/metrics
```

Register request count and duration middleware at the router level in:

```text
internal/adapters/http/middleware/metrics.go
```

Do not instrument every handler individually.

### Tracing

Tracing is optional and controlled by configuration such as `config.TracingEnabled`.

When disabled, `meta/tracing.go` provides a no-op tracer so application code does not need scattered tracing checks.

## Bootstrap and Shutdown

Keep bootstrap as the composition and cleanup boundary.

`cmd/api/main.go` must:

* load configuration
* initialize bootstrap dependencies
* create the server
* listen for `SIGINT`/`SIGTERM`
* stop accepting new requests
* drain in-flight requests using bounded `http.Server.Shutdown(ctx)`
* defer `bootstrap.Dependencies.Close()`

Dependency cleanup must allow resources such as the OTel exporter to flush before exit.

## Database

Add database infrastructure only when required:

```text
internal/adapters/database/<engine>/
```

Database-specific types and implementations remain inside the adapter.

If migrations are required:

```text
migrations/
```

Do not introduce an ORM or migration framework without a concrete requirement or existing project convention.

## Cache

Add cache infrastructure only when required:

```text
internal/adapters/cache/<engine>/
```

Cache-specific types remain inside the adapter.

Do not add Redis or another cache dependency unless the service requires it.

## Authentication

Authentication is not part of the generic scaffold.

Add JWT/session/authentication infrastructure only when required.

Do not add users, roles, sessions, or identity-provider configuration to services that do not need them.

## Chi Boilerplate

Use:

```text
assets/chi-boilerplate/
```

for every new API service.

It includes:

* `cmd/api/main.go`
* `internal/bootstrap`
* configuration
* logging
* metrics
* optional tracing
* graceful shutdown
* `GET /api/v1/ping`
* system endpoints
* Swagger/OpenAPI
* `Containerfile`
* `docker-compose.yaml`
* `Makefile`
* `.env.example`
* router endpoint test

It excludes:

* authentication
* JWTs
* users
* roles
* sessions
* databases
* Redis
* migrations
* application-specific domain models

Add excluded components only when required by the service.

## Existing Services

Before modifying an existing service:

1. Inspect `go.mod`.
2. Inspect the package layout.
3. Inspect router, bootstrap, configuration, and test conventions.
4. Follow existing project patterns.
5. Make the smallest idiomatic change.

Do not restructure an existing service to match the scaffold unless explicitly requested.

## Workflow

### New Service

1. Determine requirements from the request and repository.
2. Ask only unresolved intake questions.
3. Run `scripts/new-chi-service.sh`.
4. Preserve the bootstrap lifecycle.
5. Retain `/api/v1/ping` and all `/system` endpoints.
6. Implement the required vertical slice.
7. Add only required adapters.
8. Add/update Swagger/OpenAPI documentation.
9. Add/update tests.
10. Run `gofmt`.
11. Run focused tests.
12. Run `go test ./...`.
13. Run `go vet ./...`.

### Existing Service

1. Inspect the existing project structure and conventions.
2. Make the smallest required change.
3. Update Swagger/OpenAPI when the API contract changes.
4. Add/update tests.
5. Run `gofmt`.
6. Run focused tests.
7. Run `go vet ./...` when practical.

## Rules

* Handle errors explicitly.
* Add error context with `%w` when returning errors.
* Accept `context.Context` as the first argument for request-scoped or blocking operations.
* Keep exported APIs small and document exported identifiers when project conventions require it.
* Avoid new interfaces until there is a consumer boundary that needs one.
* Do not introduce goroutines without a defined lifecycle, cancellation behavior, and error path.
* Do not change module dependencies without a concrete requirement.
* Do not put HTTP, database, or cache types in `internal/core`.
* Do not hardcode `/system` or `/api` route registration in `main.go`.
* Do not remove Swagger/OpenAPI from an API service.
* Keep Swagger/OpenAPI synchronized with the implemented API.

## Validation

After scaffolding:

```bash
go test ./...
go vet ./...
```

Run focused tests first when appropriate.

Run:

```bash
go test -race ./...
```

when the change involves concurrency or race-sensitive code.

## Escalation

Load `golang-pro` for:

* goroutines
* channels
* gRPC
* generics
* benchmarks
* profiling
* pprof
* race conditions
* performance-sensitive design

Route Kubernetes/Helm/deployment-specific work to `platform-engineer`.
