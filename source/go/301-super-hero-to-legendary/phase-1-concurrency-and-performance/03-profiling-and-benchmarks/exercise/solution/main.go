package main

import (
	"fmt"
	"strings"
)

// JoinNaive builds the result with +=: every step allocates and copies a new string.
func JoinNaive(parts []string, sep string) string {
	out := ""
	for i, p := range parts {
		if i > 0 {
			out += sep
		}
		out += p
	}
	return out
}

// JoinBuilder returns exactly what JoinNaive returns, with one allocation for the result.
func JoinBuilder(parts []string, sep string) string {
	if len(parts) == 0 {
		return ""
	}
	size := len(sep) * (len(parts) - 1)
	for _, p := range parts {
		size += len(p)
	}
	var b strings.Builder
	b.Grow(size)
	for i, p := range parts {
		if i > 0 {
			b.WriteString(sep)
		}
		b.WriteString(p)
	}
	return b.String()
}

func main() {
	parts := []string{"a", "b", "c"}
	fmt.Println(JoinNaive(parts, ","))
	fmt.Println(JoinBuilder(parts, ","))
}
