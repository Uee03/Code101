// Package config reads the settings of the service from environment variables.
package config

import (
	"fmt"
	"log/slog"
	"os"
	"strings"
)

// Config holds every setting the service needs. It is built once at start-up and never changed.
type Config struct {
	ListenAddr string
	LogLevel   slog.Level
	LogFormat  string
}

// Load reads the environment and returns an error for a value it cannot use.
func Load() (Config, error) {
	cfg := Config{
		ListenAddr: env("LISTEN_ADDR", "127.0.0.1:8000"),
		LogFormat:  env("LOG_FORMAT", "text"),
	}
	if err := cfg.LogLevel.UnmarshalText([]byte(env("LOG_LEVEL", "info"))); err != nil {
		return Config{}, fmt.Errorf("LOG_LEVEL: %w", err)
	}
	if cfg.LogFormat != "text" && cfg.LogFormat != "json" {
		return Config{}, fmt.Errorf("LOG_FORMAT must be text or json, got %q", cfg.LogFormat)
	}
	return cfg, nil
}

// env returns the variable when it is set and not blank, otherwise the fallback.
func env(key, fallback string) string {
	if value, ok := os.LookupEnv(key); ok && strings.TrimSpace(value) != "" {
		return value
	}
	return fallback
}
