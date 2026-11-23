package slug

import (
	"strings"
	"testing"
)

func TestMake(t *testing.T) {
	tests := []struct {
		name  string
		title string
		want  string
	}{
		{"simple words", "Hello World", "hello-world"},
		{"punctuation collapses", "Hello, World!", "hello-world"},
		{"leading and trailing spaces", "  Go  ", "go"},
		{"empty title", "", ""},
		{"only symbols", "***", ""},
		{"digits are kept", "Go 1.22 released", "go-1-22-released"},
		{"non-ASCII letters are kept", "Crème Brûlée", "crème-brûlée"},
	}
	for _, tc := range tests {
		t.Run(tc.name, func(t *testing.T) {
			if got := Make(tc.title); got != tc.want {
				t.Errorf("Make(%q) = %q, want %q", tc.title, got, tc.want)
			}
		})
	}
}

// FuzzMake checks a property for any input: no hyphen at either end and never two in a row.
// Without the -fuzz flag, go test runs only the seed inputs below.
func FuzzMake(f *testing.F) {
	f.Add("Hello, World!")
	f.Add("  ")
	f.Add("a--b")
	f.Fuzz(func(t *testing.T, title string) {
		got := Make(title)
		if strings.HasPrefix(got, "-") || strings.HasSuffix(got, "-") || strings.Contains(got, "--") {
			t.Fatalf("Make(%q) = %q has a stray hyphen", title, got)
		}
	})
}
