package auth

import (
	"context"
	"encoding/json"
	"log"
	"net/http"
	"slices"
	"strings"
)

// ctxKey is a private type, so no other package can read or overwrite our context value by accident.
type ctxKey struct{}

// FromContext returns the claims that Middleware stored for this request.
func FromContext(ctx context.Context) (*Claims, bool) {
	claims, ok := ctx.Value(ctxKey{}).(*Claims)
	return claims, ok
}

// Middleware requires a valid bearer token. It answers 401 itself and calls next only for authenticated requests.
func (s *Service) Middleware(next http.Handler) http.Handler {
	return http.HandlerFunc(func(w http.ResponseWriter, r *http.Request) {
		token, ok := bearerToken(r)
		if !ok {
			unauthorized(w)
			return
		}
		claims, err := s.Verify(token)
		if err != nil {
			log.Printf("auth: token rejected: %v", err)
			unauthorized(w)
			return
		}
		ctx := context.WithValue(r.Context(), ctxKey{}, claims)
		next.ServeHTTP(w, r.WithContext(ctx))
	})
}

// RequireRole must run after Middleware. It answers 403 when the caller lacks the role.
func RequireRole(role string) func(http.Handler) http.Handler {
	return func(next http.Handler) http.Handler {
		return http.HandlerFunc(func(w http.ResponseWriter, r *http.Request) {
			claims, ok := FromContext(r.Context())
			if !ok {
				unauthorized(w)
				return
			}
			if !slices.Contains(claims.Roles, role) {
				forbidden(w)
				return
			}
			next.ServeHTTP(w, r)
		})
	}
}

// bearerToken extracts the token from "Authorization: Bearer <token>".
func bearerToken(r *http.Request) (string, bool) {
	const prefix = "Bearer "
	header := r.Header.Get("Authorization")
	if len(header) <= len(prefix) || !strings.EqualFold(header[:len(prefix)], prefix) {
		return "", false
	}
	return strings.TrimSpace(header[len(prefix):]), true
}

type problem struct {
	Type   string `json:"type"`
	Title  string `json:"title"`
	Status int    `json:"status"`
	Detail string `json:"detail"`
}

// unauthorized means "we do not know who you are": 401 plus the challenge header.
func unauthorized(w http.ResponseWriter) {
	w.Header().Set("WWW-Authenticate", `Bearer realm="api"`)
	writeProblem(w, http.StatusUnauthorized, "Unauthorized", "A valid bearer token is required.")
}

// forbidden means "we know who you are, and you may not": 403.
func forbidden(w http.ResponseWriter) {
	writeProblem(w, http.StatusForbidden, "Forbidden", "You do not have the role required for this resource.")
}

func writeProblem(w http.ResponseWriter, status int, title, detail string) {
	w.Header().Set("Content-Type", "application/problem+json")
	w.WriteHeader(status)
	_ = json.NewEncoder(w).Encode(problem{Type: "about:blank", Title: title, Status: status, Detail: detail})
}
