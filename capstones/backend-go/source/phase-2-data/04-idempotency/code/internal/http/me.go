package httpapi

import (
	"net/http"
	"slices"

	"example.com/tasksteams/internal/auth"
)

type meTeamDTO struct {
	TeamID string `json:"teamId"`
	Name   string `json:"name"`
	Role   string `json:"role"`
}

type meDTO struct {
	ID          string      `json:"id"`
	Username    string      `json:"username"`
	Email       string      `json:"email"`
	DisplayName string      `json:"displayName"`
	Roles       []string    `json:"roles"`
	Scopes      []string    `json:"scopes"`
	Teams       []meTeamDTO `json:"teams"`
}

// me describes the caller: the profile comes from the users table, roles and scopes from the credentials.
func (s *Server) me(w http.ResponseWriter, r *http.Request) {
	principal := auth.FromContext(r.Context())
	user, err := s.store.GetUser(r.Context(), principal.ID)
	if err != nil {
		s.fail(w, r, err)
		return
	}
	teams, err := s.store.UserTeams(r.Context(), principal.ID)
	if err != nil {
		s.fail(w, r, err)
		return
	}
	dto := meDTO{
		ID:          user.ID,
		Username:    user.Username,
		Email:       user.Email,
		DisplayName: user.DisplayName,
		Roles:       []string{}, // never null in JSON
		Scopes:      slices.Clone(principal.Scopes),
		Teams:       make([]meTeamDTO, 0, len(teams)),
	}
	for _, role := range []string{auth.RoleAdmin, auth.RoleMember} { // only the roles the contract knows, in a fixed order
		if principal.HasRole(role) {
			dto.Roles = append(dto.Roles, role)
		}
	}
	for _, t := range teams {
		dto.Teams = append(dto.Teams, meTeamDTO{TeamID: t.TeamID, Name: t.Name, Role: t.Role})
	}
	writeJSON(w, r, http.StatusOK, dto)
}
