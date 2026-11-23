package wordfreq

import (
	"cmp"
	"regexp"
	"slices"
	"strings"
)

// Entry is one word and how often it occurs.
type Entry struct {
	Word  string
	Count int
}

// CountNaive recompiles its regular expression on every call, a common
// real-world mistake that a profile makes visible.
func CountNaive(text string) map[string]int {
	re := regexp.MustCompile(`[a-z']+`)
	counts := make(map[string]int)
	for _, w := range re.FindAllString(strings.ToLower(text), -1) {
		counts[w]++
	}
	return counts
}

func isWordRune(r rune) bool { return r >= 'a' && r <= 'z' || r == '\'' }

func isSeparator(r rune) bool { return !isWordRune(r) }

// Count returns the same result as CountNaive without a regular expression.
func Count(text string) map[string]int {
	counts := make(map[string]int)
	for _, w := range strings.FieldsFunc(strings.ToLower(text), isSeparator) {
		counts[w]++
	}
	return counts
}

// Top returns the n most frequent words, ties broken alphabetically.
func Top(counts map[string]int, n int) []Entry {
	entries := make([]Entry, 0, len(counts))
	for w, c := range counts {
		entries = append(entries, Entry{Word: w, Count: c})
	}
	slices.SortFunc(entries, func(a, b Entry) int {
		return cmp.Or(cmp.Compare(b.Count, a.Count), strings.Compare(a.Word, b.Word))
	})
	if len(entries) > n {
		entries = entries[:n]
	}
	return entries
}
