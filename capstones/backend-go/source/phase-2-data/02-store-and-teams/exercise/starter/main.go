package main

import (
	"fmt"
	"strings"
)

// likePrefix builds the LIKE pattern for "starts with, ignoring case".
// TODO: lower-case the text, put a backslash in front of each backslash, percent sign and underscore,
// and add a percent sign at the end. Use strings.NewReplacer.
func likePrefix(s string) string {
	return s
}

func main() {
	for _, input := range []string{"Plat", "50%_off", `a\b`} {
		fmt.Printf("%-8s -> %s\n", input, likePrefix(input))
	}
	_ = strings.ToLower // remove this line once you use the strings package
}
