package main

import (
	"crypto/sha256"
	"encoding/hex"
	"fmt"
)

// requestHash identifies a request for the Idempotency-Key check: the same key may only be reused for the same request.
// TODO: hash the method, a space, the path, a newline and the body with SHA-256 and return the hex text.
func requestHash(method, path string, body []byte) string {
	_ = sha256.Sum256 // remove this line once you use the packages
	_ = hex.EncodeToString
	return ""
}

func main() {
	first := requestHash("POST", "/v1/teams", []byte(`{"name":"A"}`))
	again := requestHash("POST", "/v1/teams", []byte(`{"name":"A"}`))
	otherBody := requestHash("POST", "/v1/teams", []byte(`{"name":"B"}`))
	otherPath := requestHash("POST", "/v1/projects", []byte(`{"name":"A"}`))
	fmt.Println("first       ", first)
	fmt.Println("same request", first == again)
	fmt.Println("other body  ", first == otherBody)
	fmt.Println("other path  ", first == otherPath)
}
