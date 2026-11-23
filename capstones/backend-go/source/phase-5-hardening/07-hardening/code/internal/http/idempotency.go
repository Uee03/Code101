package httpapi

import (
	"bytes"
	"context"
	"crypto/sha256"
	"encoding/hex"
	"encoding/json"
	"io"
	"maps"
	"net/http"

	"example.com/tasksteams/internal/auth"
	"example.com/tasksteams/internal/problem"
)

// idempotentRoutes are the creates that honour the Idempotency-Key header. handle wraps exactly these.
var idempotentRoutes = map[string]bool{
	"POST /v1/teams":                      true,
	"POST /v1/teams/{teamId}/projects":    true,
	"POST /v1/projects/{projectId}/tasks": true,
	"POST /v1/tasks/{taskId}/comments":    true,
}

// recorder is a ResponseWriter that keeps the response in memory instead of sending it.
type recorder struct {
	header http.Header
	status int
	body   bytes.Buffer
}

func (r *recorder) Header() http.Header { return r.header }

func (r *recorder) WriteHeader(status int) {
	if r.status == 0 {
		r.status = status
	}
}

func (r *recorder) Write(b []byte) (int, error) {
	if r.status == 0 {
		r.status = http.StatusOK
	}
	return r.body.Write(b)
}

// storedResponse is the envelope saved in idempotency_keys.response_body. The status is in its own column.
type storedResponse struct {
	Location string          `json:"location,omitempty"`
	ETag     string          `json:"etag,omitempty"`
	Body     json.RawMessage `json:"body"`
}

// idempotent makes a create safe to retry. The first request with a key runs normally and its response is stored.
// A repeat with the same key and the same body gets the stored response and Idempotent-Replayed: true.
// The same key with another body is a 422; the same key while the first request still runs is a 409.
func (s *Server) idempotent(next http.HandlerFunc) http.HandlerFunc {
	return func(w http.ResponseWriter, r *http.Request) {
		key := r.Header.Get("Idempotency-Key")
		if key == "" {
			next(w, r)
			return
		}
		if len(key) < 8 || len(key) > 128 {
			problem.Write(w, r, problem.BadRequest("Idempotency-Key must be 8 to 128 characters."))
			return
		}
		body, err := io.ReadAll(r.Body) // already limited by the bodyLimit middleware
		if err != nil {
			problem.Write(w, r, bodyReadProblem(err))
			return
		}
		r.Body = io.NopCloser(bytes.NewReader(body)) // the handler reads the body again
		userID := auth.FromContext(r.Context()).ID
		sum := sha256.Sum256(append([]byte(r.Method+" "+r.URL.Path+"\n"), body...))
		hash := hex.EncodeToString(sum[:])

		claimed, existing, err := s.store.ClaimKey(r.Context(), userID, key, hash)
		if err != nil {
			s.fail(w, r, err)
			return
		}
		if !claimed {
			s.answerFromRecord(w, r, existing.RequestHash == hash, existing.StatusCode, existing.Response)
			return
		}

		finished := false
		defer func() {
			if !finished { // a panic or a store error: let the client try again
				_ = s.store.ReleaseKey(context.WithoutCancel(r.Context()), userID, key)
			}
		}()
		rec := &recorder{header: http.Header{}}
		next(rec, r)
		if rec.status >= 200 && rec.status < 300 {
			envelope, _ := json.Marshal(storedResponse{Location: rec.header.Get("Location"), ETag: rec.header.Get("ETag"), Body: rec.body.Bytes()})
			if err := s.store.FinishKey(context.WithoutCancel(r.Context()), userID, key, rec.status, envelope); err != nil {
				s.logger.Error("store idempotency response", "error", err, "trace_id", problem.TraceID(r.Context()))
			} else {
				finished = true
			}
		} else {
			_ = s.store.ReleaseKey(context.WithoutCancel(r.Context()), userID, key)
			finished = true // failures are not remembered: the client may fix the request and reuse the key
		}
		maps.Copy(w.Header(), rec.header)
		w.WriteHeader(rec.status)
		_, _ = w.Write(rec.body.Bytes())
	}
}

// answerFromRecord answers a request that did not claim the key.
func (s *Server) answerFromRecord(w http.ResponseWriter, r *http.Request, sameRequest bool, status *int, response []byte) {
	switch {
	case !sameRequest:
		problem.Write(w, r, problem.Validation("The Idempotency-Key was already used with a different request."))
	case status == nil:
		problem.Write(w, r, problem.Conflict("A request with this Idempotency-Key is still in progress."))
	default:
		var stored storedResponse
		if err := json.Unmarshal(response, &stored); err != nil {
			s.logger.Error("read stored idempotency response", "error", err, "trace_id", problem.TraceID(r.Context()))
			problem.Write(w, r, problem.Internal())
			return
		}
		w.Header().Set("Content-Type", "application/json")
		w.Header().Set("Idempotent-Replayed", "true")
		if stored.Location != "" {
			w.Header().Set("Location", stored.Location)
		}
		if stored.ETag != "" {
			w.Header().Set("ETag", stored.ETag)
		}
		w.WriteHeader(*status)
		_, _ = w.Write(stored.Body)
	}
}
