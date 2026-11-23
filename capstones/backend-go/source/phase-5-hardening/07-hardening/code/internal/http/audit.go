package httpapi

import (
	"encoding/json"
	"net/http"
	"slices"
	"time"

	"example.com/tasksteams/internal/auth"
	"example.com/tasksteams/internal/problem"
	"example.com/tasksteams/internal/store"
)

type auditDTO struct {
	ID         int64           `json:"id"`
	OccurredAt time.Time       `json:"occurredAt"`
	ActorID    *string         `json:"actorId"`
	Action     string          `json:"action"`
	EntityType string          `json:"entityType"`
	EntityID   string          `json:"entityId"`
	Details    json.RawMessage `json:"details"`
}

func toAuditDTO(e store.AuditEntry) auditDTO {
	return auditDTO{
		ID: e.ID, OccurredAt: e.OccurredAt.UTC(), ActorID: e.ActorID, Action: e.Action, EntityType: e.EntityType,
		EntityID: e.EntityID, Details: json.RawMessage(e.Details),
	}
}

func (s *Server) registerAudit(mux *http.ServeMux) {
	s.handle(mux, "GET /v1/audit-log", auth.ScopeAdmin, s.listAudit)
}

// queryUUID reads an optional UUID parameter.
func queryUUID(r *http.Request, name string) (string, *problem.Problem) {
	value := r.URL.Query().Get(name)
	if value != "" && !isUUID(value) {
		return "", problem.BadRequest(name + " must be a UUID.")
	}
	return value, nil
}

// queryTime reads an optional RFC 3339 timestamp parameter.
func queryTime(r *http.Request, name string) (*time.Time, *problem.Problem) {
	raw := r.URL.Query().Get(name)
	if raw == "" {
		return nil, nil
	}
	instant, err := time.Parse(time.RFC3339, raw)
	if err != nil {
		return nil, problem.BadRequest(name + " must be a timestamp such as 2027-06-30T12:00:00Z.")
	}
	return &instant, nil
}

// listAudit is for admins only: both the realm role and the tasks:admin scope are required.
func (s *Server) listAudit(w http.ResponseWriter, r *http.Request) {
	if _, ok := requireAdmin(w, r); !ok {
		return
	}
	var f store.AuditFilter
	var p *problem.Problem
	if f.Page, p = pageParams(r); p != nil {
		problem.Write(w, r, p)
		return
	}
	if f.EntityType = r.URL.Query().Get("entityType"); f.EntityType != "" &&
		!slices.Contains([]string{"team", "member", "project", "task", "comment"}, f.EntityType) {
		problem.Write(w, r, problem.BadRequest("entityType must be one of: team, member, project, task, comment."))
		return
	}
	if f.EntityID, p = queryUUID(r, "entityId"); p != nil {
		problem.Write(w, r, p)
		return
	}
	if f.ActorID, p = queryUUID(r, "actorId"); p != nil {
		problem.Write(w, r, p)
		return
	}
	if f.From, p = queryTime(r, "from"); p != nil {
		problem.Write(w, r, p)
		return
	}
	if f.To, p = queryTime(r, "to"); p != nil {
		problem.Write(w, r, p)
		return
	}
	result, err := s.store.ListAudit(r.Context(), f)
	if err != nil {
		s.fail(w, r, err)
		return
	}
	writeJSON(w, r, http.StatusOK, toPage(result, f.Page.Limit, toAuditDTO))
}
