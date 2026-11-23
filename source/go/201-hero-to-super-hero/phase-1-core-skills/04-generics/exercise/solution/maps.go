package main

import (
	"cmp"
	"slices"
)

// SortedKeys returns the keys of m in ascending order. Map order is random, so the result must be sorted.
// The constraint says what the key type must support; choose it from the standard library's cmp package.
func SortedKeys[K cmp.Ordered, V any](m map[K]V) []K {
	keys := make([]K, 0, len(m))
	for k := range m {
		keys = append(keys, k)
	}
	slices.Sort(keys)
	return keys
}

// GroupBy collects items into lists, one list per key returned by key(item).
// Items in each list keep their input order.
func GroupBy[T any, K comparable](items []T, key func(T) K) map[K][]T {
	out := make(map[K][]T)
	for _, item := range items {
		k := key(item)
		out[k] = append(out[k], item)
	}
	return out
}
