package app

import (
	"context"
	"errors"
	"testing"

	"example.com/code101/go301/l04/internal/domain"
)

// fakeStore and fixedID are test doubles. They satisfy the interfaces in
// service.go without importing any real adapter.
type fakeStore struct {
	tasks   map[string]domain.Task
	saveErr error
}

func (f *fakeStore) Save(_ context.Context, t domain.Task) error {
	if f.saveErr != nil {
		return f.saveErr
	}
	f.tasks[t.ID] = t
	return nil
}

func (f *fakeStore) Get(_ context.Context, id string) (domain.Task, error) {
	t, ok := f.tasks[id]
	if !ok {
		return domain.Task{}, domain.ErrNotFound
	}
	return t, nil
}

type fixedID string

func (f fixedID) NewID() string { return string(f) }

func TestCreateTrimsTitleAndAssignsID(t *testing.T) {
	store := &fakeStore{tasks: map[string]domain.Task{}}
	svc := NewService(store, fixedID("t-9"))

	got, err := svc.Create(context.Background(), "  write tests  ")
	if err != nil {
		t.Fatal(err)
	}
	if got.ID != "t-9" || got.Title != "write tests" || got.Done {
		t.Fatalf("unexpected task %+v", got)
	}
	if _, ok := store.tasks["t-9"]; !ok {
		t.Fatal("task was not saved")
	}
}

func TestCreateRejectsEmptyTitleWithoutSaving(t *testing.T) {
	store := &fakeStore{tasks: map[string]domain.Task{}}
	svc := NewService(store, fixedID("t-1"))

	_, err := svc.Create(context.Background(), "   ")
	if !errors.Is(err, domain.ErrEmptyTitle) {
		t.Fatalf("err = %v, want ErrEmptyTitle", err)
	}
	if len(store.tasks) != 0 {
		t.Fatal("an invalid task must not be saved")
	}
}

func TestCompleteMissingTaskIsNotFound(t *testing.T) {
	svc := NewService(&fakeStore{tasks: map[string]domain.Task{}}, fixedID("t-1"))

	_, err := svc.Complete(context.Background(), "nope")
	if !errors.Is(err, domain.ErrNotFound) {
		t.Fatalf("err = %v, want ErrNotFound", err)
	}
}

func TestStoreFailureIsWrappedNotReplaced(t *testing.T) {
	boom := errors.New("disk full")
	svc := NewService(&fakeStore{tasks: map[string]domain.Task{}, saveErr: boom}, fixedID("t-1"))

	_, err := svc.Create(context.Background(), "x")
	if !errors.Is(err, boom) {
		t.Fatalf("err = %v, want it to wrap %v", err, boom)
	}
}
