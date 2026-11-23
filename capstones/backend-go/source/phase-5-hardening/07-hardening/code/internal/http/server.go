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
