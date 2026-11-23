package httpapi

import (
	"net/http"
	"time"

	"example.com/tasksteams/internal/auth"
	"example.com/tasksteams/internal/problem"
	"example.com/tasksteams/internal/store"
)

type memberDTO struct {
	UserID      string    `json:"userId"`
	Username    string    `json:"username"`
	DisplayName string    `json:"displayName"`
	Role        string    `json:"role"`
	JoinedAt    time.Time `json:"joinedAt"`
}

func toMemberDTO(m store.Member) memberDTO {
	return memberDTO{UserID: m.UserID, Username: m.Username, DisplayName: m.DisplayName, Role: m.Role, JoinedAt: m.JoinedAt.UTC()}
}

type memberPutDTO struct {
	Role string `json:"role"`
}

func (d *memberPutDTO) validate() *problem.Problem {
	var v validator
	v.oneOf("/role", d.Role, "lead", "member")
	return v.result()
}

func (s *Server) registerMembers(mux *http.ServeMux) {
	s.handle(mux, "GET /v1/teams/{teamId}/members", auth.ScopeRead, s.listMembers)
	s.handle(mux, "PUT /v1/teams/{teamId}/members/{userId}", auth.ScopeWrite, s.putMember)
	s.handle(mux, "DELETE /v1/teams/{teamId}/members/{userId}", auth.ScopeWrite, s.removeMember)
}

func (s *Server) listMembers(w http.ResponseWriter, r *http.Request) {
	teamID, ok := pathID(w, r, "teamId")
	if !ok || !s.authorize(w, r, teamID, levelMember, "team") {
		return
	}
	page, p := pageParams(r)
	if p != nil {
		problem.Write(w, r, p)
		return
	}
	result, err := s.store.ListMembers(r.Context(), teamID, page)
	if err != nil {
		s.fail(w, r, err)
		return
	}
	writeJSON(w, r, http.StatusOK, toPage(result, page.Limit, toMemberDTO))
}

func (s *Server) putMember(w http.ResponseWriter, r *http.Request) {
	teamID, ok := pathID(w, r, "teamId")
	if !ok || !s.authorize(w, r, teamID, levelLead, "team") {
		return
	}
	userID, ok := pathID(w, r, "userId")
	if !ok {
		return
	}
	var dto memberPutDTO
	if p := decodeJSON(r, &dto); p != nil {
		problem.Write(w, r, p)
		return
	}
	if p := dto.validate(); p != nil {
		problem.Write(w, r, p)
		return
	}
	member, created, err := s.store.PutMember(r.Context(), auth.FromContext(r.Context()).ID, teamID, userID, dto.Role)
	if err != nil {
		s.fail(w, r, err)
		return
	}
	status := http.StatusOK
	if created {
		status = http.StatusCreated
	}
	writeJSON(w, r, status, toMemberDTO(member))
}

func (s *Server) removeMember(w http.ResponseWriter, r *http.Request) {
	teamID, ok := pathID(w, r, "teamId")
	if !ok || !s.authorize(w, r, teamID, levelLead, "team") {
		return
	}
	userID, ok := pathID(w, r, "userId")
	if !ok {
		return
	}
	if err := s.store.RemoveMember(r.Context(), auth.FromContext(r.Context()).ID, teamID, userID); err != nil {
		s.fail(w, r, err)
		return
	}
	w.WriteHeader(http.StatusNoContent)
}
