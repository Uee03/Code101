package main

import (
	"encoding/json"
	"log"
	"net/http"
	"slices"
	"strconv"
	"sync"
)

type Book struct {
	ID     int    `json:"id"`
	Title  string `json:"title"`
	Author string `json:"author"`
}

// Store keeps books in memory. The mutex makes it safe for the many goroutines net/http starts.
type Store struct {
	mu    sync.RWMutex
	books map[int]Book
}

func NewStore() *Store {
	return &Store{books: map[int]Book{
		1: {ID: 1, Title: "The Go Programming Language", Author: "Donovan and Kernighan"},
		2: {ID: 2, Title: "Concurrency in Go", Author: "Katherine Cox-Buday"},
	}}
}

func (s *Store) List() []Book {
	s.mu.RLock()
	defer s.mu.RUnlock()
	out := make([]Book, 0, len(s.books))
	for _, b := range s.books {
		out = append(out, b)
	}
	slices.SortFunc(out, func(a, b Book) int { return a.ID - b.ID })
	return out
}

func (s *Store) Get(id int) (Book, bool) {
	s.mu.RLock()
	defer s.mu.RUnlock()
	b, ok := s.books[id]
	return b, ok
}

func (s *Store) Delete(id int) bool {
	s.mu.Lock()
	defer s.mu.Unlock()
	_, ok := s.books[id]
	delete(s.books, id)
	return ok
}

// api holds what the handlers need; each handler is a method, so they share it without globals.
type api struct {
	store *Store
}

func (a *api) health(w http.ResponseWriter, r *http.Request) {
	writeJSON(w, http.StatusOK, map[string]string{"status": "ok"})
}

func (a *api) listBooks(w http.ResponseWriter, r *http.Request) {
	writeJSON(w, http.StatusOK, a.store.List())
}

func (a *api) getBook(w http.ResponseWriter, r *http.Request) {
	id, err := strconv.Atoi(r.PathValue("id"))
	if err != nil {
		http.Error(w, "id must be a number", http.StatusBadRequest)
		return
	}
	book, ok := a.store.Get(id)
	if !ok {
		http.Error(w, "book not found", http.StatusNotFound)
		return
	}
	writeJSON(w, http.StatusOK, book)
}

func (a *api) deleteBook(w http.ResponseWriter, r *http.Request) {
	id, err := strconv.Atoi(r.PathValue("id"))
	if err != nil {
		http.Error(w, "id must be a number", http.StatusBadRequest)
		return
	}
	if !a.store.Delete(id) {
		http.Error(w, "book not found", http.StatusNotFound)
		return
	}
	w.WriteHeader(http.StatusNoContent)
}

// writeJSON sets the headers first, then the status, then the body: the order matters,
// because headers cannot change after WriteHeader (or the first Write) has been called.
func writeJSON(w http.ResponseWriter, status int, v any) {
	w.Header().Set("Content-Type", "application/json")
	w.WriteHeader(status)
	if err := json.NewEncoder(w).Encode(v); err != nil {
		log.Printf("write response: %v", err)
	}
}
