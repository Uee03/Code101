package main

import (
	"fmt"
	"io"
	"log/slog"
	"net/http"

	"go.opentelemetry.io/contrib/instrumentation/net/http/otelhttp"
	"go.opentelemetry.io/otel/attribute"
	"go.opentelemetry.io/otel/codes"
	"go.opentelemetry.io/otel/trace"
)

type app struct {
	log     *slog.Logger
	tracer  trace.Tracer
	client  *http.Client
	baseURL string
}

// routes wires the three endpoints. Each handler is wrapped twice: instrument
// records the metrics for a fixed route name, and otelhttp creates the server
// span and reads the incoming trace context.
func (a *app) routes(m *metrics) http.Handler {
	mux := http.NewServeMux()
	mux.Handle("GET /hello", m.instrument("/hello", http.HandlerFunc(a.hello)))
	mux.Handle("GET /chain", m.instrument("/chain", http.HandlerFunc(a.chain)))
	mux.Handle("GET /fail", m.instrument("/fail", http.HandlerFunc(a.fail)))
	return otelhttp.NewHandler(mux, "http.server")
}

var greetings = map[string]string{"": "Hello", "en": "Hello", "fr": "Bonjour", "de": "Hallo"}

func (a *app) hello(w http.ResponseWriter, r *http.Request) {
	ctx, span := a.tracer.Start(r.Context(), "lookup-greeting")
	defer span.End()

	lang := r.URL.Query().Get("lang")
	span.SetAttributes(attribute.String("greeting.lang", lang))

	greeting, ok := greetings[lang]
	if !ok {
		err := fmt.Errorf("unsupported language %q", lang)
		span.RecordError(err)
		span.SetStatus(codes.Error, "unsupported language")
		a.log.WarnContext(ctx, "unsupported language", "lang", lang)
		http.Error(w, "unsupported language", http.StatusBadRequest)
		return
	}
	a.log.InfoContext(ctx, "greeted", "lang", lang)
	fmt.Fprintln(w, greeting)
}

// chain calls /hello through an instrumented client. The client adds the
// traceparent header, so both requests belong to one trace.
func (a *app) chain(w http.ResponseWriter, r *http.Request) {
	req, err := http.NewRequestWithContext(r.Context(), http.MethodGet, a.baseURL+"/hello?lang=fr", nil)
	if err != nil {
		a.log.ErrorContext(r.Context(), "build request", "error", err)
		http.Error(w, "internal error", http.StatusInternalServerError)
		return
	}
	resp, err := a.client.Do(req)
	if err != nil {
		a.log.ErrorContext(r.Context(), "call /hello", "error", err)
		http.Error(w, "upstream unavailable", http.StatusBadGateway)
		return
	}
	defer resp.Body.Close()

	body, err := io.ReadAll(io.LimitReader(resp.Body, 1<<10))
	if err != nil {
		a.log.ErrorContext(r.Context(), "read response", "error", err)
		http.Error(w, "upstream unavailable", http.StatusBadGateway)
		return
	}
	a.log.InfoContext(r.Context(), "chained", "upstream_status", resp.StatusCode)
	fmt.Fprintf(w, "chain: %s", body)
}

func (a *app) fail(w http.ResponseWriter, r *http.Request) {
	a.log.ErrorContext(r.Context(), "simulated failure", "route", "/fail")
	http.Error(w, "something broke", http.StatusInternalServerError)
}
