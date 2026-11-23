// Package problem implements RFC 9457 problem details: the one error format of the API.
package problem

import (
	"context"
	"encoding/json"
	"log/slog"
	"net/http"
)

// BaseType is the prefix of every problem type URI; the contract fixes it.
const BaseType = "https://code101.example/problems/"

// FieldError points at one invalid field of a request body with a JSON Pointer (RFC 6901).
type FieldError struct {
	Pointer string `json:"pointer"`
	Detail  string `json:"detail"`
}

// Problem is the response body and also an error value, so a handler can return it.
type Problem struct {
	Type     string       `json:"type"`
	Title    string       `json:"title"`
	Status   int          `json:"status"`
	Detail   string       `json:"detail,omitempty"`
	Instance string       `json:"instance,omitempty"`
	TraceID  string       `json:"traceId,omitempty"`
	Code     string       `json:"code,omitempty"`
	Errors   []FieldError `json:"errors,omitempty"`
	Header   http.Header  `json:"-"` // extra response headers such as WWW-Authenticate or Retry-After
}

func (p *Problem) Error() string { return p.Title + ": " + p.Detail }

// New builds a problem whose type is BaseType plus the slug.
func New(status int, slug, title, detail string) *Problem {
	return &Problem{Type: BaseType + slug, Title: title, Status: status, Detail: detail}
}

// WithCode adds the optional machine-readable code, for example "last_lead".
func (p *Problem) WithCode(code string) *Problem {
	p.Code = code
	return p
}

// WithHeader adds a response header and returns the problem for chaining.
func (p *Problem) WithHeader(key, value string) *Problem {
	if p.Header == nil {
		p.Header = http.Header{}
	}
	p.Header.Set(key, value)
	return p
}

func BadRequest(detail string) *Problem {
	return New(http.StatusBadRequest, "bad-request", "Bad request", detail)
}

func Unauthorized(detail string) *Problem {
	return New(http.StatusUnauthorized, "unauthorized", "Unauthorized", detail).
		WithHeader("WWW-Authenticate", `Bearer realm="tasksteams"`)
}

func Forbidden(detail string) *Problem {
	return New(http.StatusForbidden, "forbidden", "Forbidden", detail)
}

func NotFound(detail string) *Problem {
	return New(http.StatusNotFound, "not-found", "Not found", detail)
}

func Conflict(detail string) *Problem {
	return New(http.StatusConflict, "conflict", "Conflict", detail)
}

func PreconditionFailed(detail string) *Problem {
	return New(http.StatusPreconditionFailed, "precondition-failed", "Precondition failed", detail)
}

func PreconditionRequired(detail string) *Problem {
	return New(http.StatusPreconditionRequired, "precondition-required", "Precondition required", detail)
}

func Validation(detail string, errs ...FieldError) *Problem {
	p := New(http.StatusUnprocessableEntity, "validation-error", "Validation failed", detail)
	p.Errors = errs
	return p
}

func Internal() *Problem {
	return New(http.StatusInternalServerError, "internal-error", "Internal server error", "The server failed to handle the request.")
}

type traceKey struct{}

// WithTraceID stores the request's trace id so Write can put it in the body.
func WithTraceID(ctx context.Context, id string) context.Context {
	return context.WithValue(ctx, traceKey{}, id)
}

// TraceID returns the trace id stored by WithTraceID, or an empty string.
func TraceID(ctx context.Context) string {
	id, _ := ctx.Value(traceKey{}).(string)
	return id
}

// Write sends the problem as application/problem+json. The instance is the request path.
func Write(w http.ResponseWriter, r *http.Request, p *Problem) {
	body := *p // a copy: the same *Problem value may be shared by several requests
	body.Instance = r.URL.Path
	body.TraceID = TraceID(r.Context())
	for key, values := range p.Header {
		for _, value := range values {
			w.Header().Add(key, value)
		}
	}
	payload, err := json.Marshal(body)
	if err != nil {
		slog.Error("encode problem", "error", err)
		http.Error(w, "internal error", http.StatusInternalServerError)
		return
	}
	w.Header().Set("Content-Type", "application/problem+json")
	w.WriteHeader(p.Status)
	if _, err := w.Write(payload); err != nil {
		slog.Debug("write problem", "error", err)
	}
}
