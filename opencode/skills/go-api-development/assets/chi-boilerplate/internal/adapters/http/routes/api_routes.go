package routes

import (
	"{{MODULE_PATH}}/internal/adapters/http/handlers"
	"{{MODULE_PATH}}/internal/app/usecases"
	"{{MODULE_PATH}}/internal/config"
	"github.com/go-chi/chi/v5"
)

func AddAPI(r chi.Router, cfg *config.AppConfigs) {
	r.Route("/api/v1", func(r chi.Router) {
		r.Get("/ping", handlers.Ping(usecases.NewPing(cfg.Server.ServiceName)))
	})
}
