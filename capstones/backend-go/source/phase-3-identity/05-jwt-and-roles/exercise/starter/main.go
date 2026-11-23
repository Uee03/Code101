package main

import (
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
// TODO: split the token at the dots, decode the middle part with base64.RawURLEncoding and unmarshal the JSON.
func payloadOf(token string) (claims, error) {
	return claims{}, fmt.Errorf("not implemented")
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
