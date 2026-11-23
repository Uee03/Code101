package slug

import "testing"

func TestMake(t *testing.T) {
	tests := []struct {
		name  string
		title string
		want  string
	}{
		{"simple words", "Hello World", "hello-world"},
		{"punctuation collapses", "Hello, World!", "hello-world"},
		// TODO 1: add rows for these cases, each with the result the rules in slug.go demand:
		//   leading and trailing spaces ("  Go  ")
		//   an empty title ("")
		//   only symbols ("***")
		//   digits are kept ("Go 1.22 released")
		//   non-ASCII letters are kept ("Crème Brûlée")
	}
	for _, tc := range tests {
		t.Run(tc.name, func(t *testing.T) {
			if got := Make(tc.title); got != tc.want {
				t.Errorf("Make(%q) = %q, want %q", tc.title, got, tc.want)
			}
		})
	}
}

// TODO 3 (stretch): write FuzzMake. Property: for any input, the result never starts or ends with "-"
// and never contains "--". See https://go.dev/doc/security/fuzz/
