package main

import (
	"encoding/json"
	"errors"
	"fmt"
	"io"
	"net/http"
	"net/mail"
	"slices"
	"strings"
	"unicode"
	"unicode/utf8"
)

// ErrBodyTooLarge is returned when a request body exceeds the allowed size.
var ErrBodyTooLarge = errors.New("request body too large")

// CreateUser is the shape of one request body.
type CreateUser struct {
	Name  string `json:"name"`
	Email string `json:"email"`
	Role  string `json:"role"`
}

var allowedRoles = []string{"member", "admin"}

// Validate checks every field against an allow-list or a bound and returns
// one message per problem, in a fixed order. No messages means valid.
func (c CreateUser) Validate() []string {
	var problems []string
	if n := utf8.RuneCountInString(c.Name); n < 1 || n > 64 || strings.IndexFunc(c.Name, unicode.IsControl) >= 0 {
		problems = append(problems, "name: must be 1 to 64 characters without control characters")
	}
	if addr, err := mail.ParseAddress(c.Email); err != nil || addr.Address != c.Email || len(c.Email) > 254 {
		problems = append(problems, "email: not a valid address")
	}
	if !slices.Contains(allowedRoles, c.Role) {
		problems = append(problems, "role: must be one of "+strings.Join(allowedRoles, ", "))
	}
	return problems
}

// DecodeStrict reads exactly one JSON value of type T from the request body.
// It caps the size, rejects unknown fields and rejects trailing data.
func DecodeStrict[T any](w http.ResponseWriter, r *http.Request, maxBytes int64) (T, error) {
	var v T
	r.Body = http.MaxBytesReader(w, r.Body, maxBytes)
	dec := json.NewDecoder(r.Body)
	dec.DisallowUnknownFields()

	if err := dec.Decode(&v); err != nil {
		var tooLarge *http.MaxBytesError
		if errors.As(err, &tooLarge) {
			return v, ErrBodyTooLarge
		}
		return v, fmt.Errorf("decode: %w", err)
	}
	if _, err := dec.Token(); !errors.Is(err, io.EOF) {
		return v, errors.New("decode: body must contain a single JSON value")
	}
	return v, nil
}
