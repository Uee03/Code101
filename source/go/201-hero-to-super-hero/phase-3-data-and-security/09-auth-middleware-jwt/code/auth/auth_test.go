package auth

import (
	"errors"
	"net/http"
	"net/http/httptest"
	"testing"
	"time"

	"github.com/golang-jwt/jwt/v5"
)

const testSecret = "0123456789abcdef0123456789abcdef"

var t0 = time.Date(2030, 1, 1, 12, 0, 0, 0, time.UTC)

// serviceAt builds a Service whose clock is frozen at now, so expiry tests never depend on the real time.
func serviceAt(t *testing.T, secret, issuer, audience string, now time.Time) *Service {
	t.Helper()
	svc, err := NewService(secret, issuer, audience)
	if err != nil {
		t.Fatalf("NewService: %v", err)
	}
	svc.now = func() time.Time { return now }
	return svc
}

func TestMintThenVerify(t *testing.T) {
	svc := serviceAt(t, testSecret, "iss", "aud", t0)
	token, err := svc.Mint("ada", []string{"admin"}, time.Hour)
	if err != nil {
		t.Fatalf("Mint: %v", err)
	}
	claims, err := svc.Verify(token)
	if err != nil {
		t.Fatalf("Verify: %v", err)
	}
	if claims.Subject != "ada" || len(claims.Roles) != 1 || claims.Roles[0] != "admin" {
		t.Fatalf("unexpected claims: %+v", claims)
	}
}

func TestNewServiceRejectsShortSecret(t *testing.T) {
	if _, err := NewService("too-short", "iss", "aud"); err == nil {
		t.Fatal("a short secret should be refused")
	}
}

func TestVerifyRejectsBadTokens(t *testing.T) {
	good := serviceAt(t, testSecret, "iss", "aud", t0)
	valid := Claims{
		Roles: []string{"admin"},
		RegisteredClaims: jwt.RegisteredClaims{
			Issuer:    "iss",
			Subject:   "ada",
			Audience:  jwt.ClaimStrings{"aud"},
			ExpiresAt: jwt.NewNumericDate(t0.Add(time.Hour)),
		},
	}
	sign := func(method jwt.SigningMethod, key any, c Claims) string {
		s, err := jwt.NewWithClaims(method, c).SignedString(key)
		if err != nil {
			t.Fatalf("sign: %v", err)
		}
		return s
	}
	with := func(change func(*Claims)) Claims {
		c := valid
		change(&c)
		return c
	}
	secret := []byte(testSecret)

	// The positive control proves the failing cases below fail for their own reason.
	if _, err := good.Verify(sign(jwt.SigningMethodHS256, secret, valid)); err != nil {
		t.Fatalf("a correct token was rejected: %v", err)
	}

	tests := []struct {
		name  string
		token string
	}{
		{"expired", sign(jwt.SigningMethodHS256, secret, with(func(c *Claims) { c.ExpiresAt = jwt.NewNumericDate(t0.Add(-time.Hour)) }))},
		{"no expiry", sign(jwt.SigningMethodHS256, secret, with(func(c *Claims) { c.ExpiresAt = nil }))},
		{"wrong secret", sign(jwt.SigningMethodHS256, []byte("another-secret-another-secret-123456"), valid)},
		{"wrong issuer", sign(jwt.SigningMethodHS256, secret, with(func(c *Claims) { c.Issuer = "someone-else" }))},
		{"wrong audience", sign(jwt.SigningMethodHS256, secret, with(func(c *Claims) { c.Audience = jwt.ClaimStrings{"other"} }))},
		{"algorithm none", sign(jwt.SigningMethodNone, jwt.UnsafeAllowNoneSignatureType, valid)},
		{"garbage", "not-a-token"},
		{"empty", ""},
	}
	for _, tc := range tests {
		t.Run(tc.name, func(t *testing.T) {
			if _, err := good.Verify(tc.token); !errors.Is(err, ErrInvalidToken) {
				t.Fatalf("got %v, want ErrInvalidToken", err)
			}
		})
	}
}

func TestMiddleware(t *testing.T) {
	svc := serviceAt(t, testSecret, "iss", "aud", t0)
	handler := svc.Middleware(RequireRole("admin")(http.HandlerFunc(func(w http.ResponseWriter, r *http.Request) {
		claims, _ := FromContext(r.Context())
		_, _ = w.Write([]byte("hello " + claims.Subject))
	})))
	adminToken, _ := svc.Mint("grace", []string{"admin"}, time.Hour)
	userToken, _ := svc.Mint("ada", nil, time.Hour)

	tests := []struct {
		name   string
		header string
		want   int
	}{
		{"no header", "", http.StatusUnauthorized},
		{"wrong scheme", "Basic abc", http.StatusUnauthorized},
		{"bad token", "Bearer nope", http.StatusUnauthorized},
		{"user without the role", "Bearer " + userToken, http.StatusForbidden},
		{"admin", "Bearer " + adminToken, http.StatusOK},
	}
	for _, tc := range tests {
		t.Run(tc.name, func(t *testing.T) {
			rec := httptest.NewRecorder()
			req := httptest.NewRequest("GET", "/", nil)
			if tc.header != "" {
				req.Header.Set("Authorization", tc.header)
			}
			handler.ServeHTTP(rec, req)
			if rec.Code != tc.want {
				t.Fatalf("status %d, want %d", rec.Code, tc.want)
			}
			if tc.want == http.StatusUnauthorized && rec.Header().Get("WWW-Authenticate") == "" {
				t.Fatal("a 401 must carry a WWW-Authenticate header")
			}
		})
	}
}
