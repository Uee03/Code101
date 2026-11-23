package auth

import (
	"net/http"
	"net/http/httptest"
	"testing"
	"time"
)

// protect puts mw behind Middleware on a route with an {id} wildcard, as a real service would.
func protect(svc *Service, mw func(http.Handler) http.Handler) http.Handler {
	ok := http.HandlerFunc(func(w http.ResponseWriter, r *http.Request) { w.WriteHeader(http.StatusOK) })
	mux := http.NewServeMux()
	mux.Handle("GET /users/{id}", svc.Middleware(mw(ok)))
	return mux
}

// statusFor calls GET /users/ada with a token for subject and roles (no token when subject is empty).
func statusFor(t *testing.T, svc *Service, h http.Handler, subject string, roles []string) int {
	t.Helper()
	req := httptest.NewRequest("GET", "/users/ada", nil)
	if subject != "" {
		token, err := svc.Mint(subject, roles, time.Hour)
		if err != nil {
			t.Fatalf("Mint: %v", err)
		}
		req.Header.Set("Authorization", "Bearer "+token)
	}
	rec := httptest.NewRecorder()
	h.ServeHTTP(rec, req)
	return rec.Code
}

func TestRequireAnyRole(t *testing.T) {
	svc := serviceAt(t, testSecret, "iss", "aud", t0)
	h := protect(svc, RequireAnyRole("admin", "auditor"))

	tests := []struct {
		name    string
		subject string
		roles   []string
		want    int
	}{
		{"has the second role", "grace", []string{"auditor"}, http.StatusOK},
		{"has an unrelated role", "ada", []string{"user"}, http.StatusForbidden},
		{"has no roles", "ada", nil, http.StatusForbidden},
		{"has no token", "", nil, http.StatusUnauthorized},
	}
	for _, tc := range tests {
		t.Run(tc.name, func(t *testing.T) {
			if got := statusFor(t, svc, h, tc.subject, tc.roles); got != tc.want {
				t.Fatalf("status %d, want %d", got, tc.want)
			}
		})
	}
}

func TestRequireSelfOrRole(t *testing.T) {
	svc := serviceAt(t, testSecret, "iss", "aud", t0)
	h := protect(svc, RequireSelfOrRole("admin"))

	tests := []struct {
		name    string
		subject string
		roles   []string
		want    int
	}{
		{"owner of the resource", "ada", nil, http.StatusOK},
		{"someone else", "linus", nil, http.StatusForbidden},
		{"administrator", "linus", []string{"admin"}, http.StatusOK},
	}
	for _, tc := range tests {
		t.Run(tc.name, func(t *testing.T) {
			if got := statusFor(t, svc, h, tc.subject, tc.roles); got != tc.want {
				t.Fatalf("status %d, want %d", got, tc.want)
			}
		})
	}
}
