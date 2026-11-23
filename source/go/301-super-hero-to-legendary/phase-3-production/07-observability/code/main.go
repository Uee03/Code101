package main

import (
	"context"
	"errors"
	"fmt"
	"net/http"
	"os"
	"os/signal"
	"syscall"
	"time"

	"github.com/prometheus/client_golang/prometheus/promhttp"
	"go.opentelemetry.io/contrib/instrumentation/net/http/otelhttp"
	"go.opentelemetry.io/otel"
)

func main() {
	if err := run(); err != nil {
		fmt.Fprintln(os.Stderr, "error:", err)
		os.Exit(1)
	}
}

func run() error {
	cfg := loadConfig()
	log := newLogger(os.Stdout, cfg.logLevel).With("service", cfg.service)

	ctx, stop := signal.NotifyContext(context.Background(), os.Interrupt, syscall.SIGTERM)
	defer stop()

	// Spans go to standard error so they do not mix with the JSON logs on standard output.
	shutdownTracing, err := setupTracing(ctx, cfg.service, os.Stderr)
	if err != nil {
		return err
	}

	reg := newRegistry()
	m := newMetrics(reg)
	a := &app{
		log:     log,
		tracer:  otel.Tracer("go301/observability"),
		client:  &http.Client{Timeout: 2 * time.Second, Transport: otelhttp.NewTransport(http.DefaultTransport)},
		baseURL: cfg.baseURL,
	}

	api := &http.Server{
		Addr:              cfg.httpAddr,
		Handler:           a.routes(m),
		ReadHeaderTimeout: 5 * time.Second,
		ReadTimeout:       10 * time.Second,
		WriteTimeout:      10 * time.Second,
		IdleTimeout:       time.Minute,
	}

	// Metrics live on a separate admin port that is never published to the internet.
	adminMux := http.NewServeMux()
	adminMux.Handle("GET /metrics", promhttp.HandlerFor(reg, promhttp.HandlerOpts{}))
	adminMux.HandleFunc("GET /healthz", func(w http.ResponseWriter, _ *http.Request) {
		w.WriteHeader(http.StatusOK)
	})
	admin := &http.Server{Addr: cfg.adminAddr, Handler: adminMux, ReadHeaderTimeout: 5 * time.Second}

	errCh := make(chan error, 2)
	go func() { errCh <- api.ListenAndServe() }()
	go func() { errCh <- admin.ListenAndServe() }()
	log.Info("started", "http_addr", cfg.httpAddr, "admin_addr", cfg.adminAddr, "api_key", cfg.apiKey)

	select {
	case err := <-errCh:
		return err
	case <-ctx.Done():
	}

	shutdownCtx, cancel := context.WithTimeout(context.Background(), 10*time.Second)
	defer cancel()
	err = errors.Join(api.Shutdown(shutdownCtx), admin.Shutdown(shutdownCtx), shutdownTracing(shutdownCtx))
	log.Info("stopped")
	return err
}
