package auth

import (
	"net/http"
	"slices"
)

// RequireAnyRole lets a request through when the caller has at least one of the given roles.
// It must run after Middleware. No claims in the context means 401; claims without a matching role mean 403.
func RequireAnyRole(roles ...string) func(http.Handler) http.Handler {
	return func(next http.Handler) http.Handler {
		return http.HandlerFunc(func(w http.ResponseWriter, r *http.Request) {
			claims, ok := FromContext(r.Context())
			if !ok {
				unauthorized(w)
				return
			}
			for _, role := range roles {
				if slices.Contains(claims.Roles, role) {
					next.ServeHTTP(w, r)
					return
				}
			}
			forbidden(w)
		})
	}
}

// RequireSelfOrRole lets a request through when the token's subject equals the {id} path value
// of the route, or when the caller has the given role (for example an administrator).
// It must run after Middleware and be used on a route with an {id} wildcard.
func RequireSelfOrRole(role string) func(http.Handler) http.Handler {
	return func(next http.Handler) http.Handler {
		return http.HandlerFunc(func(w http.ResponseWriter, r *http.Request) {
			claims, ok := FromContext(r.Context())
			if !ok {
				unauthorized(w)
				return
			}
			if claims.Subject == r.PathValue("id") || slices.Contains(claims.Roles, role) {
				next.ServeHTTP(w, r)
				return
			}
			forbidden(w)
		})
	}
}
