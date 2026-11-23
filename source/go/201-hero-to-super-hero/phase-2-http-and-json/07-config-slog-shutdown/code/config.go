package main

import (
	"errors"
	"fmt"
	"log/slog"
	"time"
)

// Config holds every setting the service needs. It is read once at start-up and never changed.
type Config struct {
	Addr            string
	LogLevel        slog.Level
	LogFormat       string
	ShutdownTimeout time.Duration
}

// LoadConfig reads the settings through getenv (os.Getenv in production, a map lookup in tests).
// Defaults are safe for development; every invalid value is reported at once.
func LoadConfig(getenv func(string) string) (Config, error) {
	cfg := Config{
		Addr:            "127.0.0.1:8080",
		LogLevel:        slog.LevelInfo,
		LogFormat:       "text",
		ShutdownTimeout: 10 * time.Second,
	}
	var errs []error

	if v := getenv("APP_ADDR"); v != "" {
		cfg.Addr = v
	}
	if v := getenv("APP_LOG_LEVEL"); v != "" {
		if err := cfg.LogLevel.UnmarshalText([]byte(v)); err != nil {
			errs = append(errs, fmt.Errorf("APP_LOG_LEVEL %q: want debug, info, warn or error", v))
		}
	}
	if v := getenv("APP_LOG_FORMAT"); v != "" {
		if v != "text" && v != "json" {
			errs = append(errs, fmt.Errorf("APP_LOG_FORMAT %q: want text or json", v))
		} else {
			cfg.LogFormat = v
		}
	}
	if v := getenv("APP_SHUTDOWN_TIMEOUT"); v != "" {
		d, err := time.ParseDuration(v)
		if err != nil || d <= 0 {
			errs = append(errs, fmt.Errorf("APP_SHUTDOWN_TIMEOUT %q: want a positive duration such as 10s", v))
		} else {
			cfg.ShutdownTimeout = d
		}
	}
	return cfg, errors.Join(errs...)
}
