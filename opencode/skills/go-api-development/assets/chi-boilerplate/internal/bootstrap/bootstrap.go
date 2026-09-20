package bootstrap

import (
	"context"
	"log/slog"

	"{{MODULE_PATH}}/internal/config"
	"{{MODULE_PATH}}/internal/meta"
)

type Dependencies struct {
	Logger          *slog.Logger
	shutdownTracing func(context.Context) error
}

func Initialize(cfg *config.AppConfigs) (*Dependencies, error) {
	logger := meta.NewLogger(cfg.Server.LogLevel)
	shutdownTracing, err := meta.InitTracing(context.Background(), cfg, logger)
	if err != nil {
		return nil, err
	}

	return &Dependencies{
		Logger:          logger,
		shutdownTracing: shutdownTracing,
	}, nil
}

func (d *Dependencies) Close() {
	if err := d.shutdownTracing(context.Background()); err != nil {
		d.Logger.Error("shutdown tracing", "error", err)
	}
}
