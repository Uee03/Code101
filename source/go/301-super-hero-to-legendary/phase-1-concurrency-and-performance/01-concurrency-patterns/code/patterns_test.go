package main

import (
	"context"
	"errors"
	"slices"
	"testing"
)

func TestWorkerPoolSquares(t *testing.T) {
	got, err := workerPool(context.Background(), 3, []int{3, 1, 2}, square)
	if err != nil {
		t.Fatal(err)
	}
	if want := []int{1, 4, 9}; !slices.Equal(got, want) {
		t.Fatalf("got %v, want %v", got, want)
	}
}

func TestWorkerPoolStopsWhenCancelled(t *testing.T) {
	ctx, cancel := context.WithCancel(context.Background())
	cancel()

	got, err := workerPool(ctx, 2, []int{1, 2, 3}, square)
	if !errors.Is(err, context.Canceled) {
		t.Fatalf("err = %v, want context.Canceled", err)
	}
	if got != nil {
		t.Fatalf("got %v, want nil", got)
	}
}

func TestFetchAllReturnsFirstError(t *testing.T) {
	_, err := fetchAll(context.Background(), []int{1, 2, 3, 4}, 2, fakeFetch(3))
	if err == nil || err.Error() != "fetch 3: not found" {
		t.Fatalf("err = %v, want \"fetch 3: not found\"", err)
	}
}
