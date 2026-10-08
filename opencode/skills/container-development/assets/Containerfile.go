# syntax=docker/dockerfile:1
# Resolve every <version>, <NN> and <digest> to a real pinned value before use.
# If the project commits vendor/, add -mod=vendor to the build and do not ignore vendor/.
ARG BUILD_IMAGE=golang:<version>-bookworm@sha256:<digest>
ARG RUNTIME_IMAGE=gcr.io/distroless/static-debian<NN>:nonroot@sha256:<digest>

# ---- Build stage ----
FROM ${BUILD_IMAGE} AS build
WORKDIR /src
COPY go.mod go.sum ./
RUN --mount=type=cache,target=/go/pkg/mod go mod download
COPY . .
RUN --mount=type=cache,target=/go/pkg/mod \
    --mount=type=cache,target=/root/.cache/go-build \
    CGO_ENABLED=0 go build -trimpath -ldflags="-s -w" -o /out/{{NAME}} ./cmd/{{NAME}}

# ---- Runtime stage ----
FROM ${RUNTIME_IMAGE}
# Dynamic labels last in the final stage so changing values don't bust the cache
ARG VERSION=dev
ARG REVISION=unknown
ARG CREATED=unknown
LABEL org.opencontainers.image.source="https://github.com/{{ORG}}/{{REPO}}" \
      org.opencontainers.image.title="{{NAME}}" \
      org.opencontainers.image.description="{{DESCRIPTION}}" \
      org.opencontainers.image.version="${VERSION}" \
      org.opencontainers.image.revision="${REVISION}" \
      org.opencontainers.image.created="${CREATED}"


# Runtime notes: supports --read-only; no writable paths required
WORKDIR /app
COPY --from=build --chown=65532:65532 /out/{{NAME}} /app/{{NAME}}
USER 65532:65532
# Health: /app/{{NAME}} healthcheck (defined in compose / orchestration, not here)
EXPOSE {{PORT}}
ENTRYPOINT ["/app/{{NAME}}"]


