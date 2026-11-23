package main

import (
	"context"
	"io"
	"log/slog"

	"go.opentelemetry.io/otel/trace"
)

// newLogger writes one JSON object per line. Level names such as "debug",
// "info", "warn" and "error" are accepted; anything else falls back to info.
func newLogger(w io.Writer, level string) *slog.Logger {
	var lvl slog.Level
	if err := lvl.UnmarshalText([]byte(level)); err != nil {
		lvl = slog.LevelInfo
	}
	return slog.New(traceHandler{slog.NewJSONHandler(w, &slog.HandlerOptions{Level: lvl})})
}

// traceHandler adds trace_id and span_id to every record whose context holds
// an active span, so a log line can be matched to its trace.
type traceHandler struct {
	slog.Handler
}

func (h traceHandler) Handle(ctx context.Context, r slog.Record) error {
	if sc := trace.SpanContextFromContext(ctx); sc.IsValid() {
		r.AddAttrs(
			slog.String("trace_id", sc.TraceID().String()),
			slog.String("span_id", sc.SpanID().String()),
		)
	}
	return h.Handler.Handle(ctx, r)
}

func (h traceHandler) WithAttrs(attrs []slog.Attr) slog.Handler {
	return traceHandler{h.Handler.WithAttrs(attrs)}
}

func (h traceHandler) WithGroup(name string) slog.Handler {
	return traceHandler{h.Handler.WithGroup(name)}
}

// Secret is a string that never prints its value, in logs or with fmt.
type Secret string

func (Secret) LogValue() slog.Value { return slog.StringValue("[redacted]") }
func (Secret) String() string       { return "[redacted]" }
