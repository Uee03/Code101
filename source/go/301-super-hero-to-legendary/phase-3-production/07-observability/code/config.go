package main

import "os"

type config struct {
	service   string
	httpAddr  string
	adminAddr string
	baseURL   string
	logLevel  string
	apiKey    Secret
}

// loadConfig reads the environment once, at start-up. Defaults bind to the
// loopback address so a laptop run is not exposed to the network.
func loadConfig() config {
	return config{
		service:   env("SERVICE_NAME", "go301-observability"),
		httpAddr:  env("HTTP_ADDR", "127.0.0.1:8080"),
		adminAddr: env("ADMIN_ADDR", "127.0.0.1:9100"),
		baseURL:   env("BASE_URL", "http://127.0.0.1:8080"),
		logLevel:  env("LOG_LEVEL", "info"),
		apiKey:    Secret(os.Getenv("API_KEY")),
	}
}

func env(key, fallback string) string {
	if v := os.Getenv(key); v != "" {
		return v
	}
	return fallback
}
