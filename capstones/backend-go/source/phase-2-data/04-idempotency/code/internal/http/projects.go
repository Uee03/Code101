package httpapi

import (
	"net/http"
	"regexp"
	"time"

	"example.com/tasksteams/internal/auth"
	"example.com/tasksteams/internal/problem"
	"example.com/tasksteams/internal/store"
)

var projectKeyPattern = regexp.MustCompile(`^[A-Z][A-Z0-9]{1,9}$`)

type projectDTO struct {
	ID          string    `json:"id"`
	TeamID      string    `json:"teamId"`
	Key         string    `json:"key"`
	Name        string    `json:"name"`
	Description string    `json:"description"`
	Archived    bool      `json:"archived"`
	Version     int       `json:"version"`
	CreatedAt   time.Time `json:"createdAt"`
	UpdatedAt   time.Time `json:"updatedAt"`
}

func toProjectDTO(p store.Project) projectDTO {
	return projectDTO{
		ID: p.ID, TeamID: p.TeamID, Key: p.Key, Name: p.Name, Description: p.Description, Archived: p.Archived,
		Version: p.Version, CreatedAt: p.CreatedAt.UTC(), UpdatedAt: p.UpdatedAt.UTC(),
	}
}

type projectCreateDTO struct {
	Key         string `json:"key"`
	Name        string `json:"name"`
	Description string `json:"description"`
}

func (d *projectCreateDTO) validate() *problem.Problem {
	var v validator
	v.matches("/key", d.Key, projectKeyPattern, "must be 2 to 10 characters: a capital letter, then capital letters or digits")
	d.Name = v.text("/name", d.Name, 1, 120)
	d.Description = v.text("/description", d.Description, 0, 2000)
	return v.result()
}

type projectUpdateDTO struct {
	Name        *string `json:"name"`
	Description *string `json:"description"`
	Archived    *bool   `json:"archived"`
}

func (d *projectUpdateDTO) validate() *problem.Problem {
	var v validator
	if d.Name == nil && d.Description == nil && d.Archived == nil {
		v.add("", "send at least one field to change")
	}
	if d.Name != nil {
		*d.Name = v.text("/name", *d.Name, 1, 120)
	}
	if d.Description != nil {
		*d.Description = v.text("/description", *d.Description, 0, 2000)
	}
	return v.result()
}

func (s *Server) registerProjects(mux *http.ServeMux) {
	s.handle(mux, "GET /v1/teams/{teamId}/projects", auth.ScopeRead, s.listProjects)
	s.handle(mux, "POST /v1/teams/{teamId}/projects", auth.ScopeWrite, s.createProject)
	s.handle(mux, "GET /v1/projects/{projectId}", auth.ScopeRead, s.getProject)
	s.handle(mux, "PATCH /v1/projects/{projectId}", auth.ScopeWrite, s.updateProject)
	s.handle(mux, "DELETE /v1/projects/{projectId}", auth.ScopeWrite, s.deleteProject)
}

func (s *Server) listProjects(w http.ResponseWriter, r *http.Request) {
	teamID, ok := pathID(w, r, "teamId")
	if !ok || !s.authorize(w, r, teamID, levelMember, "team") {
		return
	}
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
	archived := r.URL.Query().Get("archived")
	if archived != "" && archived != "true" && archived != "false" {
		problem.Write(w, r, problem.BadRequest("archived must be true or false."))
		return
	}
	// archived=true includes archived projects next to the active ones; the default hides them.
	result, err := s.store.ListProjects(r.Context(), teamID, archived == "true", sort == "-createdAt", page)
	if err != nil {
		s.fail(w, r, err)
		return
	}
	writeJSON(w, r, http.StatusOK, toPage(result, page.Limit, toProjectDTO))
}

func (s *Server) createProject(w http.ResponseWriter, r *http.Request) {
	teamID, ok := pathID(w, r, "teamId")
	if !ok || !s.authorize(w, r, teamID, levelLead, "team") {
		return
	}
	var dto projectCreateDTO
	if p := decodeJSON(r, &dto); p != nil {
		problem.Write(w, r, p)
		return
	}
	if p := dto.validate(); p != nil {
		problem.Write(w, r, p)
		return
	}
	project, err := s.store.CreateProject(r.Context(), auth.FromContext(r.Context()).ID, teamID, dto.Key, dto.Name, dto.Description)
	if err != nil {
		s.fail(w, r, err)
		return
	}
	w.Header().Set("Location", s.publicURL+"/v1/projects/"+project.ID)
	respondEntity(w, r, http.StatusCreated, project.Version, toProjectDTO(project))
}

// projectTeam finds the team of the project in the URL and checks that the caller may act on it.
func (s *Server) projectTeam(w http.ResponseWriter, r *http.Request, need teamLevel) (projectID string, ok bool) {
	projectID, ok = pathID(w, r, "projectId")
	if !ok {
		return "", false
	}
	teamID, err := s.store.TeamOfProject(r.Context(), projectID)
	if err != nil {
		s.fail(w, r, err)
		return "", false
	}
	return projectID, s.authorize(w, r, teamID, need, "project")
}

func (s *Server) getProject(w http.ResponseWriter, r *http.Request) {
	id, ok := s.projectTeam(w, r, levelMember)
	if !ok {
		return
	}
	project, err := s.store.GetProject(r.Context(), id)
	if err != nil {
		s.fail(w, r, err)
		return
	}
	respondEntity(w, r, http.StatusOK, project.Version, toProjectDTO(project))
}

func (s *Server) updateProject(w http.ResponseWriter, r *http.Request) {
	id, ok := s.projectTeam(w, r, levelLead)
	if !ok {
		return
	}
	expected, p := ifMatch(r, true)
	if p != nil {
		problem.Write(w, r, p)
		return
	}
	var dto projectUpdateDTO
	if p := decodeJSON(r, &dto); p != nil {
		problem.Write(w, r, p)
		return
	}
	if p := dto.validate(); p != nil {
		problem.Write(w, r, p)
		return
	}
	project, err := s.store.UpdateProject(r.Context(), auth.FromContext(r.Context()).ID, id, expected,
		store.ProjectPatch{Name: dto.Name, Description: dto.Description, Archived: dto.Archived})
	if err != nil {
		s.fail(w, r, err)
		return
	}
	respondEntity(w, r, http.StatusOK, project.Version, toProjectDTO(project))
}

func (s *Server) deleteProject(w http.ResponseWriter, r *http.Request) {
	id, ok := s.projectTeam(w, r, levelLead)
	if !ok {
		return
	}
	if err := s.store.DeleteProject(r.Context(), auth.FromContext(r.Context()).ID, id); err != nil {
		s.fail(w, r, err)
		return
	}
	w.WriteHeader(http.StatusNoContent)
}
