package httpapi

import (
	"context"
	"crypto/rand"
	"encoding/hex"
	"log/slog"
	"net/http"
	"runtime/debug"
	"strings"
	"time"

	"example.com/tasksteams/internal/problem"
)

type middleware func(http.Handler) http.Handler

// chain wraps h so that the first middleware in the list runs first (it is the outermost).
func chain(h http.Handler, outer ...middleware) http.Handler {
	for i := len(outer) - 1; i >= 0; i-- {
		h = outer[i](h)
	}
	return h
}

// requestInfo is created once per request so later middleware can add facts for the access log.
type requestInfo struct {
	traceID string
	userID  string
}

type infoKey struct{}

func infoFrom(ctx context.Context) *requestInfo {
	if info, ok := ctx.Value(infoKey{}).(*requestInfo); ok {
		return info
	}
	return &requestInfo{}
}

// withTrace gives every request a trace id: the one from a valid W3C traceparent header, or a new one.
func withTrace(next http.Handler) http.Handler {
	return http.HandlerFunc(func(w http.ResponseWriter, r *http.Request) {
		id := traceIDFrom(r)
		ctx := context.WithValue(r.Context(), infoKey{}, &requestInfo{traceID: id})
		ctx = problem.WithTraceID(ctx, id)
		w.Header().Set("X-Trace-Id", id)
		next.ServeHTTP(w, r.WithContext(ctx))
	})
}

func traceIDFrom(r *http.Request) string {
	if parts := strings.Split(r.Header.Get("Traceparent"), "-"); len(parts) == 4 && len(parts[1]) == 32 {
		if _, err := hex.DecodeString(parts[1]); err == nil && parts[1] != strings.Repeat("0", 32) {
			return strings.ToLower(parts[1])
		}
	}
	var raw [16]byte
	_, _ = rand.Read(raw[:])
	return hex.EncodeToString(raw[:])
}

// statusWriter remembers the status and size of the response for the access log.
type statusWriter struct {
	http.ResponseWriter
	status int
	bytes  int
}

func (w *statusWriter) WriteHeader(status int) {
	if w.status == 0 {
		w.status = status
	}
	w.ResponseWriter.WriteHeader(status)
}

func (w *statusWriter) Write(b []byte) (int, error) {
	if w.status == 0 {
		w.status = http.StatusOK
	}
	n, err := w.ResponseWriter.Write(b)
	w.bytes += n
	return n, err
}

// Unwrap lets http.ResponseController reach the real writer.
func (w *statusWriter) Unwrap() http.ResponseWriter { return w.ResponseWriter }

// accessLog writes one structured line per request, after it finished. It never logs headers or bodies.
func (s *Server) accessLog(next http.Handler) http.Handler {
	return http.HandlerFunc(func(w http.ResponseWriter, r *http.Request) {
		start := time.Now()
		sw := &statusWriter{ResponseWriter: w}
		next.ServeHTTP(sw, r)
		if sw.status == 0 {
			sw.status = http.StatusOK
		}
		level := slog.LevelInfo
		switch {
		case sw.status >= 500:
			level = slog.LevelError
		case sw.status >= 400:
			level = slog.LevelWarn
		case r.URL.Path == "/health":
			level = slog.LevelDebug
		}
		info := infoFrom(r.Context())
		attrs := []slog.Attr{
			slog.String("method", r.Method),
			slog.String("path", r.URL.Path),
			slog.Int("status", sw.status),
			slog.Int("bytes", sw.bytes),
			slog.Float64("duration_ms", float64(time.Since(start).Microseconds())/1000),
			slog.String("trace_id", info.traceID),
		}
		if info.userID != "" {
			attrs = append(attrs, slog.String("user_id", info.userID))
		}
		s.logger.LogAttrs(r.Context(), level, "request", attrs...)
	})
}

// recoverer turns a panic in a handler into a logged 500 problem, so one bad request cannot kill the process.
func (s *Server) recoverer(next http.Handler) http.Handler {
	return http.HandlerFunc(func(w http.ResponseWriter, r *http.Request) {
		defer func() {
			rec := recover()
			if rec == nil {
				return
			}
			if rec == http.ErrAbortHandler {
				panic(rec)
			}
			s.logger.Error("panic in handler", "panic", rec, "trace_id", infoFrom(r.Context()).traceID, "stack", string(debug.Stack()))
			if sw, ok := w.(*statusWriter); !ok || sw.status == 0 {
				problem.Write(w, r, problem.Internal())
			}
		}()
		next.ServeHTTP(w, r)
	})
}
