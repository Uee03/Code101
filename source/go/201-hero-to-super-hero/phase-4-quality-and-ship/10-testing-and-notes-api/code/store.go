package main

import (
	"context"
	"errors"
	"slices"
	"sync"
	"time"
)

var ErrNotFound = errors.New("note not found")

// Note is the internal type; the HTTP layer converts it to a response DTO.
type Note struct {
	ID        int
	Title     string
	Body      string
	CreatedAt time.Time
}

// NoteStore is what the HTTP layer needs (lesson 01: a small interface at the consumer).
// memoryStore implements it here; the pgx store of lesson 08 could implement it too.
type NoteStore interface {
	Create(ctx context.Context, title, body string) (Note, error)
	Get(ctx context.Context, id int) (Note, error)
	List(ctx context.Context) ([]Note, error)
	Delete(ctx context.Context, id int) error
}

// memoryStore keeps notes in a map. now is a field so tests can fix the clock.
type memoryStore struct {
	mu     sync.Mutex
	nextID int
	notes  map[int]Note
	now    func() time.Time
}

func newMemoryStore() *memoryStore {
	return &memoryStore{nextID: 1, notes: make(map[int]Note), now: time.Now}
}

func (s *memoryStore) Create(ctx context.Context, title, body string) (Note, error) {
	s.mu.Lock()
	defer s.mu.Unlock()
	n := Note{ID: s.nextID, Title: title, Body: body, CreatedAt: s.now().UTC()}
	s.nextID++
	s.notes[n.ID] = n
	return n, nil
}

func (s *memoryStore) Get(ctx context.Context, id int) (Note, error) {
	s.mu.Lock()
	defer s.mu.Unlock()
	n, ok := s.notes[id]
	if !ok {
		return Note{}, ErrNotFound
	}
	return n, nil
}

func (s *memoryStore) List(ctx context.Context) ([]Note, error) {
	s.mu.Lock()
	defer s.mu.Unlock()
	out := make([]Note, 0, len(s.notes))
	for _, n := range s.notes {
		out = append(out, n)
	}
	slices.SortFunc(out, func(a, b Note) int { return a.ID - b.ID })
	return out, nil
}

func (s *memoryStore) Delete(ctx context.Context, id int) error {
	s.mu.Lock()
	defer s.mu.Unlock()
	if _, ok := s.notes[id]; !ok {
		return ErrNotFound
	}
	delete(s.notes, id)
	return nil
}
