package router_test

import (
	"net/http"
	"net/http/httptest"
	"testing"

	"{{MODULE_PATH}}/internal/adapters/http/router"
	"{{MODULE_PATH}}/internal/config"
	"{{MODULE_PATH}}/internal/meta"
)

func TestCoreEndpoints(t *testing.T) {
	handler := router.New(&config.AppConfigs{Server: &config.ServerConfigs{ServiceName: "test", Version: "test"}}, meta.NewLogger("error"), meta.NewMetrics())
	for _, path := range []string{"/api/v1/ping", "/system/version", "/system/health/live", "/system/health/ready", "/system/metrics"} {
		t.Run(path, func(t *testing.T) {
			request := httptest.NewRequest(http.MethodGet, path, nil)
			response := httptest.NewRecorder()
			handler.ServeHTTP(response, request)
			if response.Code != http.StatusOK {
				t.Fatalf("status = %d, want %d", response.Code, http.StatusOK)
			}
		})
	}
}
