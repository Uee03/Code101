package wordfreq

import (
	"maps"
	"slices"
	"strings"
	"testing"
)

func TestCountMatchesNaive(t *testing.T) {
	texts := []string{
		"",
		"   ",
		"The quick brown fox. Don't panic! The DOG, again...",
		"It's 42 o'clock; ÉCOLE école",
	}
	for _, text := range texts {
		got, want := Count(text), CountNaive(text)
		if !maps.Equal(got, want) {
			t.Fatalf("text %q: Count = %v, CountNaive = %v", text, got, want)
		}
	}
}

func TestTopBreaksTiesAlphabetically(t *testing.T) {
	got := Top(map[string]int{"b": 2, "a": 2, "c": 5}, 2)
	want := []Entry{{Word: "c", Count: 5}, {Word: "a", Count: 2}}
	if !slices.Equal(got, want) {
		t.Fatalf("got %v, want %v", got, want)
	}
}

var benchText = strings.Repeat("The quick brown fox jumps over the lazy dog. Don't panic! ", 200)

func BenchmarkCountNaive(b *testing.B) {
	b.ReportAllocs()
	for b.Loop() {
		CountNaive(benchText)
	}
}

func BenchmarkCount(b *testing.B) {
	b.ReportAllocs()
	for b.Loop() {
		Count(benchText)
	}
}
