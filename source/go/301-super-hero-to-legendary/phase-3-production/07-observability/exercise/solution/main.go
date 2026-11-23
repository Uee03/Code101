package main

import (
	"log/slog"
	"os"
)

// Token is a bearer token. LogValue keeps its value out of every log line.
type Token string

func (Token) LogValue() slog.Value { return slog.StringValue("[redacted]") }

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
