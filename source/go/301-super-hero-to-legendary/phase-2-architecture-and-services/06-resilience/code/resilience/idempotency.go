package resilience

import (
	"bytes"
	"crypto/sha256"
	"encoding/hex"
	"io"
	"net/http"
	"sync"
)

type idempotencyEntry struct {
	fingerprint string
	done        bool
	status      int
	contentType string
	body        []byte
}

// IdempotencyStore remembers the first response for each Idempotency-Key.
// It is in memory and has no expiry: a real service uses a shared database
// table with a time-to-live (see the capstone chapter on idempotency keys).
type IdempotencyStore struct {
	mu      sync.Mutex
	entries map[string]*idempotencyEntry
}

func NewIdempotencyStore() *IdempotencyStore {
	return &IdempotencyStore{entries: make(map[string]*idempotencyEntry)}
}

// Idempotent makes POST requests that carry an Idempotency-Key safe to retry:
// the handler runs once per key, and repeats get the stored response.
func Idempotent(store *IdempotencyStore, next http.Handler) http.Handler {
	return http.HandlerFunc(func(w http.ResponseWriter, r *http.Request) {
		key := r.Header.Get("Idempotency-Key")
		if key == "" || r.Method != http.MethodPost {
			next.ServeHTTP(w, r)
			return
		}

		body, err := io.ReadAll(http.MaxBytesReader(w, r.Body, 1<<20))
		if err != nil {
			http.Error(w, "request body too large or unreadable", http.StatusBadRequest)
			return
		}
		r.Body = io.NopCloser(bytes.NewReader(body))
		sum := sha256.Sum256(append([]byte(r.Method+" "+r.URL.Path+"\n"), body...))
		fingerprint := hex.EncodeToString(sum[:])

		store.mu.Lock()
		if e, seen := store.entries[key]; seen {
			snapshot := *e
			store.mu.Unlock()
			replay(w, snapshot, fingerprint)
			return
		}
		store.entries[key] = &idempotencyEntry{fingerprint: fingerprint}
		store.mu.Unlock()

		stored := false
		defer func() {
			if !stored { // server error or panic: let the client try again
				store.mu.Lock()
				delete(store.entries, key)
				store.mu.Unlock()
			}
		}()

		rec := &recorder{ResponseWriter: w}
		next.ServeHTTP(rec, r)

		if rec.status() < 500 {
			store.mu.Lock()
			e := store.entries[key]
			e.done = true
			e.status = rec.status()
			e.contentType = w.Header().Get("Content-Type")
			e.body = rec.body.Bytes()
			store.mu.Unlock()
			stored = true
		}
	})
}

func replay(w http.ResponseWriter, e idempotencyEntry, fingerprint string) {
	switch {
	case e.fingerprint != fingerprint:
		http.Error(w, "Idempotency-Key was already used with a different request", http.StatusUnprocessableEntity)
	case !e.done:
		w.Header().Set("Retry-After", "1")
		http.Error(w, "a request with this Idempotency-Key is still in progress", http.StatusConflict)
	default:
		if e.contentType != "" {
			w.Header().Set("Content-Type", e.contentType)
		}
		w.Header().Set("Idempotent-Replay", "true")
		w.WriteHeader(e.status)
		_, _ = w.Write(e.body)
	}
}

// recorder copies what the handler writes so it can be stored and replayed.
type recorder struct {
	http.ResponseWriter
	code int
	body bytes.Buffer
}

func (r *recorder) WriteHeader(code int) {
	r.code = code
	r.ResponseWriter.WriteHeader(code)
}

func (r *recorder) Write(b []byte) (int, error) {
	if r.code == 0 {
		r.code = http.StatusOK
	}
	r.body.Write(b)
	return r.ResponseWriter.Write(b)
}

func (r *recorder) status() int {
	if r.code == 0 {
		return http.StatusOK
	}
	return r.code
}
