package main

import "fmt"

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

// JoinBuilder must return exactly what JoinNaive returns.
// TODO 1: implement it with strings.Builder (add the import) and call Grow once
// with the exact final size, computed from len(sep) and the length of each part.
func JoinBuilder(parts []string, sep string) string {
	return ""
}

func main() {
	parts := []string{"a", "b", "c"}
	fmt.Println(JoinNaive(parts, ","))
	fmt.Println(JoinBuilder(parts, ","))
}
