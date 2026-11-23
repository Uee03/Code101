package main

import (
	"net/http"
	"net/http/httptest"
	"testing"
)

func TestRoutes(t *testing.T) {
	tests := []struct {
		name   string
		method string
		path   string
		want   int
	}{
		{"health", "GET", "/healthz", http.StatusOK},
		{"list", "GET", "/books", http.StatusOK},
		{"get one", "GET", "/books/1", http.StatusOK},
		{"missing book", "GET", "/books/99", http.StatusNotFound},
		{"bad id", "GET", "/books/abc", http.StatusBadRequest},
		{"delete", "DELETE", "/books/1", http.StatusNoContent},
		{"wrong method", "POST", "/books", http.StatusMethodNotAllowed},
		{"unknown path", "GET", "/nope", http.StatusNotFound},
		{"panic is recovered", "GET", "/boom", http.StatusInternalServerError},
	}
	for _, tc := range tests {
		t.Run(tc.name, func(t *testing.T) {
			rec := httptest.NewRecorder()
			req := httptest.NewRequest(tc.method, tc.path, nil)
			newRouter(NewStore()).ServeHTTP(rec, req)
			if rec.Code != tc.want {
				t.Fatalf("%s %s: status %d, want %d", tc.method, tc.path, rec.Code, tc.want)
			}
		})
	}
}

func TestGetBookBodyAndContentType(t *testing.T) {
	rec := httptest.NewRecorder()
	newRouter(NewStore()).ServeHTTP(rec, httptest.NewRequest("GET", "/books/2", nil))
	want := `{"id":2,"title":"Concurrency in Go","author":"Katherine Cox-Buday"}` + "\n"
	if rec.Body.String() != want {
		t.Fatalf("body %q, want %q", rec.Body.String(), want)
	}
	if ct := rec.Header().Get("Content-Type"); ct != "application/json" {
		t.Fatalf("content type %q, want application/json", ct)
	}
}
