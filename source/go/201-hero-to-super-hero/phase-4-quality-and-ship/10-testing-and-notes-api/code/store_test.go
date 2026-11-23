package main

import (
	"context"
	"errors"
	"testing"
	"time"
)

var fixedTime = time.Date(2030, 1, 1, 12, 0, 0, 0, time.UTC)

// seeded returns a store with one note ("first", id 1) and a frozen clock.
func seeded(t *testing.T) *memoryStore {
	t.Helper()
	s := newMemoryStore()
	s.now = func() time.Time { return fixedTime }
	if _, err := s.Create(context.Background(), "first", "body"); err != nil {
		t.Fatalf("seed: %v", err)
	}
	return s
}

func TestCreateSetsIDsAndTime(t *testing.T) {
	s := seeded(t)
	second, err := s.Create(context.Background(), "second", "")
	if err != nil {
		t.Fatalf("Create: %v", err)
	}
	if second.ID != 2 {
		t.Fatalf("ID %d, want 2", second.ID)
	}
	if !second.CreatedAt.Equal(fixedTime) {
		t.Fatalf("CreatedAt %v, want %v", second.CreatedAt, fixedTime)
	}
}

func TestGet(t *testing.T) {
	tests := []struct {
		name      string
		id        int
		wantTitle string
		wantErr   error
	}{
		{"existing note", 1, "first", nil},
		{"missing note", 2, "", ErrNotFound},
		{"zero id", 0, "", ErrNotFound},
	}
	for _, tc := range tests {
		t.Run(tc.name, func(t *testing.T) {
			got, err := seeded(t).Get(context.Background(), tc.id)
			if !errors.Is(err, tc.wantErr) {
				t.Fatalf("error %v, want %v", err, tc.wantErr)
			}
			if got.Title != tc.wantTitle {
				t.Fatalf("title %q, want %q", got.Title, tc.wantTitle)
			}
		})
	}
}

func TestDelete(t *testing.T) {
	tests := []struct {
		name    string
		id      int
		wantErr error
	}{
		{"existing note", 1, nil},
		{"missing note", 9, ErrNotFound},
	}
	for _, tc := range tests {
		t.Run(tc.name, func(t *testing.T) {
			s := seeded(t)
			if err := s.Delete(context.Background(), tc.id); !errors.Is(err, tc.wantErr) {
				t.Fatalf("error %v, want %v", err, tc.wantErr)
			}
			if tc.wantErr == nil {
				if _, err := s.Get(context.Background(), tc.id); !errors.Is(err, ErrNotFound) {
					t.Fatalf("deleted note is still there: %v", err)
				}
			}
		})
	}
}

func TestListIsOrderedAndNeverNil(t *testing.T) {
	empty, err := newMemoryStore().List(context.Background())
	if err != nil || empty == nil || len(empty) != 0 {
		t.Fatalf("empty store: got %v, %v; want an empty non-nil slice", empty, err)
	}

	s := seeded(t)
	_, _ = s.Create(context.Background(), "second", "")
	_, _ = s.Create(context.Background(), "third", "")
	notes, _ := s.List(context.Background())
	for i, n := range notes {
		if n.ID != i+1 {
			t.Fatalf("position %d holds ID %d, want %d", i, n.ID, i+1)
		}
	}
}
