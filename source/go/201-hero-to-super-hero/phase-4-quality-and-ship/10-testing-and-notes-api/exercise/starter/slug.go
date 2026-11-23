package slug

import (
	"strings"
	"unicode"
)

// Make turns a title into a URL-friendly slug.
//
//	"Hello World"       becomes "hello-world"
//	"  Hello, World!  " becomes "hello-world"
//
// Rules: lower case; letters and digits (any alphabet) are kept; every run of other characters
// becomes one hyphen; there is never a hyphen at the start or the end.
func Make(title string) string {
	var b strings.Builder
	lastHyphen := false
	for _, r := range strings.ToLower(title) {
		if unicode.IsLetter(r) || unicode.IsDigit(r) {
			b.WriteRune(r)
			lastHyphen = false
		} else if !lastHyphen {
			b.WriteByte('-')
			lastHyphen = true
		}
	}
	return b.String()
}
