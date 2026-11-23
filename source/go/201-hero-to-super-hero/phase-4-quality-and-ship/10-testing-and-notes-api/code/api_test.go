package main

import (
	"context"
	"encoding/json"
	"errors"
	"io"
	"log/slog"
	"net/http"
	"net/http/httptest"
	"strings"
	"testing"
)

var quiet = slog.New(slog.NewTextHandler(io.Discard, nil))

func doRequest(h http.Handler, method, path, contentType, body string) *httptest.ResponseRecorder {
	req := httptest.NewRequest(method, path, strings.NewReader(body))
	if contentType != "" {
		req.Header.Set("Content-Type", contentType)
	}
	rec := httptest.NewRecorder()
	h.ServeHTTP(rec, req)
	return rec
}

func TestNotesAPI(t *testing.T) {
	const validBody = `{"title":"Buy milk","body":"2 litres"}`
	tests := []struct {
		name        string
		seed        int // how many notes exist before the request
		method      string
		path        string
		contentType string
		body        string
		wantStatus  int
		wantBody    string // a fragment that must appear; empty means "do not check"
	}{
		{"create", 0, "POST", "/notes", "application/json", validBody, 201, `"title":"Buy milk"`},
		{"create without a title", 0, "POST", "/notes", "application/json", `{"title":"  "}`, 422, `"field":"title"`},
		{"create with an unknown field", 0, "POST", "/notes", "application/json", `{"title":"x","admin":true}`, 400, "not valid JSON"},
		{"create with the wrong content type", 0, "POST", "/notes", "text/plain", validBody, 415, "application/json"},
		{"list when empty", 0, "GET", "/notes", "", "", 200, "[]"},
		{"get existing", 1, "GET", "/notes/1", "", "", 200, `"id":1`},
		{"get missing", 1, "GET", "/notes/7", "", "", 404, "Note not found."},
		{"get with a bad id", 0, "GET", "/notes/abc", "", "", 400, "positive number"},
		{"delete existing", 1, "DELETE", "/notes/1", "", "", 204, ""},
		{"delete missing", 0, "DELETE", "/notes/1", "", "", 404, "Note not found."},
		{"unsupported method", 0, "PUT", "/notes/1", "", "", 405, ""},
	}
	for _, tc := range tests {
		t.Run(tc.name, func(t *testing.T) {
			store := newMemoryStore()
			for range tc.seed {
				if _, err := store.Create(context.Background(), "seed", ""); err != nil {
					t.Fatalf("seed: %v", err)
				}
			}
			rec := doRequest(newRouter(store, quiet), tc.method, tc.path, tc.contentType, tc.body)
			if rec.Code != tc.wantStatus {
				t.Fatalf("status %d, want %d (body %s)", rec.Code, tc.wantStatus, rec.Body.String())
			}
			if tc.wantBody != "" && !strings.Contains(rec.Body.String(), tc.wantBody) {
				t.Errorf("body %q does not contain %q", rec.Body.String(), tc.wantBody)
			}
		})
	}
}

// httptest.NewServer starts a real server on a free local port: the whole path, including the network.
func TestRoundTripOverRealHTTP(t *testing.T) {
	srv := httptest.NewServer(newRouter(newMemoryStore(), quiet))
	t.Cleanup(srv.Close)

	resp, err := http.Post(srv.URL+"/notes", "application/json", strings.NewReader(`{"title":"Buy milk","body":"2 litres"}`))
	if err != nil {
		t.Fatalf("POST: %v", err)
	}
	defer resp.Body.Close()
	if resp.StatusCode != http.StatusCreated {
		t.Fatalf("status %d, want 201", resp.StatusCode)
	}
	if loc := resp.Header.Get("Location"); loc != "/notes/1" {
		t.Fatalf("Location %q, want /notes/1", loc)
	}
	var created noteResponse
	if err := json.NewDecoder(resp.Body).Decode(&created); err != nil {
		t.Fatalf("decode: %v", err)
	}
	if created.ID != 1 || created.Title != "Buy milk" {
		t.Fatalf("created %+v", created)
	}

	got, err := http.Get(srv.URL + "/notes/1")
	if err != nil {
		t.Fatalf("GET: %v", err)
	}
	defer got.Body.Close()
	if got.StatusCode != http.StatusOK {
		t.Fatalf("GET status %d, want 200", got.StatusCode)
	}
}

// failingStore embeds the interface (lesson 01) and overrides one method; the other methods are never called.
type failingStore struct{ NoteStore }

func (failingStore) List(context.Context) ([]Note, error) {
	return nil, errors.New("connection to secret-host refused")
}

func TestStoreFailureBecomesAGeneric500(t *testing.T) {
	rec := doRequest(newRouter(failingStore{}, quiet), "GET", "/notes", "", "")
	if rec.Code != http.StatusInternalServerError {
		t.Fatalf("status %d, want 500", rec.Code)
	}
	if strings.Contains(rec.Body.String(), "secret-host") {
		t.Fatal("internal error text leaked to the client")
	}
}

type panickingStore struct{ NoteStore }

func (panickingStore) Get(context.Context, int) (Note, error) {
	panic("boom")
}

func TestPanicIsRecoveredAndNotLeaked(t *testing.T) {
	rec := doRequest(newRouter(panickingStore{}, quiet), "GET", "/notes/1", "", "")
	if rec.Code != http.StatusInternalServerError {
		t.Fatalf("status %d, want 500", rec.Code)
	}
	if strings.Contains(rec.Body.String(), "boom") {
		t.Fatal("panic value leaked to the client")
	}
}
