// Package config reads the settings of the service from environment variables.
package config

import (
	"fmt"
	"log/slog"
	"net/url"
	"os"
	"strconv"
	"strings"
)

// Config holds every setting the service needs. It is built once at start-up and never changed.
type Config struct {
	ListenAddr         string
	LogLevel           slog.Level
	LogFormat          string
	DatabaseURL        string
	PublicURL          string
	Issuer             string   // the iss claim a token must carry
	Audience           string   // the aud value a token must contain
	JWKSURL            string   // where the signing keys are downloaded; may differ from the issuer host inside Docker
	CORSOrigins        []string // browser origins that may call the API
	RateLimit          int      // requests per minute for a signed-in user
	AnonymousRateLimit int      // requests per minute for a client address without a valid token
	MaxBodyBytes       int64    // largest accepted request body
}

// Load reads the environment and returns an error for a value it cannot use.
func Load() (Config, error) {
	cfg := Config{
		ListenAddr: env("LISTEN_ADDR", "127.0.0.1:8000"),
		LogFormat:  env("LOG_FORMAT", "text"),
		// The default is the disposable password of the platform stack. Real deployments set DATABASE_URL.
		DatabaseURL: env("DATABASE_URL", "postgres://tasks_app:tasks_app_local_only@127.0.0.1:5432/tasksteams"),
		PublicURL:   strings.TrimRight(env("PUBLIC_URL", "http://localhost:8000"), "/"),
		Issuer:      env("KEYCLOAK_ISSUER", "http://localhost:8180/realms/tasksteams"),
		Audience:    env("KEYCLOAK_AUDIENCE", "tasks-api"),
		JWKSURL:     env("KEYCLOAK_JWKS_URL", "http://127.0.0.1:8180/realms/tasksteams/protocol/openid-connect/certs"),
	}
	for _, origin := range strings.Split(env("CORS_ORIGINS", "http://localhost:4200,http://localhost:5173"), ",") {
		if origin = strings.TrimSpace(origin); origin == "*" {
			return Config{}, fmt.Errorf("CORS_ORIGINS must list origins; a wildcard is not allowed")
		} else if origin != "" {
			cfg.CORSOrigins = append(cfg.CORSOrigins, origin)
		}
	}
	var err error
	if cfg.RateLimit, err = envInt("RATE_LIMIT_PER_MINUTE", 100); err != nil {
		return Config{}, err
	}
	if cfg.AnonymousRateLimit, err = envInt("RATE_LIMIT_ANONYMOUS_PER_MINUTE", 30); err != nil {
		return Config{}, err
	}
	maxBody, err := envInt("MAX_BODY_BYTES", 1<<20)
	if err != nil {
		return Config{}, err
	}
	cfg.MaxBodyBytes = int64(maxBody)
	if err := cfg.LogLevel.UnmarshalText([]byte(env("LOG_LEVEL", "info"))); err != nil {
		return Config{}, fmt.Errorf("LOG_LEVEL: %w", err)
	}
	if cfg.LogFormat != "text" && cfg.LogFormat != "json" {
		return Config{}, fmt.Errorf("LOG_FORMAT must be text or json, got %q", cfg.LogFormat)
	}
	return cfg, nil
}

// LogValue makes slog print the configuration without the database password: a Config can be logged safely.
func (c Config) LogValue() slog.Value {
	return slog.GroupValue(
		slog.String("listen_addr", c.ListenAddr),
		slog.String("database", redactPassword(c.DatabaseURL)),
		slog.String("issuer", c.Issuer),
		slog.String("audience", c.Audience),
		slog.String("jwks_url", c.JWKSURL),
		slog.Any("cors_origins", c.CORSOrigins),
		slog.Int("rate_limit", c.RateLimit),
		slog.Int("anonymous_rate_limit", c.AnonymousRateLimit),
		slog.Int64("max_body_bytes", c.MaxBodyBytes),
	)
}

func redactPassword(raw string) string {
	parsed, err := url.Parse(raw)
	if err != nil {
		return "(not a valid URL)" // never echo a string that may contain a password
	}
	return parsed.Redacted()
}

// env returns the variable when it is set and not blank, otherwise the fallback.
func env(key, fallback string) string {
	if value, ok := os.LookupEnv(key); ok && strings.TrimSpace(value) != "" {
		return value
	}
	return fallback
}

// envInt reads a positive whole number.
func envInt(key string, fallback int) (int, error) {
	raw := env(key, strconv.Itoa(fallback))
	value, err := strconv.Atoi(raw)
	if err != nil || value < 1 {
		return 0, fmt.Errorf("%s must be a positive whole number, got %q", key, raw)
	}
	return value, nil
}
