package main

import (
	"log/slog"
	"os"
)

// Token is a bearer token.
// TODO 1: give Token a LogValue method (the slog.LogValuer interface) that
// returns the text [redacted], so the log line below never shows the value.
type Token string

func main() {
	opts := &slog.HandlerOptions{
		// Drop the time attribute so the output is the same on every run.
		ReplaceAttr: func(groups []string, a slog.Attr) slog.Attr {
			if a.Key == slog.TimeKey && len(groups) == 0 {
				return slog.Attr{}
			}
			return a
		},
	}
	log := slog.New(slog.NewTextHandler(os.Stdout, opts))

	log.Info("login", "user", "ada", "token", Token("s3cr3t-value"))
}
