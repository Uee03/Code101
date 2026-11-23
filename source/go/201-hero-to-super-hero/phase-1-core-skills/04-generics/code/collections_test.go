package main

import (
	"reflect"
	"testing"
)

func TestMapChangesTheElementType(t *testing.T) {
	got := Map([]int{1, 2, 3}, func(n int) string { return string(rune('a' + n - 1)) })
	want := []string{"a", "b", "c"}
	if !reflect.DeepEqual(got, want) {
		t.Fatalf("got %v, want %v", got, want)
	}
}

func TestFilterKeepsMatchesInOrder(t *testing.T) {
	got := Filter([]int{1, 2, 3, 4, 5, 6}, func(n int) bool { return n%2 == 0 })
	want := []int{2, 4, 6}
	if !reflect.DeepEqual(got, want) {
		t.Fatalf("got %v, want %v", got, want)
	}
}

func TestSumOfNothingIsZero(t *testing.T) {
	if got := Sum([]int(nil)); got != 0 {
		t.Fatalf("got %d, want 0", got)
	}
}

func TestMaxOfWorksForSeveralTypes(t *testing.T) {
	if got := MaxOf(2, 7, 5); got != 7 {
		t.Fatalf("ints: got %d, want 7", got)
	}
	if got := MaxOf("b", "c", "a"); got != "c" {
		t.Fatalf("strings: got %q, want c", got)
	}
}

func TestStackIsLastInFirstOut(t *testing.T) {
	var s Stack[int]
	s.Push(1)
	s.Push(2)
	if v, ok := s.Pop(); !ok || v != 2 {
		t.Fatalf("got %d %v, want 2 true", v, ok)
	}
	if v, ok := s.Pop(); !ok || v != 1 {
		t.Fatalf("got %d %v, want 1 true", v, ok)
	}
	if _, ok := s.Pop(); ok {
		t.Fatal("pop on empty stack should report false")
	}
}
