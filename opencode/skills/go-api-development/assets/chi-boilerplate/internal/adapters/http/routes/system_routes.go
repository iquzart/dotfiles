package routes

import (
	"{{MODULE_PATH}}/internal/adapters/http/handlers"
	"{{MODULE_PATH}}/internal/meta"
	"github.com/go-chi/chi/v5"
)

func AddSystem(r chi.Router, version string, metrics *meta.Metrics) {
	r.Route("/system", func(r chi.Router) {
		r.Get("/version", handlers.Version(version))
		r.Get("/health/live", handlers.Liveness)
		r.Get("/health/ready", handlers.Readiness)
		r.Handle("/metrics", metrics.Handler())
	})
}
