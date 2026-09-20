package config

import (
	"fmt"
	"os"
	"time"
)

type ServerConfigs struct {
	Port            string
	ServiceName     string
	Version         string
	LogLevel        string
	TracingEnabled  bool
	OTLPEndpoint    string
	ShutdownTimeout time.Duration
}

type AppConfigs struct {
	Server *ServerConfigs
}

func GetAppConfigs() (*AppConfigs, error) {
	return &AppConfigs{Server: &ServerConfigs{
		Port:            env("PORT", "{{SERVICE_PORT}}"),
		ServiceName:     env("SERVICE_NAME", "{{SERVICE_NAME}}"),
		Version:         env("VERSION", "dev"),
		LogLevel:        env("LOG_LEVEL", "info"),
		TracingEnabled:  env("TRACING_ENABLED", "false") == "true",
		OTLPEndpoint:    env("OTLP_ENDPOINT", "otel-collector:4317"),
		ShutdownTimeout: duration("SHUTDOWN_TIMEOUT", 5*time.Second),
	}}, nil
}

func (c ServerConfigs) Address() string { return fmt.Sprintf(":%s", c.Port) }

func env(key, fallback string) string {
	if value := os.Getenv(key); value != "" {
		return value
	}
	return fallback
}

func duration(key string, fallback time.Duration) time.Duration {
	value, err := time.ParseDuration(env(key, fallback.String()))
	if err != nil {
		return fallback
	}
	return value
}
