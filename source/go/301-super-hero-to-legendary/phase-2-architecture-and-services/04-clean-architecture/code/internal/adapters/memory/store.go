package memory

import (
	"context"
	"sync"

	"example.com/code101/go301/l04/internal/domain"
)

// Store keeps tasks in a map. It satisfies app.Store without importing the
// app package: Go interfaces are satisfied implicitly.
type Store struct {
	mu    sync.RWMutex
	tasks map[string]domain.Task
}

func NewStore() *Store {
	return &Store{tasks: make(map[string]domain.Task)}
}

func (s *Store) Save(_ context.Context, t domain.Task) error {
	s.mu.Lock()
	defer s.mu.Unlock()
	s.tasks[t.ID] = t
	return nil
}

func (s *Store) Get(_ context.Context, id string) (domain.Task, error) {
	s.mu.RLock()
	defer s.mu.RUnlock()
	t, ok := s.tasks[id]
	if !ok {
		return domain.Task{}, domain.ErrNotFound
	}
	return t, nil
}
