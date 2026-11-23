package main

import (
	"bytes"
	"crypto/ed25519"
	"fmt"
	"net/http"
	"net/http/httptest"
	"strings"
	"time"

	"github.com/golang-jwt/jwt/v5"
)

func main() {
	demoValidation()
	demoTokens()
	demoMTLS()
}

func demoValidation() {
	decode := func(body string, maxBytes int64) (CreateUser, error) {
		req := httptest.NewRequest(http.MethodPost, "/users", strings.NewReader(body))
		return DecodeStrict[CreateUser](httptest.NewRecorder(), req, maxBytes)
	}

	user, err := decode(`{"name":"Ada","email":"ada@example.com","role":"member"}`, 1024)
	fmt.Printf("validate: valid request accepted: %+v (err=%v, problems=%v)\n", user, err, user.Validate())

	_, err = decode(`{"name":"Ada","admin":true}`, 1024)
	fmt.Println("validate: unknown field rejected:", err)

	_, err = decode(`{"name":"`+strings.Repeat("a", 100)+`"}`, 32)
	fmt.Println("validate: oversized body rejected:", err)

	user, _ = decode(`{"name":"","email":"not-an-email","role":"root"}`, 1024)
	fmt.Println("validate: invalid values:", strings.Join(user.Validate(), "; "))
}

func demoTokens() {
	// A fixed seed makes the demo repeatable. Real keys come from a key
	// management system or are generated once and stored as secrets.
	seed := bytes.Repeat([]byte{7}, ed25519.SeedSize)
	priv := ed25519.NewKeyFromSeed(seed)
	keys := KeySet{"k1": priv.Public().(ed25519.PublicKey)}

	now := time.Date(2026, 1, 1, 12, 0, 0, 0, time.UTC)
	clock := func() time.Time { return now }

	token, err := NewIssuer("k1", priv, clock).Issue("billing", "inventory", 2*time.Minute)
	if err != nil {
		fmt.Println("jwt: issue failed:", err)
		return
	}

	subject, err := NewVerifier(keys, "inventory", clock).Verify(token)
	fmt.Printf("jwt: billing -> inventory accepted: subject=%s (err=%v)\n", subject, err)

	_, err = NewVerifier(keys, "payments", clock).Verify(token)
	fmt.Printf("jwt: same token presented to payments: rejected (%s)\n", Reason(err))

	later := func() time.Time { return now.Add(10 * time.Minute) }
	_, err = NewVerifier(keys, "inventory", later).Verify(token)
	fmt.Printf("jwt: ten minutes later: rejected (%s)\n", Reason(err))

	attacker := ed25519.NewKeyFromSeed(bytes.Repeat([]byte{8}, ed25519.SeedSize))
	forged, _ := NewIssuer("k1", attacker, clock).Issue("billing", "inventory", 2*time.Minute)
	_, err = NewVerifier(keys, "inventory", clock).Verify(forged)
	fmt.Printf("jwt: forged with another key: rejected (%s)\n", Reason(err))

	unsigned, _ := jwt.NewWithClaims(jwt.SigningMethodNone, jwt.RegisteredClaims{Subject: "billing"}).SignedString(jwt.UnsafeAllowNoneSignatureType)
	_, err = NewVerifier(keys, "inventory", clock).Verify(unsigned)
	fmt.Printf("jwt: alg none token: rejected=%t\n", err != nil)
}

func demoMTLS() {
	with, without, err := mtlsDemo()
	if err != nil {
		fmt.Println("mtls: demo failed:", err)
		return
	}
	fmt.Println("mtls: with client certificate ->", with)
	fmt.Println("mtls: without client certificate ->", without)
}
