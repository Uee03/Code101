package httpapi

import (
	"net/http"

	"example.com/tasksteams/internal/problem"
)

// teamCreateDTO is the request body of POST /v1/teams (schema TeamCreate in the contract).
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

// createTeam validates the request. Storing the team needs the database, which arrives in chapter 02.
func (s *Server) createTeam(w http.ResponseWriter, r *http.Request) {
	var dto teamCreateDTO
	if p := decodeJSON(r, &dto); p != nil {
		problem.Write(w, r, p)
		return
	}
	if p := dto.validate(); p != nil {
		problem.Write(w, r, p)
		return
	}
	problem.Write(w, r, problem.New(http.StatusNotImplemented, "not-implemented", "Not implemented",
		"The request is valid, but teams are stored from chapter 02 on."))
}
