package meta

import (
	"net/http"

	"github.com/prometheus/client_golang/prometheus"
	"github.com/prometheus/client_golang/prometheus/promhttp"
)

type Metrics struct {
	Requests *prometheus.CounterVec
	Duration *prometheus.HistogramVec
	registry *prometheus.Registry
}

func NewMetrics() *Metrics {
	requests := prometheus.NewCounterVec(prometheus.CounterOpts{Name: "http_requests_total", Help: "Total HTTP requests."}, []string{"method", "route", "status"})
	duration := prometheus.NewHistogramVec(prometheus.HistogramOpts{Name: "http_request_duration_seconds", Help: "HTTP request duration in seconds."}, []string{"method", "route"})
	registry := prometheus.NewRegistry()
	registry.MustRegister(requests, duration)
	return &Metrics{Requests: requests, Duration: duration, registry: registry}
}

func (m *Metrics) Handler() http.Handler {
	return promhttp.HandlerFor(m.registry, promhttp.HandlerOpts{})
}
