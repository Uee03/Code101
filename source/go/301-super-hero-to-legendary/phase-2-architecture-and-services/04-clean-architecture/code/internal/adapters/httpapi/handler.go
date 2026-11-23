package httpapi

import (
	"context"
	"encoding/json"
	"errors"
	"log/slog"
	"net/http"

	"example.com/code101/go301/l04/internal/domain"
)

// TaskService is what the HTTP layer needs from the application. It is
// defined here, at the consumer, so tests can pass a fake.
type TaskService interface {
	Create(ctx context.Context, title string) (domain.Task, error)
	Get(ctx context.Context, id string) (domain.Task, error)
	Complete(ctx context.Context, id string) (domain.Task, error)
}

// taskJSON is the wire format. It is a separate type from domain.Task so the
// API can change without touching the domain, and the other way round.
type taskJSON struct {
	ID    string `json:"id"`
	Title string `json:"title"`
	Done  bool   `json:"done"`
}

type createRequest struct {
	Title string `json:"title"`
}

type handler struct {
	svc TaskService
	log *slog.Logger
}

// New returns the router for the task API.
func New(svc TaskService, log *slog.Logger) http.Handler {
	h := &handler{svc: svc, log: log}
	mux := http.NewServeMux()
	mux.HandleFunc("POST /tasks", h.create)
	mux.HandleFunc("GET /tasks/{id}", h.get)
	mux.HandleFunc("POST /tasks/{id}/complete", h.complete)
	return mux
}

func (h *handler) create(w http.ResponseWriter, r *http.Request) {
	r.Body = http.MaxBytesReader(w, r.Body, 1<<20)
	dec := json.NewDecoder(r.Body)
	dec.DisallowUnknownFields()

	var req createRequest
	if err := dec.Decode(&req); err != nil {
		h.writeJSON(w, r, http.StatusBadRequest, map[string]string{"error": "body must be a JSON object with a title"})
		return
	}
	t, err := h.svc.Create(r.Context(), req.Title)
	if err != nil {
		h.fail(w, r, err)
		return
	}
	h.writeJSON(w, r, http.StatusCreated, toJSON(t))
}

func (h *handler) get(w http.ResponseWriter, r *http.Request) {
	t, err := h.svc.Get(r.Context(), r.PathValue("id"))
	if err != nil {
		h.fail(w, r, err)
		return
	}
	h.writeJSON(w, r, http.StatusOK, toJSON(t))
}

func (h *handler) complete(w http.ResponseWriter, r *http.Request) {
	t, err := h.svc.Complete(r.Context(), r.PathValue("id"))
	if err != nil {
		h.fail(w, r, err)
		return
	}
	h.writeJSON(w, r, http.StatusOK, toJSON(t))
}

// fail maps errors to responses in one place. Domain errors are safe to show;
// anything else is logged in full and answered with a generic message.
func (h *handler) fail(w http.ResponseWriter, r *http.Request, err error) {
	switch {
	case errors.Is(err, domain.ErrEmptyTitle), errors.Is(err, domain.ErrTitleTooLong):
		h.writeJSON(w, r, http.StatusBadRequest, map[string]string{"error": err.Error()})
	case errors.Is(err, domain.ErrNotFound):
		h.writeJSON(w, r, http.StatusNotFound, map[string]string{"error": "task not found"})
	default:
		h.log.ErrorContext(r.Context(), "request failed", "method", r.Method, "path", r.URL.Path, "error", err)
		h.writeJSON(w, r, http.StatusInternalServerError, map[string]string{"error": "internal error"})
	}
}

func (h *handler) writeJSON(w http.ResponseWriter, r *http.Request, status int, v any) {
	w.Header().Set("Content-Type", "application/json")
	w.WriteHeader(status)
	if err := json.NewEncoder(w).Encode(v); err != nil {
		h.log.ErrorContext(r.Context(), "write response", "error", err)
	}
}

func toJSON(t domain.Task) taskJSON {
	return taskJSON{ID: t.ID, Title: t.Title, Done: t.Done}
}
