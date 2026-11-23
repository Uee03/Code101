package httpapi

import (
	"net/http"
	"time"

	"example.com/tasksteams/internal/auth"
	"example.com/tasksteams/internal/problem"
	"example.com/tasksteams/internal/store"
)

// teamDTO is the response body for a team (schema Team in the contract). It is not the store's Team:
// the names are the contract's, and the store type can change without changing the API.
type teamDTO struct {
	ID          string    `json:"id"`
	Name        string    `json:"name"`
	Description string    `json:"description"`
	MemberCount int       `json:"memberCount"`
	CreatedBy   string    `json:"createdBy"`
	Version     int       `json:"version"`
	CreatedAt   time.Time `json:"createdAt"`
	UpdatedAt   time.Time `json:"updatedAt"`
}

func toTeamDTO(t store.Team) teamDTO {
	return teamDTO{
		ID: t.ID, Name: t.Name, Description: t.Description, MemberCount: t.MemberCount, CreatedBy: t.CreatedBy,
		Version: t.Version, CreatedAt: t.CreatedAt.UTC(), UpdatedAt: t.UpdatedAt.UTC(),
	}
}

// teamCreateDTO is the request body of POST /v1/teams (schema TeamCreate).
type teamCreateDTO struct {
	Name        string `json:"name"`
	Description string `json:"description"`
	LeadUserID  string `json:"leadUserId"`
}

func (d *teamCreateDTO) validate() *problem.Problem {
	var v validator
	d.Name = v.text("/name", d.Name, 1, 80)
	d.Description = v.text("/description", d.Description, 0, 500)
	if d.LeadUserID != "" {
		v.uuid("/leadUserId", d.LeadUserID)
	}
	return v.result()
}

// teamUpdateDTO is a JSON Merge Patch: a field that is absent stays as it is.
type teamUpdateDTO struct {
	Name        *string `json:"name"`
	Description *string `json:"description"`
}

func (d *teamUpdateDTO) validate() *problem.Problem {
	var v validator
	if d.Name == nil && d.Description == nil {
		v.add("", "send at least one field to change")
	}
	if d.Name != nil {
		*d.Name = v.text("/name", *d.Name, 1, 80)
	}
	if d.Description != nil {
		*d.Description = v.text("/description", *d.Description, 0, 500)
	}
	return v.result()
}

func (s *Server) registerTeams(mux *http.ServeMux) {
	s.handle(mux, "GET /v1/teams", auth.ScopeRead, s.listTeams)
	s.handle(mux, "POST /v1/teams", auth.ScopeWrite, s.createTeam)
	s.handle(mux, "GET /v1/teams/{teamId}", auth.ScopeRead, s.getTeam)
	s.handle(mux, "PATCH /v1/teams/{teamId}", auth.ScopeWrite, s.updateTeam)
	s.handle(mux, "DELETE /v1/teams/{teamId}", auth.ScopeAdmin, s.deleteTeam)
}

func (s *Server) listTeams(w http.ResponseWriter, r *http.Request) {
	principal := auth.FromContext(r.Context())
	page, p := pageParams(r)
	if p != nil {
		problem.Write(w, r, p)
		return
	}
	sort, p := sortParam(r, "-createdAt", "createdAt")
	if p != nil {
		problem.Write(w, r, p)
		return
	}
	prefix, p := textParam(r, "q", 100)
	if p != nil {
		problem.Write(w, r, p)
		return
	}
	result, err := s.store.ListTeams(r.Context(), store.TeamFilter{
		UserID: principal.ID, All: principal.IsAdmin(), Prefix: prefix, Desc: sort == "-createdAt", Page: page,
	})
	if err != nil {
		s.fail(w, r, err)
		return
	}
	writeJSON(w, r, http.StatusOK, toPage(result, page.Limit, toTeamDTO))
}

func (s *Server) createTeam(w http.ResponseWriter, r *http.Request) {
	principal, ok := requireAdmin(w, r)
	if !ok {
		return
	}
	var dto teamCreateDTO
	if p := decodeJSON(r, &dto); p != nil {
		problem.Write(w, r, p)
		return
	}
	if p := dto.validate(); p != nil {
		problem.Write(w, r, p)
		return
	}
	lead := dto.LeadUserID
	if lead == "" {
		lead = principal.ID
	}
	team, err := s.store.CreateTeam(r.Context(), principal.ID, lead, dto.Name, dto.Description)
	if err != nil {
		s.fail(w, r, err)
		return
	}
	w.Header().Set("Location", s.publicURL+"/v1/teams/"+team.ID)
	respondEntity(w, r, http.StatusCreated, team.Version, toTeamDTO(team))
}

func (s *Server) getTeam(w http.ResponseWriter, r *http.Request) {
	id, ok := pathID(w, r, "teamId")
	if !ok || !s.authorize(w, r, id, levelMember, "team") {
		return
	}
	team, err := s.store.GetTeam(r.Context(), id)
	if err != nil {
		s.fail(w, r, err)
		return
	}
	respondEntity(w, r, http.StatusOK, team.Version, toTeamDTO(team))
}

func (s *Server) updateTeam(w http.ResponseWriter, r *http.Request) {
	id, ok := pathID(w, r, "teamId")
	if !ok || !s.authorize(w, r, id, levelLead, "team") {
		return
	}
	expected, p := ifMatch(r, true)
	if p != nil {
		problem.Write(w, r, p)
		return
	}
	var dto teamUpdateDTO
	if p := decodeJSON(r, &dto); p != nil {
		problem.Write(w, r, p)
		return
	}
	if p := dto.validate(); p != nil {
		problem.Write(w, r, p)
		return
	}
	team, err := s.store.UpdateTeam(r.Context(), auth.FromContext(r.Context()).ID, id, expected,
		store.TeamPatch{Name: dto.Name, Description: dto.Description})
	if err != nil {
		s.fail(w, r, err)
		return
	}
	respondEntity(w, r, http.StatusOK, team.Version, toTeamDTO(team))
}

func (s *Server) deleteTeam(w http.ResponseWriter, r *http.Request) {
	principal, ok := requireAdmin(w, r)
	if !ok {
		return
	}
	id, ok := pathID(w, r, "teamId")
	if !ok {
		return
	}
	if err := s.store.DeleteTeam(r.Context(), principal.ID, id); err != nil {
		s.fail(w, r, err)
		return
	}
	w.WriteHeader(http.StatusNoContent)
}
