package main

import "cmp"

// SortedKeys returns the keys of m in ascending order. Map order is random, so the result must be sorted.
// The constraint says what the key type must support; choose it from the standard library's cmp package.
func SortedKeys[K cmp.Ordered, V any](m map[K]V) []K {
	// TODO 1: collect the keys, then sort them (the standard library has a generic sort in package slices).
	return nil
}

// GroupBy collects items into lists, one list per key returned by key(item).
// Items in each list keep their input order.
func GroupBy[T any, K comparable](items []T, key func(T) K) map[K][]T {
	// TODO 2: build and return the map.
	return nil
}
