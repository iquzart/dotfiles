module {{MODULE_PATH}}

go 1.23.0

require (
	github.com/go-chi/chi/v5 v5.0.12
	github.com/prometheus/client_golang v1.20.5
	go.opentelemetry.io/contrib/instrumentation/net/http/otelhttp v0.57.0
	go.opentelemetry.io/otel v1.32.0
	go.opentelemetry.io/otel/exporters/otlp/otlptrace/otlptracegrpc v1.32.0
	go.opentelemetry.io/otel/sdk v1.32.0
	google.golang.org/grpc v1.68.1
)
