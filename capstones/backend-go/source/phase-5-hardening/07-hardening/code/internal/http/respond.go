package httpapi

import (
	"encoding/json"
	"errors"
	"io"
	"log/slog"
	"mime"
	"net/http"
	"reflect"
	"strings"

	"example.com/tasksteams/internal/problem"
)

// writeJSON encodes body and sends it with the given status.
func writeJSON(w http.ResponseWriter, r *http.Request, status int, body any) {
	payload, err := json.Marshal(body)
	if err != nil {
		slog.Error("encode response", "error", err)
		problem.Write(w, r, problem.Internal())
		return
	}
	w.Header().Set("Content-Type", "application/json")
	w.WriteHeader(status)
	if _, err := w.Write(payload); err != nil {
		slog.Debug("write response", "error", err)
	}
}

// decodeJSON reads exactly one JSON object from the body into dst. It rejects unknown fields,
// wrong types and trailing data, and returns the matching problem instead of an error.
func decodeJSON(r *http.Request, dst any) *problem.Problem {
	mediaType, _, err := mime.ParseMediaType(r.Header.Get("Content-Type"))
	if err != nil || (mediaType != "application/json" && mediaType != "application/merge-patch+json") {
		return problem.BadRequest("Content-Type must be application/json.")
	}
	decoder := json.NewDecoder(r.Body)
	decoder.DisallowUnknownFields()
	if err := decoder.Decode(dst); err != nil {
		return decodeProblem(err)
	}
	if _, err := decoder.Token(); !errors.Is(err, io.EOF) {
		return problem.BadRequest("The body must contain exactly one JSON value.")
	}
	return nil
}

// decodeProblem turns an encoding/json error into a 413 (too large), 400 (not JSON) or 422 (JSON, wrong shape).
func decodeProblem(err error) *problem.Problem {
	var tooLarge *http.MaxBytesError
	var syntaxErr *json.SyntaxError
	var typeErr *json.UnmarshalTypeError
	switch {
	case errors.As(err, &tooLarge):
		return payloadTooLarge(tooLarge.Limit)
	case errors.As(err, &typeErr):
		return problem.Validation("One or more fields are invalid.", problem.FieldError{
			Pointer: "/" + strings.ReplaceAll(typeErr.Field, ".", "/"),
			Detail:  "must be of type " + jsonType(typeErr.Type),
		})
	case errors.As(err, &syntaxErr), errors.Is(err, io.EOF), errors.Is(err, io.ErrUnexpectedEOF):
		return problem.BadRequest("The request body is not valid JSON.")
	}
	if field, ok := strings.CutPrefix(err.Error(), "json: unknown field "); ok {
		return problem.Validation("One or more fields are invalid.", problem.FieldError{
			Pointer: "/" + strings.Trim(field, `"`),
			Detail:  "is not a known field",
		})
	}
	return problem.BadRequest("The request body could not be read.")
}

func jsonType(t reflect.Type) string {
	switch t.Kind() {
	case reflect.String:
		return "string"
	case reflect.Bool:
		return "boolean"
	case reflect.Slice, reflect.Array:
		return "array"
	case reflect.Struct, reflect.Map:
		return "object"
	default:
		return "number"
	}
}
