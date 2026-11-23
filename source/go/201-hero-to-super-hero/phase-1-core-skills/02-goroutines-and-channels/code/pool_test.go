package main

import (
	"reflect"
	"testing"
)

func TestProcessReturnsEveryWordSorted(t *testing.T) {
	got := process([]string{"b", "a", "ccc"}, 2)
	want := []result{
		{Word: "a", Upper: "A", Len: 1},
		{Word: "b", Upper: "B", Len: 1},
		{Word: "ccc", Upper: "CCC", Len: 3},
	}
	if !reflect.DeepEqual(got, want) {
		t.Fatalf("got %v, want %v", got, want)
	}
}

func TestProcessWithZeroWorkersStillFinishes(t *testing.T) {
	got := process([]string{"x"}, 0)
	if len(got) != 1 {
		t.Fatalf("got %d results, want 1", len(got))
	}
}

func TestPipelineSumsSquares(t *testing.T) {
	if got := sum(square(generate(1, 2, 3))); got != 14 {
		t.Fatalf("got %d, want 14", got)
	}
}

func TestTrySendDoesNotBlockOnFullChannel(t *testing.T) {
	ch := make(chan int, 1)
	if !trySend(ch, 1) {
		t.Fatal("first send should succeed")
	}
	if trySend(ch, 2) {
		t.Fatal("second send should be refused")
	}
}
