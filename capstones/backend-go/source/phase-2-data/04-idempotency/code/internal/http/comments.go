package httpapi

import (
	"net/http"
	"time"

	"example.com/tasksteams/internal/auth"
	"example.com/tasksteams/internal/problem"
	"example.com/tasksteams/internal/store"
)

type commentDTO struct {
	ID        string    `json:"id"`
	TaskID    string    `json:"taskId"`
	Author    userDTO   `json:"author"`
	Body      string    `json:"body"`
	CreatedAt time.Time `json:"createdAt"`
}

func toCommentDTO(c store.Comment) commentDTO {
	return commentDTO{
		ID: c.ID, TaskID: c.TaskID, Body: c.Body, CreatedAt: c.CreatedAt.UTC(),
		Author: userDTO{ID: c.AuthorID, Username: c.AuthorUsername, DisplayName: c.AuthorDisplayName},
	}
}

type commentCreateDTO struct {
	Body string `json:"body"`
}

func (d *commentCreateDTO) validate() *problem.Problem {
	var v validator
	d.Body = v.text("/body", d.Body, 1, 2000)
	return v.result()
}

func (s *Server) registerComments(mux *http.ServeMux) {
	s.handle(mux, "GET /v1/tasks/{taskId}/comments", auth.ScopeRead, s.listComments)
	s.handle(mux, "POST /v1/tasks/{taskId}/comments", auth.ScopeWrite, s.createComment)
	s.handle(mux, "DELETE /v1/comments/{commentId}", auth.ScopeWrite, s.deleteComment)
}

func (s *Server) listComments(w http.ResponseWriter, r *http.Request) {
	taskID, ok := s.taskAccess(w, r, levelMember)
	if !ok {
		return
	}
	page, p := pageParams(r)
	if p != nil {
		problem.Write(w, r, p)
		return
	}
	result, err := s.store.ListComments(r.Context(), taskID, page)
	if err != nil {
		s.fail(w, r, err)
		return
	}
	writeJSON(w, r, http.StatusOK, toPage(result, page.Limit, toCommentDTO))
}

func (s *Server) createComment(w http.ResponseWriter, r *http.Request) {
	taskID, ok := s.taskAccess(w, r, levelMember)
	if !ok {
		return
	}
	var dto commentCreateDTO
	if p := decodeJSON(r, &dto); p != nil {
		problem.Write(w, r, p)
		return
	}
	if p := dto.validate(); p != nil {
		problem.Write(w, r, p)
		return
	}
	comment, err := s.store.CreateComment(r.Context(), auth.FromContext(r.Context()).ID, taskID, dto.Body)
	if err != nil {
		s.fail(w, r, err)
		return
	}
	w.Header().Set("Location", s.publicURL+"/v1/comments/"+comment.ID)
	writeJSON(w, r, http.StatusCreated, toCommentDTO(comment))
}

// deleteComment lets the author, a team lead or an admin delete a comment.
func (s *Server) deleteComment(w http.ResponseWriter, r *http.Request) {
	id, ok := pathID(w, r, "commentId")
	if !ok {
		return
	}
	teamID, authorID, err := s.store.CommentOwner(r.Context(), id)
	if err != nil {
		s.fail(w, r, err)
		return
	}
	principal := auth.FromContext(r.Context())
	if !s.authorize(w, r, teamID, levelMember, "comment") {
		return
	}
	if authorID != principal.ID && !s.authorize(w, r, teamID, levelLead, "comment") {
		return
	}
	if err := s.store.DeleteComment(r.Context(), principal.ID, id); err != nil {
		s.fail(w, r, err)
		return
	}
	w.WriteHeader(http.StatusNoContent)
}
