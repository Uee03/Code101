package main

import (
	"encoding/base64"
	"encoding/json"
	"errors"
	"fmt"
	"strings"
)

// A toy token for practice: header, payload and a fake signature. Nothing here is a real credential.
const token = "eyJhbGciOiJSUzI1NiIsImtpZCI6ImRlbW8ifQ.eyJzdWIiOiJib2IiLCJhdWQiOlsidGFza3MtYXBpIiwiYWNjb3VudCJdLCJyZWFsbV9hY2Nlc3MiOnsicm9sZXMiOlsibWVtYmVyIl19LCJzY29wZSI6Im9wZW5pZCB0YXNrczpyZWFkIn0.c2lnbmF0dXJl"

type claims struct {
	Subject     string   `json:"sub"`
	Audience    []string `json:"aud"`
	Scope       string   `json:"scope"`
	RealmAccess struct {
		Roles []string `json:"roles"`
	} `json:"realm_access"`
}

// payloadOf reads the claims of a token WITHOUT checking its signature, only to look inside it.
func payloadOf(token string) (claims, error) {
	parts := strings.Split(token, ".")
	if len(parts) != 3 {
		return claims{}, errors.New("a JWT has three parts separated by dots")
	}
	raw, err := base64.RawURLEncoding.DecodeString(parts[1])
	if err != nil {
		return claims{}, err
	}
	var c claims
	return c, json.Unmarshal(raw, &c)
}

func main() {
	c, err := payloadOf(token)
	if err != nil {
		fmt.Println("error:", err)
		return
	}
	fmt.Println("sub:   ", c.Subject)
	fmt.Println("aud:   ", c.Audience)
	fmt.Println("roles: ", c.RealmAccess.Roles)
	fmt.Println("scopes:", strings.Fields(c.Scope))
	fmt.Println("this payload was read, not verified: never authorize anyone from it")
}
