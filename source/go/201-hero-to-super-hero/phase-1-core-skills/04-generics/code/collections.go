package main

import "cmp"

// Number lists the types Sum accepts. The ~ means "any type whose underlying type is this",
// so a named type such as type Celsius float64 is accepted too.
type Number interface {
	~int | ~int64 | ~float64
}

// Map returns a new slice with f applied to every element.
func Map[T, U any](items []T, f func(T) U) []U {
	out := make([]U, 0, len(items))
	for _, item := range items {
		out = append(out, f(item))
	}
	return out
}

// Filter returns the elements for which keep returns true.
func Filter[T any](items []T, keep func(T) bool) []T {
	var out []T
	for _, item := range items {
		if keep(item) {
			out = append(out, item)
		}
	}
	return out
}

// Reduce folds the slice into one value, starting from start.
func Reduce[T, A any](items []T, start A, f func(A, T) A) A {
	acc := start
	for _, item := range items {
		acc = f(acc, item)
	}
	return acc
}

// Sum adds up any slice of numbers.
func Sum[T Number](items []T) T {
	var total T
	for _, item := range items {
		total += item
	}
	return total
}

// MaxOf returns the largest of its arguments. cmp.Ordered covers every type that supports < and >.
func MaxOf[T cmp.Ordered](first T, rest ...T) T {
	largest := first
	for _, v := range rest {
		if v > largest {
			largest = v
		}
	}
	return largest
}

// Stack is a last-in, first-out collection of any element type.
type Stack[T any] struct {
	items []T
}

func (s *Stack[T]) Push(v T) {
	s.items = append(s.items, v)
}

// Pop removes and returns the newest element; ok is false when the stack is empty.
func (s *Stack[T]) Pop() (v T, ok bool) {
	if len(s.items) == 0 {
		return v, false
	}
	last := len(s.items) - 1
	v = s.items[last]
	s.items = s.items[:last]
	return v, true
}

// Set is a collection of unique values. comparable means the type supports == and can be a map key.
type Set[T comparable] map[T]struct{}

func NewSet[T comparable](items ...T) Set[T] {
	s := make(Set[T], len(items))
	for _, item := range items {
		s[item] = struct{}{}
	}
	return s
}

func (s Set[T]) Has(v T) bool {
	_, ok := s[v]
	return ok
}

func (s Set[T]) Len() int {
	return len(s)
}
