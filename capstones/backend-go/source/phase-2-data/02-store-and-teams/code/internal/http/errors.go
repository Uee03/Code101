package httpapi

import (
	"errors"
	"net/http"

	"example.com/tasksteams/internal/problem"
	"example.com/tasksteams/internal/store"
)

// storeProblem maps a store error to the problem it stands for. Errors the store does not know become a
// 500 whose body says nothing about the cause; the cause goes to the log with the trace id.
func (s *Server) storeProblem(r *http.Request, err error) *problem.Problem {
	var se *store.Error
	if !errors.As(err, &se) {
		s.logger.Error("request failed", "error", err, "trace_id", problem.TraceID(r.Context()))
		return problem.Internal()
	}
	var p *problem.Problem
	switch se.Kind {
	case store.KindNotFound:
		p = problem.NotFound(se.Message)
	case store.KindConflict:
		p = problem.Conflict(se.Message)
	case store.KindStale:
		p = problem.PreconditionFailed(se.Message)
	case store.KindInvalid:
		p = problem.Validation(se.Message)
	case store.KindBadCursor:
		p = problem.BadRequest(se.Message)
	default:
		return problem.Internal()
	}
	if se.Code != "" {
		p.WithCode(se.Code)
	}
	return p
}

// fail writes the problem for a store error.
func (s *Server) fail(w http.ResponseWriter, r *http.Request, err error) {
	problem.Write(w, r, s.storeProblem(r, err))
}
