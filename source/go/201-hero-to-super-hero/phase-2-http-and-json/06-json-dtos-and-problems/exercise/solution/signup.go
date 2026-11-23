package signup

import (
	"encoding/json"
	"errors"
	"fmt"
	"io"
	"strings"
)

// Request is the JSON body of a sign-up call.
type Request struct {
	Email string `json:"email"`
	Age   int    `json:"age"`
}

// FieldError names one invalid field and says why.
type FieldError struct {
	Field   string `json:"field"`
	Message string `json:"message"`
}

// Validate checks the rules and returns one FieldError per broken rule, in the order email, age.
// It returns nil when the request is valid.
//
//	email: required (after trimming spaces); must contain "@"
//	age:   must be between 13 and 120
//
// The exact messages are in signup_test.go.
func (r Request) Validate() []FieldError {
	var errs []FieldError
	email := strings.TrimSpace(r.Email)
	switch {
	case email == "":
		errs = append(errs, FieldError{Field: "email", Message: "is required"})
	case !strings.Contains(email, "@"):
		errs = append(errs, FieldError{Field: "email", Message: "must contain @"})
	}
	if r.Age < 13 || r.Age > 120 {
		errs = append(errs, FieldError{Field: "age", Message: "must be between 13 and 120"})
	}
	return errs
}

// Decode reads exactly one JSON object from body into a Request.
// It must fail for an empty body, an unknown field, a wrong type and trailing data after the object.
func Decode(body io.Reader) (Request, error) {
	dec := json.NewDecoder(io.LimitReader(body, 1<<20))
	dec.DisallowUnknownFields()
	var req Request
	if err := dec.Decode(&req); err != nil {
		return Request{}, fmt.Errorf("decode sign-up: %w", err)
	}
	if err := dec.Decode(&struct{}{}); !errors.Is(err, io.EOF) {
		return Request{}, errors.New("decode sign-up: body must contain a single JSON object")
	}
	return req, nil
}
