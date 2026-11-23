package main

import (
	"context"
	"encoding/json"
	"errors"
	"flag"
	"fmt"
	"log/slog"
	"net"
	"net/http"
	"os"
	"os/signal"
	"sync/atomic"
	"syscall"
	"time"

	"example.com/code101/go301/l09/internal/version"
)

func main() {
	showVersion := flag.Bool("version", false, "print the version and exit")
	healthcheck := flag.Bool("healthcheck", false, "probe /healthz and exit with 0 (healthy) or 1")
	flag.Parse()

	addr := env("HTTP_ADDR", "127.0.0.1:8080")
	switch {
	case *showVersion:
		fmt.Println(version.String())
	case *healthcheck:
		os.Exit(probe(addr))
	default:
		if err := serve(addr); err != nil {
			slog.Error("server stopped", "error", err)
			os.Exit(1)
		}
	}
}

// probe is used by the container health check: a distroless image has no
// shell and no curl, so the binary checks itself.
func probe(addr string) int {
	_, port, err := net.SplitHostPort(addr)
	if err != nil {
		return 1
	}
	client := &http.Client{Timeout: 2 * time.Second}
	resp, err := client.Get("http://127.0.0.1:" + port + "/healthz")
	if err != nil {
		return 1
	}
	defer resp.Body.Close()
	if resp.StatusCode != http.StatusOK {
		return 1
	}
	return 0
}

func serve(addr string) error {
	log := slog.New(slog.NewJSONHandler(os.Stdout, nil))
	var ready atomic.Bool

	mux := http.NewServeMux()
	// Liveness: the process is running. Never check dependencies here.
	mux.HandleFunc("GET /healthz", func(w http.ResponseWriter, _ *http.Request) {
		w.WriteHeader(http.StatusOK)
	})
	// Readiness: should the load balancer send traffic now?
	mux.HandleFunc("GET /readyz", func(w http.ResponseWriter, _ *http.Request) {
		if !ready.Load() {
			w.WriteHeader(http.StatusServiceUnavailable)
			return
		}
		w.WriteHeader(http.StatusOK)
	})
	mux.HandleFunc("GET /version", func(w http.ResponseWriter, _ *http.Request) {
		w.Header().Set("Content-Type", "application/json")
		_ = json.NewEncoder(w).Encode(version.Get())
	})

	srv := &http.Server{
		Addr:              addr,
		Handler:           mux,
		ReadHeaderTimeout: 5 * time.Second,
		ReadTimeout:       10 * time.Second,
		WriteTimeout:      10 * time.Second,
		IdleTimeout:       time.Minute,
	}

	ln, err := net.Listen("tcp", addr)
	if err != nil {
		return err
	}
	ctx, stop := signal.NotifyContext(context.Background(), os.Interrupt, syscall.SIGTERM)
	defer stop()

	errCh := make(chan error, 1)
	go func() { errCh <- srv.Serve(ln) }()
	ready.Store(true)
	log.Info("started", "addr", addr, "version", version.Version, "commit", version.Commit)

	select {
	case err := <-errCh:
		return err
	case <-ctx.Done():
	}

	// Graceful shutdown: say "not ready", give the load balancer time to
	// notice, then stop accepting connections and let in-flight requests finish.
	ready.Store(false)
	if d, err := time.ParseDuration(env("SHUTDOWN_DELAY", "0s")); err == nil && d > 0 {
		time.Sleep(d)
	}
	shutdownCtx, cancel := context.WithTimeout(context.Background(), 10*time.Second)
	defer cancel()
	if err := srv.Shutdown(shutdownCtx); err != nil && !errors.Is(err, http.ErrServerClosed) {
		return err
	}
	log.Info("stopped")
	return nil
}

func env(key, fallback string) string {
	if v := os.Getenv(key); v != "" {
		return v
	}
	return fallback
}
