package httpapi

import (
	"context"
	"errors"
	"log/slog"
	"net/http"
	"net/http/httptest"
	"strings"
	"testing"

	"example.com/code101/go301/l04/internal/domain"
)

// fakeService returns the same task and error for every call.
type fakeService struct {
	task domain.Task
	err  error
}

func (f fakeService) Create(context.Context, string) (domain.Task, error) {
	return f.task, f.err
}

func (f fakeService) Get(context.Context, string) (domain.Task, error) {
	return f.task, f.err
}

func (f fakeService) Complete(context.Context, string) (domain.Task, error) {
	return f.task, f.err
}

func do(svc TaskService, method, target, body string) *httptest.ResponseRecorder {
	h := New(svc, slog.New(slog.DiscardHandler))
	req := httptest.NewRequest(method, target, strings.NewReader(body))
	rec := httptest.NewRecorder()
	h.ServeHTTP(rec, req)
	return rec
}

func TestErrorsMapToStatusCodes(t *testing.T) {
	cases := []struct {
		name string
		err  error
		want int
	}{
		{"empty title", domain.ErrEmptyTitle, http.StatusBadRequest},
		{"not found", domain.ErrNotFound, http.StatusNotFound},
		{"unexpected", errors.New("db password is hunter2"), http.StatusInternalServerError},
	}
	for _, tc := range cases {
		t.Run(tc.name, func(t *testing.T) {
			rec := do(fakeService{err: tc.err}, http.MethodPost, "/tasks", `{"title":"x"}`)
			if rec.Code != tc.want {
				t.Fatalf("status = %d, want %d", rec.Code, tc.want)
			}
			if strings.Contains(rec.Body.String(), "hunter2") {
				t.Fatalf("internal error text leaked to the client: %s", rec.Body.String())
			}
		})
	}
}

func TestCreateReturnsCreatedJSON(t *testing.T) {
	svc := fakeService{task: domain.Task{ID: "t-1", Title: "write", Done: false}}
	rec := do(svc, http.MethodPost, "/tasks", `{"title":"write"}`)

	if rec.Code != http.StatusCreated {
		t.Fatalf("status = %d, want 201", rec.Code)
	}
	want := `{"id":"t-1","title":"write","done":false}` + "\n"
	if rec.Body.String() != want {
		t.Fatalf("body = %q, want %q", rec.Body.String(), want)
	}
}

func TestCreateRejectsUnknownFields(t *testing.T) {
	rec := do(fakeService{}, http.MethodPost, "/tasks", `{"title":"x","admin":true}`)
	if rec.Code != http.StatusBadRequest {
		t.Fatalf("status = %d, want 400", rec.Code)
	}
}
