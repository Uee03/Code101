package app

import (
	"context"
	"fmt"

	"example.com/code101/go301/l04/internal/domain"
)

// Store is what the use cases need from persistence. The interface lives here,
// with its consumer, and lists only the methods the consumer calls.
type Store interface {
	Save(ctx context.Context, t domain.Task) error
	Get(ctx context.Context, id string) (domain.Task, error)
}

// IDGenerator is what the use cases need to name new tasks.
type IDGenerator interface {
	NewID() string
}

// Service holds the application's use cases.
type Service struct {
	store Store
	ids   IDGenerator
}

func NewService(store Store, ids IDGenerator) *Service {
	return &Service{store: store, ids: ids}
}

func (s *Service) Create(ctx context.Context, title string) (domain.Task, error) {
	t, err := domain.NewTask(title)
	if err != nil {
		return domain.Task{}, err
	}
	t.ID = s.ids.NewID()
	if err := s.store.Save(ctx, t); err != nil {
		return domain.Task{}, fmt.Errorf("save task: %w", err)
	}
	return t, nil
}

func (s *Service) Get(ctx context.Context, id string) (domain.Task, error) {
	t, err := s.store.Get(ctx, id)
	if err != nil {
		return domain.Task{}, fmt.Errorf("get task %q: %w", id, err)
	}
	return t, nil
}

func (s *Service) Complete(ctx context.Context, id string) (domain.Task, error) {
	t, err := s.Get(ctx, id)
	if err != nil {
		return domain.Task{}, err
	}
	t = t.Completed()
	if err := s.store.Save(ctx, t); err != nil {
		return domain.Task{}, fmt.Errorf("save task: %w", err)
	}
	return t, nil
}
