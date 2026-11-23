package auth

import (
	"errors"
	"fmt"
	"time"

	"github.com/golang-jwt/jwt/v5"
)

// Claims is the payload of our tokens: the standard registered claims (iss, sub, aud, exp, iat)
// plus the roles of the user.
type Claims struct {
	Roles []string `json:"roles"`
	jwt.RegisteredClaims
}

// ErrInvalidToken is returned for every verification failure. Callers must not tell the client why.
var ErrInvalidToken = errors.New("invalid token")

// Service signs and verifies tokens with a shared secret (HS256).
type Service struct {
	secret   []byte
	issuer   string
	audience string
	now      func() time.Time
}

// NewService refuses a short secret: HS256 is only as strong as its key.
func NewService(secret, issuer, audience string) (*Service, error) {
	if len(secret) < 32 {
		return nil, errors.New("must be set and at least 32 bytes long")
	}
	return &Service{secret: []byte(secret), issuer: issuer, audience: audience, now: time.Now}, nil
}

// Mint creates a signed token for subject with the given roles, valid for ttl.
// In production an identity provider issues tokens; this stands in for it in the lesson.
func (s *Service) Mint(subject string, roles []string, ttl time.Duration) (string, error) {
	now := s.now()
	claims := Claims{
		Roles: roles,
		RegisteredClaims: jwt.RegisteredClaims{
			Issuer:    s.issuer,
			Subject:   subject,
			Audience:  jwt.ClaimStrings{s.audience},
			IssuedAt:  jwt.NewNumericDate(now),
			ExpiresAt: jwt.NewNumericDate(now.Add(ttl)),
		},
	}
	return jwt.NewWithClaims(jwt.SigningMethodHS256, claims).SignedString(s.secret)
}

// Verify checks the signature, the algorithm, the issuer, the audience and the expiry.
func (s *Service) Verify(tokenString string) (*Claims, error) {
	claims := &Claims{}
	token, err := jwt.ParseWithClaims(tokenString, claims,
		func(t *jwt.Token) (any, error) { return s.secret, nil },
		jwt.WithValidMethods([]string{jwt.SigningMethodHS256.Alg()}),
		jwt.WithIssuer(s.issuer),
		jwt.WithAudience(s.audience),
		jwt.WithExpirationRequired(),
		jwt.WithTimeFunc(s.now),
		jwt.WithLeeway(5*time.Second),
	)
	if err != nil || !token.Valid {
		return nil, fmt.Errorf("%w: %v", ErrInvalidToken, err)
	}
	return claims, nil
}
