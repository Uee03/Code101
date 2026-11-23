package main

import (
	"strings"
	"testing"
)

func TestJoinBuilderMatchesNaive(t *testing.T) {
	cases := [][]string{nil, {"a"}, {"a", "b", "c"}, {"", "x", ""}}
	for _, parts := range cases {
		if got, want := JoinBuilder(parts, ", "), JoinNaive(parts, ", "); got != want {
			t.Fatalf("parts %q: got %q, want %q", parts, got, want)
		}
	}
}

var parts = strings.Split(strings.Repeat("word,", 1000), ",")

// TODO 2: write BenchmarkJoinNaive and BenchmarkJoinBuilder.
// Use b.ReportAllocs() and `for b.Loop() { ... }`, and join `parts` with ",".
