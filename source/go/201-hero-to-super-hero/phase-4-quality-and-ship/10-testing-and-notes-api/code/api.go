package main

import (
	"encoding/json"
	"errors"
	"io"
	"log/slog"
	"mime"
	"net/http"
	"strconv"
	"strings"
	"time"
	"unicode/utf8"
)

// DTOs (lesson 06): what a client may send and what it receives.
type createNoteRequest struct {
	Title string `json:"title"`
	Body  string `json:"body"`
}

type noteResponse struct {
	ID        int       `json:"id"`
	Title     string    `json:"title"`
	Body      string    `json:"body"`
	CreatedAt time.Time `json:"createdAt"`
}

type fieldError struct {
	Field   string `json:"field"`
	Message string `json:"message"`
}

// problem is an RFC 9457 problem details object.
type problem struct {
	Type     string       `json:"type"`
	Title    string       `json:"title"`
	Status   int          `json:"status"`
	Detail   string       `json:"detail,omitempty"`
	Instance string       `json:"instance,omitempty"`
	Errors   []fieldError `json:"errors,omitempty"`
}

func (r createNoteRequest) validate() []fieldError {
	var errs []fieldError
	title := strings.TrimSpace(r.Title)
	if title == "" {
		errs = append(errs, fieldError{Field: "title", Message: "is required"})
	} else if utf8.RuneCountInString(title) > 100 {
		errs = append(errs, fieldError{Field: "title", Message: "must be at most 100 characters"})
	}
	if utf8.RuneCountInString(r.Body) > 2000 {
		errs = append(errs, fieldError{Field: "body", Message: "must be at most 2000 characters"})
	}
	return errs
}

func toResponse(n Note) noteResponse {
	return noteResponse{ID: n.ID, Title: n.Title, Body: n.Body, CreatedAt: n.CreatedAt}
}

type server struct {
	store  NoteStore
	logger *slog.Logger
}

// newRouter wires routes and middleware. It takes the store as an interface, so tests can pass a fake.
func newRouter(store NoteStore, logger *slog.Logger) http.Handler {
	s := &server{store: store, logger: logger}
	mux := http.NewServeMux()
	mux.HandleFunc("GET /healthz", s.health)
	mux.HandleFunc("POST /notes", s.createNote)
	mux.HandleFunc("GET /notes", s.listNotes)
	mux.HandleFunc("GET /notes/{id}", s.getNote)
	mux.HandleFunc("DELETE /notes/{id}", s.deleteNote)
	return chain(mux, requestLog(logger), recoverer(logger))
}

func (s *server) health(w http.ResponseWriter, r *http.Request) {
	writeJSON(w, http.StatusOK, map[string]string{"status": "ok"})
}

func (s *server) createNote(w http.ResponseWriter, r *http.Request) {
	var req createNoteRequest
	if !readJSON(w, r, &req) {
		return
	}
	if errs := req.validate(); len(errs) > 0 {
		writeProblem(w, r, http.StatusUnprocessableEntity, "validation-error", "Validation failed", "One or more fields are invalid.", errs)
		return
	}
	note, err := s.store.Create(r.Context(), strings.TrimSpace(req.Title), req.Body)
	if err != nil {
		s.fail(w, r, err)
		return
	}
	w.Header().Set("Location", "/notes/"+strconv.Itoa(note.ID))
	writeJSON(w, http.StatusCreated, toResponse(note))
}

func (s *server) listNotes(w http.ResponseWriter, r *http.Request) {
	notes, err := s.store.List(r.Context())
	if err != nil {
		s.fail(w, r, err)
		return
	}
	out := make([]noteResponse, 0, len(notes))
	for _, n := range notes {
		out = append(out, toResponse(n))
	}
	writeJSON(w, http.StatusOK, out)
}

func (s *server) getNote(w http.ResponseWriter, r *http.Request) {
	id, ok := pathID(w, r)
	if !ok {
		return
	}
	note, err := s.store.Get(r.Context(), id)
	if err != nil {
		s.fail(w, r, err)
		return
	}
	writeJSON(w, http.StatusOK, toResponse(note))
}

func (s *server) deleteNote(w http.ResponseWriter, r *http.Request) {
	id, ok := pathID(w, r)
	if !ok {
		return
	}
	if err := s.store.Delete(r.Context(), id); err != nil {
		s.fail(w, r, err)
		return
	}
	w.WriteHeader(http.StatusNoContent)
}

// fail maps a store error to a response. Unknown errors are logged and answered with a generic 500.
func (s *server) fail(w http.ResponseWriter, r *http.Request, err error) {
	if errors.Is(err, ErrNotFound) {
		writeProblem(w, r, http.StatusNotFound, "not-found", "Not found", "Note not found.", nil)
		return
	}
	s.logger.Error("request failed", "method", r.Method, "path", r.URL.Path, "err", err)
	writeProblem(w, r, http.StatusInternalServerError, "internal-error", "Internal server error", "", nil)
}

func pathID(w http.ResponseWriter, r *http.Request) (int, bool) {
	id, err := strconv.Atoi(r.PathValue("id"))
	if err != nil || id < 1 {
		writeProblem(w, r, http.StatusBadRequest, "bad-request", "Bad request", "id must be a positive number.", nil)
		return 0, false
	}
	return id, true
}

// readJSON decodes exactly one JSON object with the guards of lesson 06.
// On failure it has already written the problem response and returns false.
func readJSON(w http.ResponseWriter, r *http.Request, dst any) bool {
	mediaType, _, err := mime.ParseMediaType(r.Header.Get("Content-Type"))
	if err != nil || mediaType != "application/json" {
		writeProblem(w, r, http.StatusUnsupportedMediaType, "unsupported-media-type", "Unsupported media type", "Content-Type must be application/json.", nil)
		return false
	}
	r.Body = http.MaxBytesReader(w, r.Body, 1<<20)
	dec := json.NewDecoder(r.Body)
	dec.DisallowUnknownFields()
	if err := dec.Decode(dst); err != nil {
		status, detail := http.StatusBadRequest, "Body is not valid JSON for this endpoint."
		var tooBig *http.MaxBytesError
		if errors.As(err, &tooBig) {
			status, detail = http.StatusRequestEntityTooLarge, "Body must be at most 1 MiB."
		}
		writeProblem(w, r, status, "bad-request", "Bad request", detail, nil)
		return false
	}
	if err := dec.Decode(&struct{}{}); !errors.Is(err, io.EOF) {
		writeProblem(w, r, http.StatusBadRequest, "bad-request", "Bad request", "Body must contain a single JSON object.", nil)
		return false
	}
	return true
}

func writeProblem(w http.ResponseWriter, r *http.Request, status int, slug, title, detail string, errs []fieldError) {
	w.Header().Set("Content-Type", "application/problem+json")
	w.WriteHeader(status)
	_ = json.NewEncoder(w).Encode(problem{
		Type:     "https://example.com/problems/" + slug,
		Title:    title,
		Status:   status,
		Detail:   detail,
		Instance: r.URL.Path,
		Errors:   errs,
	})
}

func writeJSON(w http.ResponseWriter, status int, v any) {
	w.Header().Set("Content-Type", "application/json")
	w.WriteHeader(status)
	_ = json.NewEncoder(w).Encode(v)
}
