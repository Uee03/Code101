package main

import (
	"context"
	"fmt"
	"log/slog"
	"net"
	"net/http"
	"os"
	"os/signal"
	"syscall"
	"time"
)

func main() {
	os.Exit(realMain(os.Args[1:]))
}

// env returns the value of an environment variable, or fallback when it is empty.
func env(key, fallback string) string {
	if v := os.Getenv(key); v != "" {
		return v
	}
	return fallback
}

func realMain(args []string) int {
	addr := env("APP_ADDR", "127.0.0.1:8080")
	if len(args) > 0 && args[0] == "healthcheck" {
		return healthcheck(addr)
	}

	timeout, err := time.ParseDuration(env("APP_SHUTDOWN_TIMEOUT", "10s"))
	if err != nil || timeout <= 0 {
		fmt.Fprintln(os.Stderr, "APP_SHUTDOWN_TIMEOUT: want a positive duration such as 10s")
		return 2
	}
	var handler slog.Handler
	switch format := env("APP_LOG_FORMAT", "text"); format {
	case "text":
		handler = slog.NewTextHandler(os.Stderr, nil)
	case "json":
		handler = slog.NewJSONHandler(os.Stderr, nil)
	default:
		fmt.Fprintf(os.Stderr, "APP_LOG_FORMAT %q: want text or json\n", format)
		return 2
	}
	logger := slog.New(handler)

	ctx, stop := signal.NotifyContext(context.Background(), os.Interrupt, syscall.SIGTERM)
	defer stop()

	if err := serve(ctx, addr, timeout, newRouter(newMemoryStore(), logger), logger); err != nil {
		logger.Error("server failed", "err", err)
		return 1
	}
	return 0
}

// serve runs the server until ctx is cancelled, then drains in-flight requests (lesson 07).
func serve(ctx context.Context, addr string, timeout time.Duration, h http.Handler, logger *slog.Logger) error {
	srv := &http.Server{
		Handler:           h,
		ReadHeaderTimeout: 5 * time.Second,
		ReadTimeout:       10 * time.Second,
		WriteTimeout:      10 * time.Second,
		IdleTimeout:       60 * time.Second,
		ErrorLog:          slog.NewLogLogger(logger.Handler(), slog.LevelError),
	}
	ln, err := net.Listen("tcp", addr)
	if err != nil {
		return fmt.Errorf("listen: %w", err)
	}
	serveErr := make(chan error, 1)
	go func() {
		logger.Info("server started", "addr", ln.Addr().String())
		serveErr <- srv.Serve(ln)
	}()

	select {
	case err := <-serveErr:
		return fmt.Errorf("serve: %w", err)
	case <-ctx.Done():
	}

	logger.Info("shutdown requested", "timeout", timeout)
	shutdownCtx, cancel := context.WithTimeout(context.Background(), timeout)
	defer cancel()
	if err := srv.Shutdown(shutdownCtx); err != nil {
		_ = srv.Close()
		return fmt.Errorf("graceful shutdown: %w", err)
	}
	logger.Info("server stopped")
	return nil
}

// healthcheck lets the container ask itself "are you alive?". The runtime image has no shell and no curl,
// so the program itself is the health probe: exit code 0 means healthy.
func healthcheck(addr string) int {
	_, port, err := net.SplitHostPort(addr)
	if err != nil {
		fmt.Fprintln(os.Stderr, "healthcheck:", err)
		return 1
	}
	client := http.Client{Timeout: 2 * time.Second}
	resp, err := client.Get("http://127.0.0.1:" + port + "/healthz")
	if err != nil {
		fmt.Fprintln(os.Stderr, "healthcheck:", err)
		return 1
	}
	defer resp.Body.Close()
	if resp.StatusCode != http.StatusOK {
		fmt.Fprintln(os.Stderr, "healthcheck: status", resp.StatusCode)
		return 1
	}
	return 0
}
