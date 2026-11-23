package main

import (
	"bytes"
	"context"
	"net/http"
	"net/http/httptest"
	"strings"
	"testing"

	"github.com/prometheus/client_golang/prometheus"
	"github.com/prometheus/client_golang/prometheus/testutil"
	"go.opentelemetry.io/otel/trace"
)

func TestInstrumentCountsRequestsByRouteAndStatus(t *testing.T) {
	m := newMetrics(prometheus.NewRegistry())
	h := m.instrument("/fail", http.HandlerFunc(func(w http.ResponseWriter, _ *http.Request) {
		http.Error(w, "boom", http.StatusInternalServerError)
	}))

	for range 3 {
		h.ServeHTTP(httptest.NewRecorder(), httptest.NewRequest(http.MethodGet, "/fail", nil))
	}

	got := testutil.ToFloat64(m.requests.WithLabelValues("/fail", "GET", "500"))
	if got != 3 {
		t.Fatalf("counter = %v, want 3", got)
	}
}

func TestTraceHandlerAddsTraceAndSpanIDs(t *testing.T) {
	var buf bytes.Buffer
	log := newLogger(&buf, "info")
	sc := trace.NewSpanContext(trace.SpanContextConfig{
		TraceID:    trace.TraceID{1},
		SpanID:     trace.SpanID{2},
		TraceFlags: trace.FlagsSampled,
	})
	ctx := trace.ContextWithSpanContext(context.Background(), sc)

	log.InfoContext(ctx, "hello")

	for _, want := range []string{
		`"trace_id":"` + sc.TraceID().String() + `"`,
		`"span_id":"` + sc.SpanID().String() + `"`,
	} {
		if !strings.Contains(buf.String(), want) {
			t.Fatalf("log line %q does not contain %s", buf.String(), want)
		}
	}
}

func TestSecretIsRedactedInLogs(t *testing.T) {
	var buf bytes.Buffer
	log := newLogger(&buf, "info")

	log.Info("config", "api_key", Secret("hunter2"))

	out := buf.String()
	if strings.Contains(out, "hunter2") || !strings.Contains(out, "[redacted]") {
		t.Fatalf("secret was not redacted: %s", out)
	}
}
