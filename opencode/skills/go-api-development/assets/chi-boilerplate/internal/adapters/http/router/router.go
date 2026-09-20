package router

import (
	"log/slog"

	"{{MODULE_PATH}}/internal/adapters/http/middleware"
	"{{MODULE_PATH}}/internal/adapters/http/routes"
	"{{MODULE_PATH}}/internal/config"
	"{{MODULE_PATH}}/internal/meta"
	"github.com/go-chi/chi/v5"
	chimiddleware "github.com/go-chi/chi/v5/middleware"
	"go.opentelemetry.io/contrib/instrumentation/net/http/otelhttp"
)

func New(cfg *config.AppConfigs, logger *slog.Logger, metrics *meta.Metrics) *chi.Mux {
	r := chi.NewRouter()
	r.Use(chimiddleware.RequestID, chimiddleware.RealIP, chimiddleware.Recoverer)
	r.Use(otelhttp.NewMiddleware(cfg.Server.ServiceName))
	r.Use(middleware.Observe(metrics, logger))
	routes.AddSystem(r, cfg.Server.Version, metrics)
	routes.AddAPI(r, cfg)
	return r
}
