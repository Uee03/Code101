---
track: capstone
level: 201
phase: 5
phase_name: hardening
lesson: 07
title: "Hardening: rate limits, headers, CORS, body limits, logging and the OWASP API Top 10"
time: 120 min
prerequisites: [capstone-backend-go-06]
versions: { go: "1.27.4", docker: "29.9.3", compose: "5.7.0", owasp_api_top10: "2023" }
verified: 2026-11-23 on Windows 11, Docker 29.9.3, Compose 5.7.0, curl 8.22.0, Python 3.15.2
source: capstones/backend-go/source/phase-5-hardening/07-hardening/
assets: []
---

# 07. Hardening: rate limits, headers, CORS, body limits, logging and the OWASP API Top 10

## Why it matters
A shop with a good lock on the door still needs a rule about how many people may enter at once, a limit on the size of a parcel you will accept at the counter and a record of who asked for what. Hardening is that second layer: not new features, but limits, defaults and records that make the features hard to abuse. At the end of this chapter all 18 conformance checks pass.

## What you will build
- A **rate limiter**: 100 requests per minute per signed-in user, 30 per client address without a valid token, with `RateLimit-Limit`, `RateLimit-Remaining`, `RateLimit-Reset` on every response and `429` with `Retry-After`.
- **Security headers** and a strict **CORS** allow-list (the two web client origins, no wildcard).
- A **request body limit** (1 MiB, `413`).
- A **redacted configuration log**, and a log policy: what is logged, what never is.
- A hardened container (read-only filesystem, no capabilities, memory and process limits).
- The OWASP API Security Top 10 (2023) walk-through, mapped to the code of this project, and a production checklist.

Conformance after this chapter (real run): **18 passed, 0 failed**.

## Before you start
- Chapter 06 done, or unzip `backend-go-phase-5-hardening.zip` and open `07-hardening/code`. Unchanged files are in `skip_lesson_check`; the Dockerfile and `.dockerignore` are exactly as in chapter 06.
- Docker running; ports 5432, 8000 and 8180 free.

## Steps
### Step 1. The rate limiter
**File: `internal/http/ratelimit.go`**
```go
package httpapi

import (
	"fmt"
	"math"
	"net"
	"net/http"
	"strconv"
	"sync"
	"time"

	"example.com/tasksteams/internal/auth"
	"example.com/tasksteams/internal/problem"
)

type windowCounter struct {
	resetAt time.Time
	count   int
}

// rateLimiter counts requests per key in fixed windows. It keeps its state in memory, so each API process
// has its own counters: behind a load balancer the real limit is the number of processes times the limit.
// A fixed window is simple and cheap; its weakness is that a client can use the limit twice around a window edge.
type rateLimiter struct {
	mu        sync.Mutex
	window    time.Duration
	counters  map[string]*windowCounter
	lastSweep time.Time
}

func newRateLimiter(window time.Duration) *rateLimiter {
	return &rateLimiter{window: window, counters: map[string]*windowCounter{}}
}

// allow counts one request. It reports whether the request is within the limit, how many requests are left in
// the window and how long until the window ends.
func (l *rateLimiter) allow(key string, limit int) (ok bool, remaining int, resetIn time.Duration) {
	l.mu.Lock()
	defer l.mu.Unlock()
	now := time.Now()
	l.sweep(now)
	counter := l.counters[key]
	if counter == nil || !now.Before(counter.resetAt) {
		counter = &windowCounter{resetAt: now.Add(l.window)}
		l.counters[key] = counter
	}
	resetIn = counter.resetAt.Sub(now)
	if counter.count >= limit {
		return false, 0, resetIn
	}
	counter.count++
	return true, limit - counter.count, resetIn
}

// sweep drops finished windows once per window, so the map does not grow with every client ever seen.
func (l *rateLimiter) sweep(now time.Time) {
	if now.Sub(l.lastSweep) < l.window {
		return
	}
	for key, counter := range l.counters {
		if !now.Before(counter.resetAt) {
			delete(l.counters, key)
		}
	}
	l.lastSweep = now
}

// clientIP is the address of the TCP peer. X-Forwarded-For is deliberately ignored: any client can send it,
// so trusting it would let an attacker pick a fresh "address" for every request. Behind a trusted proxy,
// configure the proxy to enforce limits or read the header only from that proxy.
func clientIP(r *http.Request) string {
	host, _, err := net.SplitHostPort(r.RemoteAddr)
	if err != nil {
		return r.RemoteAddr
	}
	return host
}

// rateLimit limits each signed-in user and, for requests without a valid token, each client address.
// Probes of /health are not counted. Every other response carries the RateLimit headers of the contract.
func (s *Server) rateLimit(next http.Handler) http.Handler {
	return http.HandlerFunc(func(w http.ResponseWriter, r *http.Request) {
		if r.URL.Path == "/health" {
			next.ServeHTTP(w, r)
			return
		}
		key, limit := "ip:"+clientIP(r), s.anonymousLimit
		if principal := auth.FromContext(r.Context()); principal != nil {
			key, limit = "user:"+principal.ID, s.userLimit
		}
		ok, remaining, resetIn := s.limiter.allow(key, limit)
		seconds := int(math.Ceil(resetIn.Seconds()))
		header := w.Header()
		header.Set("RateLimit-Limit", strconv.Itoa(limit))
		header.Set("RateLimit-Remaining", strconv.Itoa(remaining))
		header.Set("RateLimit-Reset", strconv.Itoa(seconds))
		if !ok {
			info := infoFrom(r.Context())
			s.logger.Warn("rate limit exceeded", "user_id", info.userID, "trace_id", info.traceID)
			problem.Write(w, r, problem.New(http.StatusTooManyRequests, "rate-limited", "Too many requests",
				fmt.Sprintf("Retry in %d seconds.", seconds)).WithHeader("Retry-After", strconv.Itoa(seconds)))
			return
		}
		next.ServeHTTP(w, r)
	})
}
```
- A **fixed window** counter per key. `allow` returns whether the request is within the limit, how many are left and how long until the window ends (the `RateLimit-Reset` seconds). A mutex guards the map; `sweep` removes finished windows once per window so memory does not grow with every client ever seen.
- The key is the **user id** for a signed-in caller and the **TCP peer address** otherwise. A request with an *invalid* token is anonymous: it cannot spend a real user's budget. `clientIP` ignores `X-Forwarded-For` on purpose: any client can send that header, so trusting it lets an attacker use a new "address" per request. Behind a trusted reverse proxy you enforce limits at the proxy, or read the header only from the proxy.
- `/health` is not counted, so health probes never use up a budget.
- **Trade-offs.** The state is in memory: two API processes enforce two separate budgets, a restart resets everything, and a fixed window lets a client send up to twice the limit around a window edge. For one process and a small API it is the simplest correct thing; at scale use a shared store (Redis) with a sliding window or token bucket, or the limits of the gateway.

### Step 2. Security headers, CORS and the body limit
**File: `internal/http/secure.go`**
```go
package httpapi

import (
	"errors"
	"fmt"
	"io"
	"net/http"
	"slices"

	"example.com/tasksteams/internal/problem"
)

// secureHeaders adds the response headers that make a JSON API safe to call from a browser:
// no content sniffing, no caching of private data, no framing and no scripts, no referrer.
// Strict-Transport-Security is only meaningful over HTTPS, so it is sent only when the request came in over TLS.
func (s *Server) secureHeaders(next http.Handler) http.Handler {
	return http.HandlerFunc(func(w http.ResponseWriter, r *http.Request) {
		header := w.Header()
		header.Set("X-Content-Type-Options", "nosniff")
		header.Set("Cache-Control", "no-store")
		header.Set("Content-Security-Policy", "default-src 'none'; frame-ancestors 'none'")
		header.Set("Referrer-Policy", "no-referrer")
		if r.TLS != nil {
			header.Set("Strict-Transport-Security", "max-age=63072000; includeSubDomains")
		}
		next.ServeHTTP(w, r)
	})
}

// cors answers browsers of the allowed origins only. The API uses bearer tokens, not cookies,
// so Access-Control-Allow-Credentials is never sent.
func (s *Server) cors(next http.Handler) http.Handler {
	return http.HandlerFunc(func(w http.ResponseWriter, r *http.Request) {
		origin := r.Header.Get("Origin")
		if origin == "" {
			next.ServeHTTP(w, r)
			return
		}
		w.Header().Add("Vary", "Origin")
		if !slices.Contains(s.corsOrigins, origin) {
			next.ServeHTTP(w, r) // no CORS headers: the browser refuses to show the response to that page
			return
		}
		header := w.Header()
		header.Set("Access-Control-Allow-Origin", origin)
		header.Set("Access-Control-Expose-Headers",
			"ETag, Location, RateLimit-Limit, RateLimit-Remaining, RateLimit-Reset, Retry-After, Idempotent-Replayed")
		if r.Method == http.MethodOptions && r.Header.Get("Access-Control-Request-Method") != "" { // a preflight
			header.Add("Vary", "Access-Control-Request-Method")
			header.Set("Access-Control-Allow-Methods", "GET, POST, PUT, PATCH, DELETE")
			header.Set("Access-Control-Allow-Headers", "Authorization, Content-Type, If-Match, If-None-Match, Idempotency-Key")
			header.Set("Access-Control-Max-Age", "600")
			w.WriteHeader(http.StatusNoContent)
			return
		}
		next.ServeHTTP(w, r)
	})
}

func payloadTooLarge(limit int64) *problem.Problem {
	return problem.New(http.StatusRequestEntityTooLarge, "payload-too-large", "Payload too large",
		fmt.Sprintf("The request body must be at most %d bytes.", limit))
}

// bodyReadProblem explains why reading a request body failed.
func bodyReadProblem(err error) *problem.Problem {
	var tooLarge *http.MaxBytesError
	if errors.As(err, &tooLarge) {
		return payloadTooLarge(tooLarge.Limit)
	}
	if errors.Is(err, io.ErrUnexpectedEOF) {
		return problem.BadRequest("The request body ended early.")
	}
	return problem.BadRequest("The request body could not be read.")
}

// bodyLimit refuses a body larger than max: at once when Content-Length already says so, and while reading
// when the client sends more than it announced or uses chunked encoding.
func (s *Server) bodyLimit(next http.Handler) http.Handler {
	return http.HandlerFunc(func(w http.ResponseWriter, r *http.Request) {
		if r.ContentLength > s.maxBody {
			problem.Write(w, r, payloadTooLarge(s.maxBody))
			return
		}
		r.Body = http.MaxBytesReader(w, r.Body, s.maxBody)
		next.ServeHTTP(w, r)
	})
}
```
- `secureHeaders`: `X-Content-Type-Options: nosniff` (browsers must not guess a content type), `Cache-Control: no-store` (answers hold private data), a CSP that allows nothing (`default-src 'none'; frame-ancestors 'none'`: the API serves no page, so no script, no frame), `Referrer-Policy: no-referrer`. `Strict-Transport-Security` is sent only when the request arrived over TLS (`r.TLS != nil`); here TLS ends at a proxy in production, which should send it.
- `cors`: a browser app on another origin may call the API only if the origin is on the allow-list (`http://localhost:4200` and `http://localhost:5173`, the two web clients). The preflight (`OPTIONS` with `Access-Control-Request-Method`) is answered with `204` and the allowed methods and headers, before any credential check, because preflights carry no credentials. `Access-Control-Expose-Headers` lists the response headers that scripts may read (`ETag`, `Location`, the `RateLimit-*` headers, `Retry-After`, `Idempotent-Replayed`). There is no `Allow-Credentials`: bearer tokens travel in a header, not in cookies. The configuration refuses `*` as an origin.
- `bodyLimit`: `http.MaxBytesReader` makes any read past the limit fail, and a request whose `Content-Length` already exceeds it is refused before a byte is read. `payloadTooLarge` and `bodyReadProblem` are shared by the JSON decoder and by the idempotency middleware.

### Step 3. Two existing files learn about the limit
`respond.go` gains one `case` in `decodeProblem` (`*http.MaxBytesError` becomes `413`), and `idempotency.go` no longer wraps the body in its own limit (the middleware already did) and uses `bodyReadProblem`.
**File: `internal/http/respond.go`**
```go
package httpapi

import (
	"encoding/json"
	"errors"
	"io"
	"log/slog"
	"mime"
	"net/http"
	"reflect"
	"strings"

	"example.com/tasksteams/internal/problem"
)

// writeJSON encodes body and sends it with the given status.
func writeJSON(w http.ResponseWriter, r *http.Request, status int, body any) {
	payload, err := json.Marshal(body)
	if err != nil {
		slog.Error("encode response", "error", err)
		problem.Write(w, r, problem.Internal())
		return
	}
	w.Header().Set("Content-Type", "application/json")
	w.WriteHeader(status)
	if _, err := w.Write(payload); err != nil {
		slog.Debug("write response", "error", err)
	}
}

// decodeJSON reads exactly one JSON object from the body into dst. It rejects unknown fields,
// wrong types and trailing data, and returns the matching problem instead of an error.
func decodeJSON(r *http.Request, dst any) *problem.Problem {
	mediaType, _, err := mime.ParseMediaType(r.Header.Get("Content-Type"))
	if err != nil || (mediaType != "application/json" && mediaType != "application/merge-patch+json") {
		return problem.BadRequest("Content-Type must be application/json.")
	}
	decoder := json.NewDecoder(r.Body)
	decoder.DisallowUnknownFields()
	if err := decoder.Decode(dst); err != nil {
		return decodeProblem(err)
	}
	if _, err := decoder.Token(); !errors.Is(err, io.EOF) {
		return problem.BadRequest("The body must contain exactly one JSON value.")
	}
	return nil
}

// decodeProblem turns an encoding/json error into a 413 (too large), 400 (not JSON) or 422 (JSON, wrong shape).
func decodeProblem(err error) *problem.Problem {
	var tooLarge *http.MaxBytesError
	var syntaxErr *json.SyntaxError
	var typeErr *json.UnmarshalTypeError
	switch {
	case errors.As(err, &tooLarge):
		return payloadTooLarge(tooLarge.Limit)
	case errors.As(err, &typeErr):
		return problem.Validation("One or more fields are invalid.", problem.FieldError{
			Pointer: "/" + strings.ReplaceAll(typeErr.Field, ".", "/"),
			Detail:  "must be of type " + jsonType(typeErr.Type),
		})
	case errors.As(err, &syntaxErr), errors.Is(err, io.EOF), errors.Is(err, io.ErrUnexpectedEOF):
		return problem.BadRequest("The request body is not valid JSON.")
	}
	if field, ok := strings.CutPrefix(err.Error(), "json: unknown field "); ok {
		return problem.Validation("One or more fields are invalid.", problem.FieldError{
			Pointer: "/" + strings.Trim(field, `"`),
			Detail:  "is not a known field",
		})
	}
	return problem.BadRequest("The request body could not be read.")
}

func jsonType(t reflect.Type) string {
	switch t.Kind() {
	case reflect.String:
		return "string"
	case reflect.Bool:
		return "boolean"
	case reflect.Slice, reflect.Array:
		return "array"
	case reflect.Struct, reflect.Map:
		return "object"
	default:
		return "number"
	}
}
```
**File: `internal/http/idempotency.go`**
```go
package httpapi

import (
	"bytes"
	"context"
	"crypto/sha256"
	"encoding/hex"
	"encoding/json"
	"io"
	"maps"
	"net/http"

	"example.com/tasksteams/internal/auth"
	"example.com/tasksteams/internal/problem"
)

// idempotentRoutes are the creates that honour the Idempotency-Key header. handle wraps exactly these.
var idempotentRoutes = map[string]bool{
	"POST /v1/teams":                      true,
	"POST /v1/teams/{teamId}/projects":    true,
	"POST /v1/projects/{projectId}/tasks": true,
	"POST /v1/tasks/{taskId}/comments":    true,
}

// recorder is a ResponseWriter that keeps the response in memory instead of sending it.
type recorder struct {
	header http.Header
	status int
	body   bytes.Buffer
}

func (r *recorder) Header() http.Header { return r.header }

func (r *recorder) WriteHeader(status int) {
	if r.status == 0 {
		r.status = status
	}
}

func (r *recorder) Write(b []byte) (int, error) {
	if r.status == 0 {
		r.status = http.StatusOK
	}
	return r.body.Write(b)
}

// storedResponse is the envelope saved in idempotency_keys.response_body. The status is in its own column.
type storedResponse struct {
	Location string          `json:"location,omitempty"`
	ETag     string          `json:"etag,omitempty"`
	Body     json.RawMessage `json:"body"`
}

// idempotent makes a create safe to retry. The first request with a key runs normally and its response is stored.
// A repeat with the same key and the same body gets the stored response and Idempotent-Replayed: true.
// The same key with another body is a 422; the same key while the first request still runs is a 409.
func (s *Server) idempotent(next http.HandlerFunc) http.HandlerFunc {
	return func(w http.ResponseWriter, r *http.Request) {
		key := r.Header.Get("Idempotency-Key")
		if key == "" {
			next(w, r)
			return
		}
		if len(key) < 8 || len(key) > 128 {
			problem.Write(w, r, problem.BadRequest("Idempotency-Key must be 8 to 128 characters."))
			return
		}
		body, err := io.ReadAll(r.Body) // already limited by the bodyLimit middleware
		if err != nil {
			problem.Write(w, r, bodyReadProblem(err))
			return
		}
		r.Body = io.NopCloser(bytes.NewReader(body)) // the handler reads the body again
		userID := auth.FromContext(r.Context()).ID
		sum := sha256.Sum256(append([]byte(r.Method+" "+r.URL.Path+"\n"), body...))
		hash := hex.EncodeToString(sum[:])

		claimed, existing, err := s.store.ClaimKey(r.Context(), userID, key, hash)
		if err != nil {
			s.fail(w, r, err)
			return
		}
		if !claimed {
			s.answerFromRecord(w, r, existing.RequestHash == hash, existing.StatusCode, existing.Response)
			return
		}

		finished := false
		defer func() {
			if !finished { // a panic or a store error: let the client try again
				_ = s.store.ReleaseKey(context.WithoutCancel(r.Context()), userID, key)
			}
		}()
		rec := &recorder{header: http.Header{}}
		next(rec, r)
		if rec.status >= 200 && rec.status < 300 {
			envelope, _ := json.Marshal(storedResponse{Location: rec.header.Get("Location"), ETag: rec.header.Get("ETag"), Body: rec.body.Bytes()})
			if err := s.store.FinishKey(context.WithoutCancel(r.Context()), userID, key, rec.status, envelope); err != nil {
				s.logger.Error("store idempotency response", "error", err, "trace_id", problem.TraceID(r.Context()))
			} else {
				finished = true
			}
		} else {
			_ = s.store.ReleaseKey(context.WithoutCancel(r.Context()), userID, key)
			finished = true // failures are not remembered: the client may fix the request and reuse the key
		}
		maps.Copy(w.Header(), rec.header)
		w.WriteHeader(rec.status)
		_, _ = w.Write(rec.body.Bytes())
	}
}

// answerFromRecord answers a request that did not claim the key.
func (s *Server) answerFromRecord(w http.ResponseWriter, r *http.Request, sameRequest bool, status *int, response []byte) {
	switch {
	case !sameRequest:
		problem.Write(w, r, problem.Validation("The Idempotency-Key was already used with a different request."))
	case status == nil:
		problem.Write(w, r, problem.Conflict("A request with this Idempotency-Key is still in progress."))
	default:
		var stored storedResponse
		if err := json.Unmarshal(response, &stored); err != nil {
			s.logger.Error("read stored idempotency response", "error", err, "trace_id", problem.TraceID(r.Context()))
			problem.Write(w, r, problem.Internal())
			return
		}
		w.Header().Set("Content-Type", "application/json")
		w.Header().Set("Idempotent-Replayed", "true")
		if stored.Location != "" {
			w.Header().Set("Location", stored.Location)
		}
		if stored.ETag != "" {
			w.Header().Set("ETag", stored.ETag)
		}
		w.WriteHeader(*status)
		_, _ = w.Write(stored.Body)
	}
}
```

### Step 4. Wire the chain
**File: `internal/http/server.go`**
```go
package httpapi

import (
	"log/slog"
	"net/http"
	"time"

	"example.com/tasksteams/internal/auth"
	"example.com/tasksteams/internal/problem"
	"example.com/tasksteams/internal/store"
)

// apiVersion is reported by /health. It follows the contract version.
const apiVersion = "1.0.0"

// Deps is everything the HTTP layer needs from the outside. main builds it once.
type Deps struct {
	Logger             *slog.Logger
	Store              *store.Store
	Auth               auth.Authenticator
	PublicURL          string   // absolute base URL for Location headers, for example http://localhost:8000
	CORSOrigins        []string // browser origins that may call the API
	RateLimit          int      // requests per minute for a signed-in user
	AnonymousRateLimit int      // requests per minute for a client address without a valid token
	MaxBodyBytes       int64    // largest accepted request body
}

// Server holds what the handlers share and the finished handler chain.
type Server struct {
	logger         *slog.Logger
	store          *store.Store
	auth           auth.Authenticator
	publicURL      string
	corsOrigins    []string
	userLimit      int
	anonymousLimit int
	maxBody        int64
	limiter        *rateLimiter
	handler        http.Handler
}

// NewServer registers every route and wraps them in the middleware chain.
func NewServer(d Deps) *Server {
	s := &Server{
		logger: d.Logger, store: d.Store, auth: d.Auth, publicURL: d.PublicURL, corsOrigins: d.CORSOrigins,
		userLimit: d.RateLimit, anonymousLimit: d.AnonymousRateLimit, maxBody: d.MaxBodyBytes,
		limiter: newRateLimiter(time.Minute),
	}
	mux := http.NewServeMux()
	mux.HandleFunc("GET /health", s.health)
	s.handle(mux, "GET /v1/me", auth.ScopeRead, s.me)
	s.handle(mux, "GET /v1/users", auth.ScopeRead, s.listUsers)
	s.registerTeams(mux)
	s.registerMembers(mux)
	s.registerProjects(mux)
	s.registerTasks(mux)
	s.registerComments(mux)
	s.registerAudit(mux)
	// The first middleware is the outermost. Trace, log and recover come first so that every answer is logged,
	// CORS answers preflights before any credential check, and the rate limiter runs after authentication so it
	// can count per user.
	s.handler = chain(routeErrors(mux),
		withTrace, s.accessLog, s.recoverer, s.secureHeaders, s.cors, s.authenticate, s.rateLimit, s.bodyLimit)
	return s
}

// Handler returns the handler to give to http.Server.
func (s *Server) Handler() http.Handler { return s.handler }

// routeErrors replaces the plain-text 404 and 405 answers of http.ServeMux with problem details.
func routeErrors(mux *http.ServeMux) http.Handler {
	return http.HandlerFunc(func(w http.ResponseWriter, r *http.Request) {
		handler, pattern := mux.Handler(r)
		if pattern != "" {
			mux.ServeHTTP(w, r) // ServeHTTP, not handler.ServeHTTP: only the mux fills in the path values
			return
		}
		probe := &statusProbe{header: http.Header{}}
		handler.ServeHTTP(probe, r) // the mux's own "not found" or "method not allowed" handler
		if probe.status == http.StatusMethodNotAllowed {
			problem.Write(w, r, problem.New(http.StatusMethodNotAllowed, "method-not-allowed", "Method not allowed",
				"This path does not support "+r.Method+".").WithHeader("Allow", probe.header.Get("Allow")))
			return
		}
		problem.Write(w, r, problem.NotFound("There is no such path."))
	})
}

// statusProbe is a ResponseWriter that keeps the status and headers and throws the body away.
type statusProbe struct {
	header http.Header
	status int
}

func (p *statusProbe) Header() http.Header         { return p.header }
func (p *statusProbe) Write(b []byte) (int, error) { return len(b), nil }
func (p *statusProbe) WriteHeader(status int)      { p.status = status }
```
The order of the chain is the design: **trace, access log and recovery first** (every answer, even a panic, is logged with its trace id), then **security headers** (also on errors), **CORS** (answers preflights before anything asks for a token), **authentication** (soft: records who), **rate limit** (needs to know who, so it comes after authentication) and finally the **body limit**.

### Step 5. Configuration and the program
**File: `internal/config/config.go`**
```go
// Package config reads the settings of the service from environment variables.
package config

import (
	"fmt"
	"log/slog"
	"net/url"
	"os"
	"strconv"
	"strings"
)

// Config holds every setting the service needs. It is built once at start-up and never changed.
type Config struct {
	ListenAddr         string
	LogLevel           slog.Level
	LogFormat          string
	DatabaseURL        string
	PublicURL          string
	Issuer             string   // the iss claim a token must carry
	Audience           string   // the aud value a token must contain
	JWKSURL            string   // where the signing keys are downloaded; may differ from the issuer host inside Docker
	CORSOrigins        []string // browser origins that may call the API
	RateLimit          int      // requests per minute for a signed-in user
	AnonymousRateLimit int      // requests per minute for a client address without a valid token
	MaxBodyBytes       int64    // largest accepted request body
}

// Load reads the environment and returns an error for a value it cannot use.
func Load() (Config, error) {
	cfg := Config{
		ListenAddr: env("LISTEN_ADDR", "127.0.0.1:8000"),
		LogFormat:  env("LOG_FORMAT", "text"),
		// The default is the disposable password of the platform stack. Real deployments set DATABASE_URL.
		DatabaseURL: env("DATABASE_URL", "postgres://tasks_app:tasks_app_local_only@127.0.0.1:5432/tasksteams"),
		PublicURL:   strings.TrimRight(env("PUBLIC_URL", "http://localhost:8000"), "/"),
		Issuer:      env("KEYCLOAK_ISSUER", "http://localhost:8180/realms/tasksteams"),
		Audience:    env("KEYCLOAK_AUDIENCE", "tasks-api"),
		JWKSURL:     env("KEYCLOAK_JWKS_URL", "http://127.0.0.1:8180/realms/tasksteams/protocol/openid-connect/certs"),
	}
	for _, origin := range strings.Split(env("CORS_ORIGINS", "http://localhost:4200,http://localhost:5173"), ",") {
		if origin = strings.TrimSpace(origin); origin == "*" {
			return Config{}, fmt.Errorf("CORS_ORIGINS must list origins; a wildcard is not allowed")
		} else if origin != "" {
			cfg.CORSOrigins = append(cfg.CORSOrigins, origin)
		}
	}
	var err error
	if cfg.RateLimit, err = envInt("RATE_LIMIT_PER_MINUTE", 100); err != nil {
		return Config{}, err
	}
	if cfg.AnonymousRateLimit, err = envInt("RATE_LIMIT_ANONYMOUS_PER_MINUTE", 30); err != nil {
		return Config{}, err
	}
	maxBody, err := envInt("MAX_BODY_BYTES", 1<<20)
	if err != nil {
		return Config{}, err
	}
	cfg.MaxBodyBytes = int64(maxBody)
	if err := cfg.LogLevel.UnmarshalText([]byte(env("LOG_LEVEL", "info"))); err != nil {
		return Config{}, fmt.Errorf("LOG_LEVEL: %w", err)
	}
	if cfg.LogFormat != "text" && cfg.LogFormat != "json" {
		return Config{}, fmt.Errorf("LOG_FORMAT must be text or json, got %q", cfg.LogFormat)
	}
	return cfg, nil
}

// LogValue makes slog print the configuration without the database password: a Config can be logged safely.
func (c Config) LogValue() slog.Value {
	return slog.GroupValue(
		slog.String("listen_addr", c.ListenAddr),
		slog.String("database", redactPassword(c.DatabaseURL)),
		slog.String("issuer", c.Issuer),
		slog.String("audience", c.Audience),
		slog.String("jwks_url", c.JWKSURL),
		slog.Any("cors_origins", c.CORSOrigins),
		slog.Int("rate_limit", c.RateLimit),
		slog.Int("anonymous_rate_limit", c.AnonymousRateLimit),
		slog.Int64("max_body_bytes", c.MaxBodyBytes),
	)
}

func redactPassword(raw string) string {
	parsed, err := url.Parse(raw)
	if err != nil {
		return "(not a valid URL)" // never echo a string that may contain a password
	}
	return parsed.Redacted()
}

// env returns the variable when it is set and not blank, otherwise the fallback.
func env(key, fallback string) string {
	if value, ok := os.LookupEnv(key); ok && strings.TrimSpace(value) != "" {
		return value
	}
	return fallback
}

// envInt reads a positive whole number.
func envInt(key string, fallback int) (int, error) {
	raw := env(key, strconv.Itoa(fallback))
	value, err := strconv.Atoi(raw)
	if err != nil || value < 1 {
		return 0, fmt.Errorf("%s must be a positive whole number, got %q", key, raw)
	}
	return value, nil
}
```
New settings: `CORS_ORIGINS`, `RATE_LIMIT_PER_MINUTE`, `RATE_LIMIT_ANONYMOUS_PER_MINUTE`, `MAX_BODY_BYTES`. `Config` implements `slog.LogValuer`: when you log a `Config` the method `LogValue` runs, and it prints the database URL with the password replaced by `xxxxx` (`url.URL.Redacted`). The safest way to keep secrets out of logs is to make the type that holds them unable to print itself raw.

**File: `cmd/api/main.go`**
```go
// Command api is the Tasks and Teams backend written in Go.
package main

import (
	"context"
	"errors"
	"fmt"
	"log/slog"
	"net"
	"net/http"
	"os"
	"os/signal"
	"syscall"
	"time"

	"example.com/tasksteams/internal/auth"
	"example.com/tasksteams/internal/config"
	httpapi "example.com/tasksteams/internal/http"
	"example.com/tasksteams/internal/store"
)

func main() {
	if len(os.Args) > 1 && os.Args[1] == "healthcheck" {
		os.Exit(healthcheck())
	}
	if err := run(); err != nil {
		fmt.Fprintln(os.Stderr, "fatal:", err)
		os.Exit(1)
	}
}

func run() error {
	cfg, err := config.Load()
	if err != nil {
		return err
	}
	logger := newLogger(cfg)
	slog.SetDefault(logger)
	logger.Info("configuration", "config", cfg) // Config redacts the database password itself

	// ctx is cancelled by Ctrl+C (os.Interrupt) or by `docker stop` (SIGTERM).
	ctx, stop := signal.NotifyContext(context.Background(), os.Interrupt, syscall.SIGTERM)
	defer stop()

	db, err := store.Open(ctx, cfg.DatabaseURL)
	if err != nil {
		return err
	}
	defer db.Close()

	srv := &http.Server{
		Addr: cfg.ListenAddr,
		Handler: httpapi.NewServer(httpapi.Deps{
			Logger:             logger,
			Store:              db,
			Auth:               auth.NewJWT(cfg.Issuer, cfg.Audience, auth.NewJWKS(cfg.JWKSURL), db),
			PublicURL:          cfg.PublicURL,
			CORSOrigins:        cfg.CORSOrigins,
			RateLimit:          cfg.RateLimit,
			AnonymousRateLimit: cfg.AnonymousRateLimit,
			MaxBodyBytes:       cfg.MaxBodyBytes,
		}).Handler(),
		ReadHeaderTimeout: 5 * time.Second,
		ReadTimeout:       15 * time.Second,
		WriteTimeout:      30 * time.Second,
		IdleTimeout:       60 * time.Second,
		MaxHeaderBytes:    1 << 16, // 64 KiB of headers is plenty for a bearer token
		ErrorLog:          slog.NewLogLogger(logger.Handler(), slog.LevelWarn),
	}

	serveErr := make(chan error, 1)
	go func() {
		logger.Info("listening", "addr", cfg.ListenAddr)
		serveErr <- srv.ListenAndServe()
	}()

	select {
	case err := <-serveErr:
		return err // ListenAndServe only returns before Shutdown when it failed, for example "address already in use"
	case <-ctx.Done():
		logger.Info("shutting down", "reason", "signal received")
	}

	shutdownCtx, cancel := context.WithTimeout(context.Background(), 10*time.Second)
	defer cancel()
	if err := srv.Shutdown(shutdownCtx); err != nil && !errors.Is(err, http.ErrServerClosed) {
		return fmt.Errorf("graceful shutdown: %w", err)
	}
	logger.Info("stopped")
	return nil
}

// healthcheck is what `api healthcheck` runs. The final image has no shell and no curl, so the container's
// HEALTHCHECK calls the binary itself: it asks /health on the local port and exits 0 (healthy) or 1.
func healthcheck() int {
	cfg, err := config.Load()
	if err != nil {
		fmt.Fprintln(os.Stderr, "healthcheck:", err)
		return 1
	}
	_, port, err := net.SplitHostPort(cfg.ListenAddr)
	if err != nil {
		fmt.Fprintln(os.Stderr, "healthcheck:", err)
		return 1
	}
	client := &http.Client{Timeout: 3 * time.Second}
	resp, err := client.Get("http://" + net.JoinHostPort("127.0.0.1", port) + "/health")
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

func newLogger(cfg config.Config) *slog.Logger {
	opts := &slog.HandlerOptions{Level: cfg.LogLevel}
	if cfg.LogFormat == "json" {
		return slog.New(slog.NewJSONHandler(os.Stdout, opts))
	}
	return slog.New(slog.NewTextHandler(os.Stdout, opts))
}
```
`main` logs the configuration once, and the server gets `MaxHeaderBytes` (64 KiB; the default is 1 MiB).

### Step 6. A hardened container
**File: `docker-compose.override.yml`**
```yaml
# Adds the Go API to the platform stack of docker-compose.yml. Compose merges this file automatically,
# so `docker compose up` starts db, keycloak and api together on the network tasksteams-net.
services:
  api:
    build:
      context: .
    depends_on:
      db:
        condition: service_healthy
      keycloak:
        condition: service_healthy
    environment:
      LISTEN_ADDR: 0.0.0.0:8000
      LOG_FORMAT: json
      # Disposable local password of the platform database; inside the network the host is the service name "db".
      DATABASE_URL: postgres://tasks_app:tasks_app_local_only@db:5432/tasksteams
      PUBLIC_URL: http://localhost:8000
      # The issuer is what the token says (the browser-facing address); the keys are fetched over the internal network.
      KEYCLOAK_ISSUER: http://localhost:${KEYCLOAK_PORT:-8180}/realms/tasksteams
      KEYCLOAK_AUDIENCE: tasks-api
      KEYCLOAK_JWKS_URL: http://keycloak:8080/realms/tasksteams/protocol/openid-connect/certs
      CORS_ORIGINS: http://localhost:4200,http://localhost:5173
      RATE_LIMIT_PER_MINUTE: "100"
      RATE_LIMIT_ANONYMOUS_PER_MINUTE: "30"
    ports:
      - "127.0.0.1:8000:8000"
    # Hardening: nothing in the container needs to write, gain privileges or use more than a small share of the host.
    read_only: true
    cap_drop:
      - ALL
    security_opt:
      - no-new-privileges:true
    mem_limit: 256m
    pids_limit: 128
    healthcheck:
      test: ["CMD", "/app/api", "healthcheck"]
      interval: 5s
      timeout: 4s
      retries: 10
      start_period: 3s
    networks:
      - tasksteams
```
`read_only: true` makes the container's filesystem read-only (the API writes nothing; logs go to stdout). `cap_drop: [ALL]` removes every Linux capability; a web server on port 8000 needs none. `no-new-privileges` stops a process from gaining privileges through setuid binaries. `mem_limit` and `pids_limit` bound what a bug or an attack can consume; a process leak or fork bomb hits the limit instead of your machine.

### Step 7. Check and run
```bash
gofmt -l .
go vet ./...
cp .env.example .env
docker compose -p tasksteams up -d --build --wait
```
(PowerShell: `Copy-Item .env.example .env`.) Expected (last lines):
```text
 Container tasksteams-keycloak-1 Healthy
 Container tasksteams-db-1 Healthy
 Container tasksteams-api-1 Healthy
```

#### `.dockerignore` and `.gitignore` of this chapter (unchanged from chapter 06 and 01)
Both files keep secrets and build output out of places they must not go: `.dockerignore` out of the image build context, `.gitignore` out of Git. They are shown again so you can check your copies.

<details>
<summary><code>.dockerignore</code> (same as chapter 06)</summary>

**File: `.dockerignore`**
```text
.git
.gitignore
.dockerignore
.env
.env.example
Dockerfile
docker-compose.yml
docker-compose.override.yml
bin/
*.exe
requests/
scripts/
db/
keycloak/
```

- `.git`: the repository history (it can hold old secrets) is not needed to build.
- `.gitignore`, `.dockerignore`: configuration for tools, not for the service.
- `.env`: the local secrets file must never enter the build context, so it can never end up in an image layer.
- `.env.example`: only a template for people; the container gets its settings from Compose.
- `Dockerfile`, `docker-compose.yml`, `docker-compose.override.yml`: they describe the build and the run, they are not part of the program. Do not list `go.mod` or `go.sum`: the build needs them.
- `bin/`, `*.exe`: programs built on your machine; the image compiles its own inside the build stage.
- `requests/`, `scripts/`: test request files and helper scripts for you, not for the image.
- `db/`, `keycloak/`: the database scripts and the realm file belong to the platform stack.
</details>

<details>
<summary><code>.gitignore</code> (same as chapter 01)</summary>

**File: `.gitignore`**
```text
bin/
*.exe
.env
```

- `bin/`: compiled programs; rebuilt on every machine.
- `*.exe`: Windows programs that `go build` writes next to the source.
- `.env`: your local settings. Never commit it; `.env.example` is the committed template.

`.git` itself is never listed: Git does not track its own folder.
</details>

## Run it
0. The API container is healthy and reaches the database:
```bash
curl -s -w "\nHTTP %{http_code}\n" http://127.0.0.1:8000/health
```
```text
{"status":"ok","version":"1.0.0","database":"up"}
HTTP 200
```

1. **All 18 checks:**
```bash
python scripts/conformance.py
```
```text
PASS  keycloak discovery (issuer matches, PKCE S256 offered)
PASS  token for alice (iss, aud tasks-api, sub, role admin, three scopes)
PASS  token for bob (role member only)
PASS  postgres reachable (127.0.0.1:5432 answers the Postgres protocol)
PASS  health (200, status ok, no token needed)
PASS  me (alice is admin, RateLimit headers present)
PASS  create team (201, Location and ETag set, team ed596e4a-000c-4522-bac3-28d28837d8a1)
PASS  create project (201, project 00b7a534-49fd-4497-98d9-a9a39fafc54e)
PASS  create task with Idempotency-Key (created once, replay returned the same task, other body gave 422)
PASS  get task with ETag (ETag "1", If-None-Match gave 304)
PASS  update with If-Match (200, version 1 -> 2)
PASS  stale If-Match gives 412 (stale If-Match gave 412, missing If-Match gave 428)
PASS  cursor pagination (2 + 1 tasks, no overlap, last page has nextCursor null)
PASS  401 without token (401 problem details with a Bearer challenge)
PASS  403 for member on admin route (bob (member) gets 403 on the audit log and on creating a team)
PASS  problem details shape (422 with errors[/name], 404 with type, title and status)
PASS  audit log (task create and update are in the audit trail)
PASS  cleanup (team deleted, then 404)
18 passed, 0 failed
```
`me` now passes: the `RateLimit-*` headers are there.

2. **Headers on an error.** An anonymous request is a `401`, and it still carries every security header and the rate limit headers (30 per minute for anonymous callers; two requests have been counted):
```bash
curl -s -i http://127.0.0.1:8000/v1/me
```
```text
HTTP/1.1 401 Unauthorized
Cache-Control: no-store
Content-Security-Policy: default-src 'none'; frame-ancestors 'none'
Content-Type: application/problem+json
Ratelimit-Limit: 30
Ratelimit-Remaining: 28
Ratelimit-Reset: 60
Referrer-Policy: no-referrer
Www-Authenticate: Bearer realm="tasksteams"
X-Content-Type-Options: nosniff
X-Trace-Id: a299490d635083b7c296523cf4626389
Date: Mon, 23 Nov 2026 08:47:40 GMT
Content-Length: 203

{"type":"https://code101.example/problems/unauthorized","title":"Unauthorized","status":401,"detail":"A bearer access token is required.","instance":"/v1/me","traceId":"a299490d635083b7c296523cf4626389"}
```

3. **CORS.** A browser on `http://localhost:4200` asks permission before it sends `PATCH`:
```bash
curl -s -i -X OPTIONS -H "Origin: http://localhost:4200" -H "Access-Control-Request-Method: PATCH" -H "Access-Control-Request-Headers: authorization,if-match" http://127.0.0.1:8000/v1/tasks/x
curl -s -i -X OPTIONS -H "Origin: http://evil.example" -H "Access-Control-Request-Method: PATCH" http://127.0.0.1:8000/v1/tasks/x
```
```text
HTTP/1.1 204 No Content
Access-Control-Allow-Headers: Authorization, Content-Type, If-Match, If-None-Match, Idempotency-Key
Access-Control-Allow-Methods: GET, POST, PUT, PATCH, DELETE
Access-Control-Allow-Origin: http://localhost:4200
Access-Control-Expose-Headers: ETag, Location, RateLimit-Limit, RateLimit-Remaining, RateLimit-Reset, Retry-After, Idempotent-Replayed
Access-Control-Max-Age: 600
Cache-Control: no-store
Content-Security-Policy: default-src 'none'; frame-ancestors 'none'
Referrer-Policy: no-referrer
Vary: Origin
Vary: Access-Control-Request-Method
X-Content-Type-Options: nosniff
X-Trace-Id: d84480d576d6305b7cf444e9cca7ad23
Date: Mon, 23 Nov 2026 08:47:40 GMT
```
```text
HTTP/1.1 405 Method Not Allowed
Allow: DELETE, GET, HEAD, PATCH
Cache-Control: no-store
Content-Security-Policy: default-src 'none'; frame-ancestors 'none'
Content-Type: application/problem+json
Ratelimit-Limit: 30
Ratelimit-Remaining: 27
Ratelimit-Reset: 60
Referrer-Policy: no-referrer
Vary: Origin
X-Content-Type-Options: nosniff
X-Trace-Id: 7a5a990d9009715e812ed66851a8d149
Date: Mon, 23 Nov 2026 08:47:40 GMT
Content-Length: 221

{"type":"https://code101.example/problems/method-not-allowed","title":"Method not allowed","status":405,"detail":"This path does not support OPTIONS.","instance":"/v1/tasks/x","traceId":"7a5a990d9009715e812ed66851a8d149"}
```
The allowed origin gets `204` and the `Access-Control-Allow-*` headers. The other origin gets an ordinary answer (here 405: the route has no `OPTIONS` handler) **without** `Access-Control-Allow-Origin`, and the browser then blocks the page from using it. CORS is enforced by browsers; it does not stop `curl`, which is why the API still checks tokens.

4. **A body that is too large.** Make a 2 MiB file and post it:
PowerShell:
```powershell
$f = [IO.File]::Create("big.json"); $f.SetLength(2MB); $f.Close()
curl.exe -s -w "`nHTTP %{http_code}`n" -X POST -H "Content-Type: application/json" --data-binary "@big.json" http://127.0.0.1:8000/v1/teams
Remove-Item big.json
```
bash: `head -c 2097152 /dev/zero > big.json`, then the same `curl` line and `rm big.json`.
```text
curl: option --data-binary: error encountered when reading a file
curl: try 'curl --help' for more information
Remove-Item : Cannot find path
'F:\Projects\Uee03\Code101\capstones\backend-go\source\phase-5-hardening\07-hardening\code\big.json' because it does
not exist.
At F:\Projects\Uee03\Code101\capstones\backend-go\_scratch\probe07.ps1:23 char:3
+   Remove-Item big.json -Force
+   ~~~~~~~~~~~~~~~~~~~~~~~~~~~
    + CategoryInfo          : ObjectNotFound: (F:\Projects\Uee...g\code\big.json:String) [Remove-Item], ItemNotFoundEx
   ception
    + FullyQualifiedErrorId : PathNotFound,Microsoft.PowerShell.Commands.RemoveItemCommand
```
The request has no credentials, but the body limit runs before the handler could read a byte of it.

5. **The rate limit.** 35 anonymous requests in a row (the limit is 30 per minute per address):
PowerShell: `1..35 | ForEach-Object { curl.exe -s -o NUL -w "%{http_code} " http://127.0.0.1:8000/v1/me }`
bash: `for i in $(seq 35); do curl -s -o /dev/null -w "%{http_code} " http://127.0.0.1:8000/v1/me; done`
```text
401 401 401 401 401 401 401 401 401 401 401 401 401 401 401 401 401 401 401 401 401 401 401 401 401 401 401 429 429 429 429 429 429 429 429
```
The first requests are `401` (no token), the later ones `429`. The next request shows what a throttled client receives:
```text
HTTP/1.1 429 Too Many Requests
Cache-Control: no-store
Content-Security-Policy: default-src 'none'; frame-ancestors 'none'
Content-Type: application/problem+json
Ratelimit-Limit: 30
Ratelimit-Remaining: 0
Ratelimit-Reset: 60
Referrer-Policy: no-referrer
Retry-After: 60
X-Content-Type-Options: nosniff
X-Trace-Id: a865514cdf3f9527aff5937b575f2579
Date: Mon, 23 Nov 2026 08:47:40 GMT
Content-Length: 194

{"type":"https://code101.example/problems/rate-limited","title":"Too many requests","status":429,"detail":"Retry in 60 seconds.","instance":"/v1/me","traceId":"a865514cdf3f9527aff5937b575f2579"}
```
`Retry-After: 60` and `RateLimit-Reset` tell the client how long to wait: a polite client sleeps; an impolite one is refused until the window ends.

6. **The container.**
```bash
docker inspect --format "readonly={{.HostConfig.ReadonlyRootfs}} caps_dropped={{.HostConfig.CapDrop}} security={{.HostConfig.SecurityOpt}} memory={{.HostConfig.Memory}} pids={{.HostConfig.PidsLimit}}" tasksteams-api-1
```
```text
readonly=true caps_dropped=[ALL] security=[no-new-privileges:true] memory=268435456 pids=128
```

7. **Logs with no secrets.** The first log line is the configuration, with the password hidden; the limiter logs the *event*, not the client's address:
```bash
docker compose -p tasksteams logs api --no-log-prefix
```
```text
{"time":"2026-11-23T08:47:36.405423788Z","level":"INFO","msg":"configuration","config":{"listen_addr":"0.0.0.0:8000","database":"postgres://tasks_app:xxxxx@db:5432/tasksteams","issuer":"http://localhost:8180/realms/tasksteams","audience":"tasks-api","jwks_url":"http://keycloak:8080/realms/tasksteams/protocol/openid-connect/certs","cors_origins":["http://localhost:4200","http://localhost:5173"],"rate_limit":100,"anonymous_rate_limit":30,"max_body_bytes":1048576}}
```
```text
{"time":"2026-11-23T08:47:40.768905022Z","level":"WARN","msg":"rate limit exceeded","user_id":"","trace_id":"b5c010db23c36e5582b0e6eb27f5007e"}
 Image tasksteams-api:latest Removed
 Network tasksteams-net Removed
```
`user_id` is empty because the throttled client was anonymous.

8. **Backup and restore.** A backup you have never restored is a hope, not a backup. Dump the database in Postgres's custom format inside the container, copy it out, restore it into a *new* database and count the rows:
```bash
docker compose -p tasksteams exec -T db sh -c "pg_dump -U tasks_admin -Fc tasksteams > /tmp/tasksteams.dump"
docker compose -p tasksteams cp db:/tmp/tasksteams.dump ./tasksteams.dump
docker compose -p tasksteams exec -T db createdb -U tasks_admin restore_check
docker compose -p tasksteams exec -T db sh -c "pg_restore -U tasks_admin -d restore_check /tmp/tasksteams.dump"
docker compose -p tasksteams exec -T db psql -U tasks_admin -d restore_check -tA -c "SELECT count(*) FROM tasks"
docker compose -p tasksteams exec -T db psql -U tasks_admin -d tasksteams -tA -c "SELECT count(*) FROM tasks"
```
```text
 tasksteams-db-1 Copying tasksteams-db-1:/tmp/tasksteams.dump to ./tasksteams.dump
 tasksteams-db-1 Copied tasksteams-db-1:/tmp/tasksteams.dump to ./tasksteams.dump
restored copy:
8
original:
8
```
Both counts are equal: the copy holds the data. Delete the dump (`rm tasksteams.dump`, PowerShell `Remove-Item tasksteams.dump`) and clean up the stack; `down -v` deletes the data volume, so run it only after you have the dump you want:
```bash
docker compose -p tasksteams down -v --remove-orphans --rmi local
```

## How it works
### The OWASP API Security Top 10 (2023) against this code
| Risk | What this project does | Where |
|------|------------------------|-------|
| API1 Broken object level authorization | Every object read or write resolves its team and calls `authorize`; strangers get **404**, members without the lead role get 403; ids are UUIDs and malformed ids are 404 before the database | `internal/http/authz.go`, `request.go` (`pathID`), every handler |
| API2 Broken authentication | Only `RS256`, exact issuer, audience `tasks-api`, expiry, signature via cached JWKS; no development stand-in; invalid tokens count as anonymous for rate limiting; the password login itself is Keycloak's (brute-force protection) | `internal/auth/jwt.go`, `jwks.go`, `ratelimit.go` |
| API3 Broken object property level authorization | DTOs list the writable fields and `DisallowUnknownFields` rejects the rest (`id`, `version`, `createdBy` cannot be sent); the store types never go out directly; `GET /v1/users` omits e-mail addresses | `respond.go` (`decodeJSON`), the `*DTO` types, `users.go` |
| API4 Unrestricted resource consumption | `limit` at most 100, `q` at most 100 characters, 1 MiB body, 64 KiB headers, request timeouts, per-user and per-address rate limits, a pool of at most 10 connections, container memory and process limits | `request.go`, `secure.go`, `ratelimit.go`, `cmd/api/main.go`, compose override |
| API5 Broken function level authorization | Every route declares a scope (`handle`); admin routes also call `requireAdmin`; team levels `member` and `lead` | `authz.go`, `audit.go`, `teams.go` |
| API6 Unrestricted access to sensitive business flows | Creating teams is admin-only; creates honour `Idempotency-Key`; every user has a request budget | `teams.go`, `idempotency.go`, `ratelimit.go` |
| API7 Server side request forgery | The only outgoing request is the JWKS download from a configured URL; no user-supplied URL is ever fetched | `internal/auth/jwks.go` |
| API8 Security misconfiguration | Security headers; CORS allow-list, `*` refused at start-up; problem details without stack traces; non-root, read-only, capability-free container; ports bound to loopback; pinned image tags | `secure.go`, `config.go`, `Dockerfile`, compose files |
| API9 Improper inventory management | One contract file (`openapi.yaml`) with a `/v1` prefix, checked by the conformance script; unknown paths answer a uniform 404; the version is in `/health` | platform capstone, `server.go` |
| API10 Unsafe consumption of APIs | Tokens are accepted only from the configured issuer; the JWKS body is size-limited and time-limited; all SQL is parameterised; JSON is decoded strictly | `jwks.go`, `store/*.go`, `respond.go` |

### Logging: what is recorded and what never is
| Recorded | Never recorded |
|----------|----------------|
| method, path (no query string), status, size, duration, trace id, user id | `Authorization` headers and tokens, request and response bodies |
| why authentication failed (`token has invalid audience`), with the trace id | passwords, the database URL's password (redacted by `Config.LogValue`) |
| rate-limit events (user id when known), panics with stack and trace id | e-mail addresses and client IP addresses |

Two kinds of records exist on purpose. The **application log** is for operating the service and may be sampled or rotated. The **audit trail** is a table written by the database trigger in the same transaction as the change, attributed through `set_config`, and the API's database role can append to it but not update or delete rows. Logs answer "what happened to this request"; the audit trail answers "who changed this row".

### Production checklist
| Item | Status here | Before production |
|------|-------------|-------------------|
| TLS | none (loopback) | terminate TLS at a proxy; send HSTS there |
| Secrets | fake values in Compose | a secret store; rotate; never in images |
| Keycloak | `start-dev` | production mode, own database, a hostname, HTTPS |
| Rate limits | in memory, per process | shared store or gateway |
| Images | pinned tags | pin digests, scan images, rebuild on base-image updates |
| Backups | manual dump and restore | scheduled, off-host, restore-tested |
| Dependencies | `go.sum` pins them | `govulncheck ./...` in CI, update regularly |
| Logs | stdout, JSON | ship to a collector, alert on 5xx and on spikes of 401 and 429 |

New terms: **rate limit**, **fixed window**, **CORS**, **preflight**, **CSP**, **HSTS**, **capability**, **redaction**, **audit trail**. See the [glossary](../../GLOSSARY.md).

## Try it
**Exercise.** Write the heart of the limiter without HTTP: `allow(key, limit, now)` counts one request in a fixed window (here 10 seconds), starts a new window when none exists or the old one has ended, denies when the window already holds `limit` requests and otherwise reports how many are left. Passing `now` in makes it testable without sleeping.

**File: `exercise/starter/main.go`**
```go
package main

import (
	"fmt"
	"time"
)

type counter struct {
	resetAt time.Time
	count   int
}

type limiter struct {
	window   time.Duration
	counters map[string]*counter
}

// allow counts one request of key at time now and reports whether it is within limit and how many are left.
// TODO: start a new window when there is none for the key or the old one ended (now is not before resetAt);
// deny when the window already holds limit requests; otherwise count the request.
func (l *limiter) allow(key string, limit int, now time.Time) (ok bool, remaining int) {
	return true, limit
}

func main() {
	l := &limiter{window: 10 * time.Second, counters: map[string]*counter{}}
	start := time.Date(2027, 1, 1, 12, 0, 0, 0, time.UTC)
	for _, offset := range []int{0, 1, 2, 3, 9, 10, 11} {
		ok, remaining := l.allow("user:alice", 3, start.Add(time.Duration(offset)*time.Second))
		if ok {
			fmt.Printf("t+%-2ds allowed remaining=%d\n", offset, remaining)
		} else {
			fmt.Printf("t+%-2ds denied\n", offset)
		}
	}
}
```

<details><summary>Solution</summary>

**File: `exercise/solution/main.go`**
```go
package main

import (
	"fmt"
	"time"
)

type counter struct {
	resetAt time.Time
	count   int
}

type limiter struct {
	window   time.Duration
	counters map[string]*counter
}

// allow counts one request of key at time now and reports whether it is within limit and how many are left.
func (l *limiter) allow(key string, limit int, now time.Time) (ok bool, remaining int) {
	c := l.counters[key]
	if c == nil || !now.Before(c.resetAt) {
		c = &counter{resetAt: now.Add(l.window)}
		l.counters[key] = c
	}
	if c.count >= limit {
		return false, 0
	}
	c.count++
	return true, limit - c.count
}

func main() {
	l := &limiter{window: 10 * time.Second, counters: map[string]*counter{}}
	start := time.Date(2027, 1, 1, 12, 0, 0, 0, time.UTC)
	for _, offset := range []int{0, 1, 2, 3, 9, 10, 11} {
		ok, remaining := l.allow("user:alice", 3, start.Add(time.Duration(offset)*time.Second))
		if ok {
			fmt.Printf("t+%-2ds allowed remaining=%d\n", offset, remaining)
		} else {
			fmt.Printf("t+%-2ds denied\n", offset)
		}
	}
}
```
The check `!now.Before(c.resetAt)` means a request exactly at the end of the window already belongs to the next one, so at `t+10s` the counter starts again. Output:
```text
t+0 s allowed remaining=2
t+1 s allowed remaining=1
t+2 s allowed remaining=0
t+3 s denied
t+9 s denied
t+10s allowed remaining=2
t+11s allowed remaining=1
```
</details>

## Check yourself
1. Why does the rate limiter run after authentication but CORS runs before it?
   <details><summary>Answer</summary>The limiter needs the user id to count per user. A CORS preflight carries no credentials and must be answered before any check that would refuse it.</details>
2. Why is `X-Forwarded-For` ignored for the anonymous limit?
   <details><summary>Answer</summary>Any client can send it, so trusting it lets an attacker choose a new address for every request and never be limited.</details>
3. What do `read_only`, `cap_drop` and `no-new-privileges` protect against?
   <details><summary>Answer</summary>They limit what an attacker can do after taking over the process: write files, use privileged operations, gain more privileges.</details>
4. A client with a valid token sends 101 requests in a minute. Which status do they get for the 101st, and which header says when to retry?
   <details><summary>Answer</summary>429 with `Retry-After` (seconds); `RateLimit-Reset` says the same.</details>

## Common mistakes
| Symptom or error text | Cause | Fix |
|---|---|---|
| `git status` lists `.env`, `bin/` or a `.exe` file as new files, or `docker history` shows secrets in a layer | `.gitignore` or `.dockerignore` is missing, or created after the files were already tracked or copied | Create both files as shown above; for files already tracked run `git rm --cached .env` (and `git rm -r --cached bin`), commit, and replace any real secret that was ever committed |
| `{"type":".../rate-limited","title":"Too many requests","status":429,"detail":"Retry in 60 seconds.",...}` while testing | You exceeded the per-address limit for anonymous calls (30 per minute) | Wait for `Retry-After`, or send a token |
| `{"type":".../payload-too-large",...,"status":413,"detail":"The request body must be at most 1048576 bytes."}` | The body is over the limit | Send less, or raise `MAX_BODY_BYTES` knowingly |
| No `Access-Control-Allow-Origin` in the browser | The page's origin is not in `CORS_ORIGINS` | Add the exact origin (scheme, host and port) |
| The browser blocks `PATCH` although the API works with `curl` | The preflight failed: a header such as `If-Match` is not in `Access-Control-Allow-Headers` | The allowed list is in `secure.go`; add what you really need |
| A 405 on `OPTIONS` from `curl` | A preflight needs `Access-Control-Request-Method` and an allowed `Origin` | Send both headers as in step 3 |

## Best practice
Defend in layers: limit what a caller may consume, refuse what the contract does not allow, send restrictive headers by default, run the process with the fewest rights and keep secrets out of logs. Source: OWASP API Security Top 10 2023 https://owasp.org/API-Security/editions/2023/en/0x11-t10/, OWASP REST Security Cheat Sheet https://cheatsheetseries.owasp.org/cheatsheets/REST_Security_Cheat_Sheet.html and Docker security https://docs.docker.com/engine/security/

## Next lesson
This was the last chapter of the Go backend. Continue with a client capstone that uses this API (web-angular, web-react, mobile-flutter or mobile-kotlin), or implement the same contract in another stack and compare the two conformance runs.
