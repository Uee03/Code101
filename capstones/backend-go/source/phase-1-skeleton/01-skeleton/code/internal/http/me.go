package httpapi

import "net/http"

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

// me is a stub: it always answers as the seed user alice. Chapters 02 and 05 replace it with the real caller.
func (s *Server) me(w http.ResponseWriter, r *http.Request) {
	writeJSON(w, r, http.StatusOK, meDTO{
		ID:          "a11ce000-0000-4000-8000-000000000001",
		Username:    "alice",
		Email:       "alice@tasksteams.test",
		DisplayName: "Alice Admin",
		Roles:       []string{"admin"},
		Scopes:      []string{"tasks:read", "tasks:write", "tasks:admin"},
		Teams:       []meTeamDTO{}, // an empty slice encodes as [], a nil slice would encode as null
	})
}
