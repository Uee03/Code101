package main

import (
	"net/http"
	"net/http/httptest"
	"testing"
)

func get(t *testing.T, path string) *httptest.ResponseRecorder {
	t.Helper()
	rec := httptest.NewRecorder()
	newRouter().ServeHTTP(rec, httptest.NewRequest(http.MethodGet, path, nil))
	return rec
}

func TestHelloWithName(t *testing.T) {
	rec := get(t, "/hello/ada")
	if rec.Code != http.StatusOK || rec.Body.String() != "hello, ada" {
		t.Fatalf("got %d %q, want 200 \"hello, ada\"", rec.Code, rec.Body.String())
	}
}

func TestHelloWithoutName(t *testing.T) {
	rec := get(t, "/hello")
	if rec.Code != http.StatusOK || rec.Body.String() != "hello, world" {
		t.Fatalf("got %d %q, want 200 \"hello, world\"", rec.Code, rec.Body.String())
	}
}

func TestNosniffOnEveryResponse(t *testing.T) {
	for _, path := range []string{"/hello", "/hello/ada", "/missing"} {
		if got := get(t, path).Header().Get("X-Content-Type-Options"); got != "nosniff" {
			t.Errorf("%s: header is %q, want nosniff", path, got)
		}
	}
}

func TestPostIsNotAllowed(t *testing.T) {
	rec := httptest.NewRecorder()
	newRouter().ServeHTTP(rec, httptest.NewRequest(http.MethodPost, "/hello", nil))
	if rec.Code != http.StatusMethodNotAllowed {
		t.Fatalf("got %d, want 405", rec.Code)
	}
}
