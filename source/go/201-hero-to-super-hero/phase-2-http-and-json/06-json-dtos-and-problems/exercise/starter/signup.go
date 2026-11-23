package signup

import "io"

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
	// TODO 1: apply the rules.
	return nil
}

// Decode reads exactly one JSON object from body into a Request.
// It must fail for an empty body, an unknown field, a wrong type and trailing data after the object.
func Decode(body io.Reader) (Request, error) {
	// TODO 2: decode strictly and return a wrapped error on failure.
	return Request{}, nil
}
