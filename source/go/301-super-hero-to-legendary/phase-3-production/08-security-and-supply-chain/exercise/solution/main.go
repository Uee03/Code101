package main

import (
	"bytes"
	"crypto/ed25519"
	"fmt"
	"time"

	"github.com/golang-jwt/jwt/v5"
)

var now = time.Date(2026, 1, 1, 12, 0, 0, 0, time.UTC)

func sign(method jwt.SigningMethod, key any, c jwt.RegisteredClaims) string {
	s, err := jwt.NewWithClaims(method, c).SignedString(key)
	if err != nil {
		panic(err)
	}
	return s
}

func claims(audience string, expires *jwt.NumericDate) jwt.RegisteredClaims {
	return jwt.RegisteredClaims{
		Issuer:    "auth.example",
		Subject:   "billing",
		Audience:  jwt.ClaimStrings{audience},
		IssuedAt:  jwt.NewNumericDate(now),
		ExpiresAt: expires,
	}
}

// verify accepts only: EdDSA tokens, issued by "auth.example", meant for the
// audience "inventory", that carry an expiry that has not passed.
func verify(tokenString string, pub ed25519.PublicKey) error {
	_, err := jwt.ParseWithClaims(tokenString, &jwt.RegisteredClaims{},
		func(*jwt.Token) (any, error) { return pub, nil },
		jwt.WithValidMethods([]string{"EdDSA"}),
		jwt.WithIssuer("auth.example"),
		jwt.WithAudience("inventory"),
		jwt.WithExpirationRequired(),
		jwt.WithTimeFunc(func() time.Time { return now }), // fixed clock for a stable demo
	)
	return err
}

func main() {
	priv := ed25519.NewKeyFromSeed(bytes.Repeat([]byte{9}, ed25519.SeedSize))
	pub := priv.Public().(ed25519.PublicKey)
	soon := jwt.NewNumericDate(now.Add(time.Minute))

	cases := []struct{ name, token string }{
		{"billing", sign(jwt.SigningMethodEdDSA, priv, claims("inventory", soon))},
		{"wrong audience", sign(jwt.SigningMethodEdDSA, priv, claims("payments", soon))},
		{"expired", sign(jwt.SigningMethodEdDSA, priv, claims("inventory", jwt.NewNumericDate(now.Add(-time.Hour))))},
		{"alg none", sign(jwt.SigningMethodNone, jwt.UnsafeAllowNoneSignatureType, claims("inventory", soon))},
		{"no expiry", sign(jwt.SigningMethodEdDSA, priv, claims("inventory", nil))},
	}
	for _, c := range cases {
		if err := verify(c.token, pub); err != nil {
			fmt.Printf("%s: rejected\n", c.name)
		} else {
			fmt.Printf("%s: accepted\n", c.name)
		}
	}
}
