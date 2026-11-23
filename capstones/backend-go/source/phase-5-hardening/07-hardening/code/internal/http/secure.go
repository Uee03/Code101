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
