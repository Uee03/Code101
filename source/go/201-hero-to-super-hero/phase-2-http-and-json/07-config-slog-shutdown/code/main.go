package main

import (
	"context"
	"fmt"
	"os"
	"os/signal"
	"syscall"
)

func main() {
	os.Exit(realMain())
}

// realMain returns an exit code instead of calling os.Exit itself,
// so its deferred calls (stop) run before the process ends.
func realMain() int {
	cfg, err := LoadConfig(os.Getenv)
	if err != nil {
		fmt.Fprintln(os.Stderr, "configuration error:")
		fmt.Fprintln(os.Stderr, err)
		return 2
	}
	logger := newLogger(cfg, os.Stderr)

	ctx, stop := signal.NotifyContext(context.Background(), os.Interrupt, syscall.SIGTERM)
	defer stop()

	if err := run(ctx, cfg, logger); err != nil {
		logger.Error("server failed", "err", err)
		return 1
	}
	return 0
}
