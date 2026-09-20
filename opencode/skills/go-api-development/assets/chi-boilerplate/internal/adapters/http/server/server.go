package server

import (
	"context"
	"errors"
	"log/slog"
	"net/http"
	"os"
	"os/signal"
	"syscall"

	"{{MODULE_PATH}}/internal/adapters/http/router"
	"{{MODULE_PATH}}/internal/config"
	"{{MODULE_PATH}}/internal/meta"
)

type Server struct {
	cfg    *config.ServerConfigs
	logger *slog.Logger
	http   *http.Server
}

func New(cfg *config.AppConfigs, logger *slog.Logger) *Server {
	return &Server{
		cfg:    cfg.Server,
		logger: logger,
		http:   &http.Server{Addr: cfg.Server.Address(), Handler: router.New(cfg, logger, meta.NewMetrics())},
	}
}

func (s *Server) Run() {
	stop := make(chan os.Signal, 1)
	signal.Notify(stop, os.Interrupt, syscall.SIGTERM)
	defer signal.Stop(stop)

	go func() {
		s.logger.Info("service started", "address", s.cfg.Address(), "service", s.cfg.ServiceName)
		if err := s.http.ListenAndServe(); err != nil && !errors.Is(err, http.ErrServerClosed) {
			s.logger.Error("serve HTTP", "error", err)
		}
	}()

	<-stop
	ctx, cancel := context.WithTimeout(context.Background(), s.cfg.ShutdownTimeout)
	defer cancel()
	if err := s.http.Shutdown(ctx); err != nil {
		s.logger.Error("shutdown HTTP server", "error", err)
	}
}
