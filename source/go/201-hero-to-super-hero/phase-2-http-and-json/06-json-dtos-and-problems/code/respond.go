package main

import (
	"encoding/json"
	"log"
	"net/http"
)

const problemBase = "https://example.com/problems/"

// Problem is an RFC 9457 "problem details" object. The media type is application/problem+json.
type Problem struct {
	Type     string       `json:"type"`
	Title    string       `json:"title"`
	Status   int          `json:"status"`
	Detail   string       `json:"detail,omitempty"`
	Instance string       `json:"instance,omitempty"`
	Errors   []FieldError `json:"errors,omitempty"`
}

func badRequest(detail string) Problem {
	return Problem{Type: problemBase + "bad-request", Title: "Bad request", Status: http.StatusBadRequest, Detail: detail}
}

func notFound(detail string) Problem {
	return Problem{Type: problemBase + "not-found", Title: "Not found", Status: http.StatusNotFound, Detail: detail}
}

func unsupportedMediaType(detail string) Problem {
	return Problem{Type: problemBase + "unsupported-media-type", Title: "Unsupported media type", Status: http.StatusUnsupportedMediaType, Detail: detail}
}

func payloadTooLarge(detail string) Problem {
	return Problem{Type: problemBase + "payload-too-large", Title: "Payload too large", Status: http.StatusRequestEntityTooLarge, Detail: detail}
}

func validationFailed(errs []FieldError) Problem {
	return Problem{
		Type:   problemBase + "validation-error",
		Title:  "Validation failed",
		Status: http.StatusUnprocessableEntity,
		Detail: "One or more fields are invalid.",
		Errors: errs,
	}
}

// writeProblem sends p as application/problem+json. Instance says which request failed.
func writeProblem(w http.ResponseWriter, r *http.Request, p Problem) {
	p.Instance = r.URL.Path
	w.Header().Set("Content-Type", "application/problem+json")
	w.WriteHeader(p.Status)
	if err := json.NewEncoder(w).Encode(p); err != nil {
		log.Printf("write problem: %v", err)
	}
}

func writeJSON(w http.ResponseWriter, status int, v any) {
	w.Header().Set("Content-Type", "application/json")
	w.WriteHeader(status)
	if err := json.NewEncoder(w).Encode(v); err != nil {
		log.Printf("write response: %v", err)
	}
}
