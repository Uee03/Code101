package main

import (
	"net/http"
	"net/http/httptest"
	"strings"
	"testing"
)

func do(t *testing.T, h http.Handler, method, path, contentType, body string) *httptest.ResponseRecorder {
	t.Helper()
	req := httptest.NewRequest(method, path, strings.NewReader(body))
	if contentType != "" {
		req.Header.Set("Content-Type", contentType)
	}
	rec := httptest.NewRecorder()
	h.ServeHTTP(rec, req)
	return rec
}

func TestCreateBookStatuses(t *testing.T) {
	tests := []struct {
		name        string
		contentType string
		body        string
		wantStatus  int
		wantType    string
	}{
		{"valid", "application/json", `{"title":"Learning Go","author":"Jon Bodner","pages":375}`, 201, "application/json"},
		{"missing fields", "application/json", `{"title":"","author":"","pages":0}`, 422, "application/problem+json"},
		{"wrong field type", "application/json", `{"title":"x","author":"y","pages":"many"}`, 400, "application/problem+json"},
		{"unknown field", "application/json", `{"title":"x","author":"y","pages":1,"admin":true}`, 400, "application/problem+json"},
		{"truncated json", "application/json", `{"title":"x"`, 400, "application/problem+json"},
		{"empty body", "application/json", ``, 400, "application/problem+json"},
		{"trailing data", "application/json", `{"title":"x","author":"y","pages":1} {}`, 400, "application/problem+json"},
		{"wrong content type", "text/plain", `{"title":"x","author":"y","pages":1}`, 415, "application/problem+json"},
	}
	for _, tc := range tests {
		t.Run(tc.name, func(t *testing.T) {
			rec := do(t, newRouter(NewStore()), "POST", "/books", tc.contentType, tc.body)
			if rec.Code != tc.wantStatus {
				t.Fatalf("status %d, want %d (body %s)", rec.Code, tc.wantStatus, rec.Body.String())
			}
			if got := rec.Header().Get("Content-Type"); got != tc.wantType {
				t.Fatalf("content type %q, want %q", got, tc.wantType)
			}
		})
	}
}

func TestValidationProblemBody(t *testing.T) {
	rec := do(t, newRouter(NewStore()), "POST", "/books", "application/json", `{"title":"","author":"","pages":0}`)
	want := `{"type":"https://example.com/problems/validation-error","title":"Validation failed","status":422,` +
		`"detail":"One or more fields are invalid.","instance":"/books",` +
		`"errors":[{"field":"title","message":"is required"},{"field":"author","message":"is required"},` +
		`{"field":"pages","message":"must be between 1 and 10000"}]}` + "\n"
	if rec.Body.String() != want {
		t.Fatalf("body\n%s\nwant\n%s", rec.Body.String(), want)
	}
}

func TestCreateThenGet(t *testing.T) {
	h := newRouter(NewStore())
	created := do(t, h, "POST", "/books", "application/json", `{"title":"Learning Go","author":"Jon Bodner","pages":375}`)
	if loc := created.Header().Get("Location"); loc != "/books/1" {
		t.Fatalf("Location %q, want /books/1", loc)
	}
	got := do(t, h, "GET", "/books/1", "", "")
	if got.Body.String() != created.Body.String() {
		t.Fatalf("GET body %q differs from POST body %q", got.Body.String(), created.Body.String())
	}
	if missing := do(t, h, "GET", "/books/7", "", ""); missing.Code != http.StatusNotFound {
		t.Fatalf("missing book: status %d, want 404", missing.Code)
	}
}
