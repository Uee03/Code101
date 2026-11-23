package httpapi

import (
	"net/http"
	"slices"
	"strings"
	"time"

	"example.com/tasksteams/internal/auth"
	"example.com/tasksteams/internal/problem"
	"example.com/tasksteams/internal/store"
)

var (
	taskStatuses   = []string{"todo", "in_progress", "blocked", "done", "cancelled"}
	taskPriorities = []string{"low", "medium", "high", "urgent"}
)

type taskDTO struct {
	ID          string     `json:"id"`
	ProjectID   string     `json:"projectId"`
	Title       string     `json:"title"`
	Description string     `json:"description"`
	Status      string     `json:"status"`
	Priority    string     `json:"priority"`
	AssigneeID  *string    `json:"assigneeId"`
	DueDate     *string    `json:"dueDate"`
	CompletedAt *time.Time `json:"completedAt"`
	CreatedBy   string     `json:"createdBy"`
	Version     int        `json:"version"`
	CreatedAt   time.Time  `json:"createdAt"`
	UpdatedAt   time.Time  `json:"updatedAt"`
}

func toTaskDTO(t store.Task) taskDTO {
	dto := taskDTO{
		ID: t.ID, ProjectID: t.ProjectID, Title: t.Title, Description: t.Description, Status: t.Status,
		Priority: t.Priority, AssigneeID: t.AssigneeID, CreatedBy: t.CreatedBy, Version: t.Version,
		CreatedAt: t.CreatedAt.UTC(), UpdatedAt: t.UpdatedAt.UTC(),
	}
	if t.DueDate != nil {
		due := t.DueDate.Format(time.DateOnly)
		dto.DueDate = &due
	}
	if t.CompletedAt != nil {
		done := t.CompletedAt.UTC()
		dto.CompletedAt = &done
	}
	return dto
}

type taskCreateDTO struct {
	Title       string  `json:"title"`
	Description string  `json:"description"`
	Priority    string  `json:"priority"`
	AssigneeID  *string `json:"assigneeId"`
	DueDate     *string `json:"dueDate"`
}

// validate checks the body and returns the store input; the problem is nil when everything is valid.
func (d *taskCreateDTO) validate() (store.TaskInput, *problem.Problem) {
	var v validator
	in := store.TaskInput{Priority: "medium", AssigneeID: d.AssigneeID}
	in.Title = v.text("/title", d.Title, 1, 200)
	in.Description = v.text("/description", d.Description, 0, 10000)
	if d.Priority != "" {
		v.oneOf("/priority", d.Priority, taskPriorities...)
		in.Priority = d.Priority
	}
	if d.AssigneeID != nil {
		v.uuid("/assigneeId", *d.AssigneeID)
	}
	if d.DueDate != nil {
		if due, ok := v.date("/dueDate", *d.DueDate); ok {
			in.DueDate = &due
		}
	}
	return in, v.result()
}

type taskUpdateDTO struct {
	Title       *string          `json:"title"`
	Description *string          `json:"description"`
	Status      *string          `json:"status"`
	Priority    *string          `json:"priority"`
	AssigneeID  optional[string] `json:"assigneeId"`
	DueDate     optional[string] `json:"dueDate"`
}

func (d *taskUpdateDTO) validate() (store.TaskPatch, *problem.Problem) {
	var v validator
	patch := store.TaskPatch{Title: d.Title, Description: d.Description, Status: d.Status, Priority: d.Priority}
	if d.Title == nil && d.Description == nil && d.Status == nil && d.Priority == nil && !d.AssigneeID.Set && !d.DueDate.Set {
		v.add("", "send at least one field to change")
	}
	if d.Title != nil {
		*d.Title = v.text("/title", *d.Title, 1, 200)
	}
	if d.Description != nil {
		*d.Description = v.text("/description", *d.Description, 0, 10000)
	}
	if d.Status != nil {
		v.oneOf("/status", *d.Status, taskStatuses...)
	}
	if d.Priority != nil {
		v.oneOf("/priority", *d.Priority, taskPriorities...)
	}
	if d.AssigneeID.Set {
		patch.SetAssignee, patch.AssigneeID = true, d.AssigneeID.Value
		if d.AssigneeID.Value != nil {
			v.uuid("/assigneeId", *d.AssigneeID.Value)
		}
	}
	if d.DueDate.Set {
		patch.SetDueDate = true
		if d.DueDate.Value != nil {
			if due, ok := v.date("/dueDate", *d.DueDate.Value); ok {
				patch.DueDate = &due
			}
		}
	}
	return patch, v.result()
}

type reassignDTO struct {
	AssigneeID optional[string] `json:"assigneeId"`
}

func (d *reassignDTO) validate() *problem.Problem {
	var v validator
	switch {
	case !d.AssigneeID.Set:
		v.add("/assigneeId", "is required; send null to unassign")
	case d.AssigneeID.Value != nil:
		v.uuid("/assigneeId", *d.AssigneeID.Value)
	}
	return v.result()
}

func (s *Server) registerTasks(mux *http.ServeMux) {
	s.handle(mux, "GET /v1/projects/{projectId}/tasks", auth.ScopeRead, s.listTasks)
	s.handle(mux, "POST /v1/projects/{projectId}/tasks", auth.ScopeWrite, s.createTask)
	s.handle(mux, "GET /v1/tasks/{taskId}", auth.ScopeRead, s.getTask)
	s.handle(mux, "PATCH /v1/tasks/{taskId}", auth.ScopeWrite, s.updateTask)
	s.handle(mux, "DELETE /v1/tasks/{taskId}", auth.ScopeWrite, s.deleteTask)
	s.handle(mux, "POST /v1/tasks/{taskId}/complete", auth.ScopeWrite, s.completeTask)
	s.handle(mux, "POST /v1/tasks/{taskId}/reassign", auth.ScopeWrite, s.reassignTask)
}

// taskAccess finds the team of the task in the URL and checks that the caller may act on it.
func (s *Server) taskAccess(w http.ResponseWriter, r *http.Request, need teamLevel) (taskID string, ok bool) {
	taskID, ok = pathID(w, r, "taskId")
	if !ok {
		return "", false
	}
	teamID, err := s.store.TeamOfTask(r.Context(), taskID)
	if err != nil {
		s.fail(w, r, err)
		return "", false
	}
	return taskID, s.authorize(w, r, teamID, need, "task")
}

// queryDate reads an optional date parameter such as dueBefore.
func queryDate(r *http.Request, name string) (*time.Time, *problem.Problem) {
	raw := r.URL.Query().Get(name)
	if raw == "" {
		return nil, nil
	}
	date, err := time.Parse(time.DateOnly, raw)
	if err != nil {
		return nil, problem.BadRequest(name + " must be a date such as 2027-06-30.")
	}
	return &date, nil
}

// queryEnum reads a repeatable parameter such as status and checks every value.
func queryEnum(r *http.Request, name string, allowed []string) ([]string, *problem.Problem) {
	values := r.URL.Query()[name]
	for _, value := range values {
		if !slices.Contains(allowed, value) {
			return nil, problem.BadRequest(name + " must be one of: " + strings.Join(allowed, ", ") + ".")
		}
	}
	return values, nil
}

func (s *Server) listTasks(w http.ResponseWriter, r *http.Request) {
	projectID, ok := pathID(w, r, "projectId")
	if !ok {
		return
	}
	teamID, err := s.store.TeamOfProject(r.Context(), projectID)
	if err != nil {
		s.fail(w, r, err)
		return
	}
	if !s.authorize(w, r, teamID, levelMember, "project") {
		return
	}
	filter := store.TaskFilter{ProjectID: projectID}
	var p *problem.Problem
	if filter.Page, p = pageParams(r); p != nil {
		problem.Write(w, r, p)
		return
	}
	if filter.Sort, p = sortParam(r, "-createdAt", "createdAt", "dueDate"); p != nil {
		problem.Write(w, r, p)
		return
	}
	if filter.Statuses, p = queryEnum(r, "status", taskStatuses); p != nil {
		problem.Write(w, r, p)
		return
	}
	if filter.Priorities, p = queryEnum(r, "priority", taskPriorities); p != nil {
		problem.Write(w, r, p)
		return
	}
	if filter.DueBefore, p = queryDate(r, "dueBefore"); p != nil {
		problem.Write(w, r, p)
		return
	}
	if filter.DueAfter, p = queryDate(r, "dueAfter"); p != nil {
		problem.Write(w, r, p)
		return
	}
	if filter.Title, p = textParam(r, "q", 100); p != nil {
		problem.Write(w, r, p)
		return
	}
	if filter.AssigneeID = r.URL.Query().Get("assigneeId"); filter.AssigneeID != "" && !isUUID(filter.AssigneeID) {
		problem.Write(w, r, problem.BadRequest("assigneeId must be a UUID."))
		return
	}
	result, err := s.store.ListTasks(r.Context(), filter)
	if err != nil {
		s.fail(w, r, err)
		return
	}
	writeJSON(w, r, http.StatusOK, toPage(result, filter.Page.Limit, toTaskDTO))
}

func (s *Server) createTask(w http.ResponseWriter, r *http.Request) {
	projectID, ok := pathID(w, r, "projectId")
	if !ok {
		return
	}
	teamID, err := s.store.TeamOfProject(r.Context(), projectID)
	if err != nil {
		s.fail(w, r, err)
		return
	}
	if !s.authorize(w, r, teamID, levelMember, "project") {
		return
	}
	var dto taskCreateDTO
	if p := decodeJSON(r, &dto); p != nil {
		problem.Write(w, r, p)
		return
	}
	input, p := dto.validate()
	if p != nil {
		problem.Write(w, r, p)
		return
	}
	task, err := s.store.CreateTask(r.Context(), auth.FromContext(r.Context()).ID, projectID, input)
	if err != nil {
		s.fail(w, r, err)
		return
	}
	w.Header().Set("Location", s.publicURL+"/v1/tasks/"+task.ID)
	respondEntity(w, r, http.StatusCreated, task.Version, toTaskDTO(task))
}

func (s *Server) getTask(w http.ResponseWriter, r *http.Request) {
	id, ok := s.taskAccess(w, r, levelMember)
	if !ok {
		return
	}
	task, err := s.store.GetTask(r.Context(), id)
	if err != nil {
		s.fail(w, r, err)
		return
	}
	respondEntity(w, r, http.StatusOK, task.Version, toTaskDTO(task))
}

func (s *Server) updateTask(w http.ResponseWriter, r *http.Request) {
	id, ok := s.taskAccess(w, r, levelMember)
	if !ok {
		return
	}
	expected, p := ifMatch(r, true)
	if p != nil {
		problem.Write(w, r, p)
		return
	}
	var dto taskUpdateDTO
	if p := decodeJSON(r, &dto); p != nil {
		problem.Write(w, r, p)
		return
	}
	patch, p := dto.validate()
	if p != nil {
		problem.Write(w, r, p)
		return
	}
	task, err := s.store.UpdateTask(r.Context(), auth.FromContext(r.Context()).ID, id, expected, patch)
	if err != nil {
		s.fail(w, r, err)
		return
	}
	respondEntity(w, r, http.StatusOK, task.Version, toTaskDTO(task))
}

func (s *Server) deleteTask(w http.ResponseWriter, r *http.Request) {
	id, ok := s.taskAccess(w, r, levelLead)
	if !ok {
		return
	}
	expected, p := ifMatch(r, false)
	if p != nil {
		problem.Write(w, r, p)
		return
	}
	if err := s.store.DeleteTask(r.Context(), auth.FromContext(r.Context()).ID, id, expected); err != nil {
		s.fail(w, r, err)
		return
	}
	w.WriteHeader(http.StatusNoContent)
}

// completeTask hands the work to the complete_task stored function: the rules live in the database.
func (s *Server) completeTask(w http.ResponseWriter, r *http.Request) {
	id, ok := s.taskAccess(w, r, levelMember)
	if !ok {
		return
	}
	expected, p := ifMatch(r, true)
	if p != nil {
		problem.Write(w, r, p)
		return
	}
	task, err := s.store.CompleteTask(r.Context(), auth.FromContext(r.Context()).ID, id, expected)
	if err != nil {
		s.fail(w, r, err)
		return
	}
	respondEntity(w, r, http.StatusOK, task.Version, toTaskDTO(task))
}

func (s *Server) reassignTask(w http.ResponseWriter, r *http.Request) {
	id, ok := s.taskAccess(w, r, levelLead)
	if !ok {
		return
	}
	expected, p := ifMatch(r, true)
	if p != nil {
		problem.Write(w, r, p)
		return
	}
	var dto reassignDTO
	if p := decodeJSON(r, &dto); p != nil {
		problem.Write(w, r, p)
		return
	}
	if p := dto.validate(); p != nil {
		problem.Write(w, r, p)
		return
	}
	task, err := s.store.ReassignTask(r.Context(), auth.FromContext(r.Context()).ID, id, dto.AssigneeID.Value, expected)
	if err != nil {
		s.fail(w, r, err)
		return
	}
	respondEntity(w, r, http.StatusOK, task.Version, toTaskDTO(task))
}
