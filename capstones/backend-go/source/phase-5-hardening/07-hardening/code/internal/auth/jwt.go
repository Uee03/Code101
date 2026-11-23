package auth

import (
	"context"
	"errors"
	"fmt"
	"net/http"
	"strings"
	"sync"
	"time"

	"github.com/golang-jwt/jwt/v5"
)

// UserRegistry creates the users row of a caller the first time the caller is seen.
type UserRegistry interface {
	EnsureUser(ctx context.Context, id, username, email, displayName string) error
}

// JWT validates Keycloak access tokens (RFC 9068 JWT access tokens) and builds the Principal from their claims.
type JWT struct {
	parser *jwt.Parser
	keys   *JWKS
	users  UserRegistry
	known  sync.Map // subjects whose users row exists, so most requests skip the database
}

// NewJWT builds a validator for one issuer and one audience.
//
// The parser options are the whole validation policy:
//   - only RS256, so "alg": "none" and an HMAC token signed with the public key are refused;
//   - iss must equal the configured issuer exactly;
//   - aud (a string or a list in the token) must contain our audience;
//   - exp must be present and in the future, nbf is checked when present, both with 30 seconds of clock skew.
func NewJWT(issuer, audience string, keys *JWKS, users UserRegistry) *JWT {
	return &JWT{
		keys:  keys,
		users: users,
		parser: jwt.NewParser(
			jwt.WithValidMethods([]string{"RS256"}),
			jwt.WithIssuer(issuer),
			jwt.WithAudience(audience),
			jwt.WithExpirationRequired(),
			jwt.WithLeeway(30*time.Second),
		),
	}
}

// accessClaims are the claims of a Keycloak access token that the API uses besides the registered ones.
type accessClaims struct {
	jwt.RegisteredClaims
	Scope             string `json:"scope"`
	PreferredUsername string `json:"preferred_username"`
	Email             string `json:"email"`
	Name              string `json:"name"`
	RealmAccess       struct {
		Roles []string `json:"roles"`
	} `json:"realm_access"`
}

// Authenticate implements Authenticator: (nil, nil) without a header, an error for a token that is not valid.
func (v *JWT) Authenticate(r *http.Request) (*Principal, error) {
	header := r.Header.Get("Authorization")
	if header == "" {
		return nil, nil
	}
	scheme, token, found := strings.Cut(header, " ")
	if !found || !strings.EqualFold(scheme, "Bearer") || strings.TrimSpace(token) == "" {
		return nil, errors.New("the Authorization header is not a Bearer token")
	}
	var claims accessClaims
	if _, err := v.parser.ParseWithClaims(strings.TrimSpace(token), &claims, v.keyFunc(r.Context())); err != nil {
		return nil, fmt.Errorf("token rejected: %w", err)
	}
	if claims.Subject == "" {
		return nil, errors.New("token rejected: no sub claim")
	}
	p := &Principal{
		ID:          claims.Subject,
		Username:    firstNonEmpty(claims.PreferredUsername, claims.Subject),
		Email:       firstNonEmpty(claims.Email, claims.Subject+"@unknown.invalid"),
		DisplayName: firstNonEmpty(claims.Name, claims.PreferredUsername, claims.Subject),
		Roles:       claims.RealmAccess.Roles,
		Scopes:      strings.Fields(claims.Scope),
	}
	if err := v.ensureUser(r.Context(), p); err != nil {
		return nil, fmt.Errorf("register user: %w", err)
	}
	return p, nil
}

// keyFunc is called by the parser after it has read the header: it finds the public key for the token's kid.
func (v *JWT) keyFunc(ctx context.Context) jwt.Keyfunc {
	return func(token *jwt.Token) (any, error) {
		kid, _ := token.Header["kid"].(string)
		if kid == "" {
			return nil, errors.New("the token header has no kid")
		}
		return v.keys.Key(ctx, kid)
	}
}

func (v *JWT) ensureUser(ctx context.Context, p *Principal) error {
	if _, ok := v.known.Load(p.ID); ok {
		return nil
	}
	if err := v.users.EnsureUser(ctx, p.ID, p.Username, p.Email, p.DisplayName); err != nil {
		return err
	}
	v.known.Store(p.ID, struct{}{})
	return nil
}

func firstNonEmpty(values ...string) string {
	for _, value := range values {
		if value != "" {
			return value
		}
	}
	return ""
}
