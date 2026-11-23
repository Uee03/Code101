package main

import (
	"crypto/ed25519"
	"crypto/rand"
	"errors"
	"fmt"
	"time"

	"github.com/golang-jwt/jwt/v5"
)

const (
	tokenIssuer  = "https://auth.internal.example"
	maxTokenLife = 5 * time.Minute
)

// KeySet maps a key id (the "kid" header) to a public key. Having several
// entries is how keys are rotated without downtime.
type KeySet map[string]ed25519.PublicKey

// Issuer signs short-lived service-to-service tokens.
type Issuer struct {
	kid string
	key ed25519.PrivateKey
	now func() time.Time
}

func NewIssuer(kid string, key ed25519.PrivateKey, now func() time.Time) *Issuer {
	return &Issuer{kid: kid, key: key, now: now}
}

// Issue creates a token that says: the service called subject may call the
// service called audience during the next ttl.
func (i *Issuer) Issue(subject, audience string, ttl time.Duration) (string, error) {
	if ttl <= 0 || ttl > maxTokenLife {
		return "", fmt.Errorf("ttl must be between 0 and %s", maxTokenLife)
	}
	now := i.now()
	claims := jwt.RegisteredClaims{
		Issuer:    tokenIssuer,
		Subject:   subject,
		Audience:  jwt.ClaimStrings{audience},
		IssuedAt:  jwt.NewNumericDate(now),
		NotBefore: jwt.NewNumericDate(now),
		ExpiresAt: jwt.NewNumericDate(now.Add(ttl)),
		ID:        rand.Text(),
	}
	token := jwt.NewWithClaims(jwt.SigningMethodEdDSA, claims)
	token.Header["kid"] = i.kid
	return token.SignedString(i.key)
}

// Verifier checks tokens presented to one service.
type Verifier struct {
	keys     KeySet
	audience string
	now      func() time.Time
}

func NewVerifier(keys KeySet, audience string, now func() time.Time) *Verifier {
	return &Verifier{keys: keys, audience: audience, now: now}
}

// Verify returns the calling service's name, or an error.
func (v *Verifier) Verify(tokenString string) (string, error) {
	claims := &jwt.RegisteredClaims{}
	_, err := jwt.ParseWithClaims(tokenString, claims, v.keyFunc,
		jwt.WithValidMethods([]string{"EdDSA"}),
		jwt.WithIssuer(tokenIssuer),
		jwt.WithAudience(v.audience),
		jwt.WithExpirationRequired(),
		jwt.WithIssuedAt(),
		jwt.WithLeeway(5*time.Second),
		jwt.WithTimeFunc(v.now),
	)
	if err != nil {
		return "", err
	}
	if claims.Subject == "" {
		return "", errors.New("token has no subject")
	}
	return claims.Subject, nil
}

// keyFunc picks the public key by the kid header. It never trusts the token
// to say which algorithm or which key type to use.
func (v *Verifier) keyFunc(t *jwt.Token) (any, error) {
	kid, _ := t.Header["kid"].(string)
	key, ok := v.keys[kid]
	if !ok {
		return nil, fmt.Errorf("unknown key id %q", kid)
	}
	return key, nil
}

// Reason turns a verification error into a short label that is safe to put
// in logs, metrics and responses.
func Reason(err error) string {
	switch {
	case err == nil:
		return "ok"
	case errors.Is(err, jwt.ErrTokenExpired):
		return "expired"
	case errors.Is(err, jwt.ErrTokenInvalidAudience):
		return "wrong audience"
	case errors.Is(err, jwt.ErrTokenInvalidIssuer):
		return "wrong issuer"
	case errors.Is(err, jwt.ErrTokenSignatureInvalid):
		return "bad signature"
	case errors.Is(err, jwt.ErrTokenMalformed):
		return "malformed"
	case errors.Is(err, jwt.ErrTokenUnverifiable):
		return "unverifiable"
	default:
		return "invalid"
	}
}
