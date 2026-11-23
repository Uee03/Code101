package main

import (
	"encoding/json"
	"errors"
	"io"
	"mime"
	"net/http"
)

const maxBodyBytes = 1 << 20

// decodeJSON reads exactly one JSON object from the request body into dst.
// When the request is not acceptable it returns the Problem to send and false.
func decodeJSON(w http.ResponseWriter, r *http.Request, dst any) (Problem, bool) {
	mediaType, _, err := mime.ParseMediaType(r.Header.Get("Content-Type"))
	if err != nil || mediaType != "application/json" {
		return unsupportedMediaType("Content-Type must be application/json."), false
	}

	r.Body = http.MaxBytesReader(w, r.Body, maxBodyBytes)
	dec := json.NewDecoder(r.Body)
	dec.DisallowUnknownFields()
	if err := dec.Decode(dst); err != nil {
		return decodeProblem(err), false
	}
	// A second Decode must reach the end of the body; anything else is trailing data.
	if err := dec.Decode(&struct{}{}); !errors.Is(err, io.EOF) {
		return badRequest("Body must contain a single JSON object."), false
	}
	return Problem{}, true
}

// decodeProblem maps decoding errors to a client-safe message. It never echoes the raw error text.
func decodeProblem(err error) Problem {
	var syntaxErr *json.SyntaxError
	var typeErr *json.UnmarshalTypeError
	var tooBig *http.MaxBytesError
	switch {
	case errors.Is(err, io.EOF):
		return badRequest("Body must not be empty.")
	case errors.As(err, &syntaxErr), errors.Is(err, io.ErrUnexpectedEOF):
		return badRequest("Body is not valid JSON.")
	case errors.As(err, &typeErr):
		return badRequest("Field " + typeErr.Field + " has the wrong type.")
	case errors.As(err, &tooBig):
		return payloadTooLarge("Body must be at most 1 MiB.")
	default:
		return badRequest("Body does not match the expected fields.")
	}
}
