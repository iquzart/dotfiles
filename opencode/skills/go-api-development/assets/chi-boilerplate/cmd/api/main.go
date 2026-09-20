package main

import (
	"{{MODULE_PATH}}/internal/adapters/http/server"
	"{{MODULE_PATH}}/internal/bootstrap"
	"{{MODULE_PATH}}/internal/config"
	"{{MODULE_PATH}}/internal/meta"
)

func main() {
	// Load configs.
	cfg, err := config.GetAppConfigs()
	if err != nil {
		meta.Fatal(meta.NewLogger("error"), "failed to load application configs", "error", err)
	}

	deps, err := bootstrap.Initialize(cfg)
	if err != nil {
		meta.Fatal(meta.NewLogger("error"), "failed to initialize dependencies", "error", err)
	}
	defer deps.Close()

	// Start server.
	server.New(cfg, deps.Logger).Run()
}
