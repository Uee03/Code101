package httpapi

import (
	"net/http"

	"example.com/tasksteams/internal/problem"
	"example.com/tasksteams/internal/store"
)

type userDTO struct {
	ID          string `json:"id"`
	Username    string `json:"username"`
	DisplayName string `json:"displayName"`
}

func toUserDTO(u store.User) userDTO {
	return userDTO{ID: u.ID, Username: u.Username, DisplayName: u.DisplayName}
}

// listUsers lets any signed-in user find people, for example to add a team member. It exposes no e-mail addresses.
func (s *Server) listUsers(w http.ResponseWriter, r *http.Request) {
	page, p := pageParams(r)
	if p != nil {
		problem.Write(w, r, p)
		return
	}
	prefix, p := textParam(r, "q", 100)
	if p != nil {
		problem.Write(w, r, p)
		return
	}
	result, err := s.store.ListUsers(r.Context(), prefix, page)
	if err != nil {
		s.fail(w, r, err)
		return
	}
	writeJSON(w, r, http.StatusOK, toPage(result, page.Limit, toUserDTO))
}
