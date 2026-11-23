package main

import (
	"fmt"
	"strings"
)

var likeEscaper = strings.NewReplacer(`\`, `\\`, `%`, `\%`, `_`, `\_`)

// likePrefix builds the LIKE pattern for "starts with, ignoring case".
func likePrefix(s string) string {
	return likeEscaper.Replace(strings.ToLower(s)) + "%"
}

func main() {
	for _, input := range []string{"Plat", "50%_off", `a\b`} {
		fmt.Printf("%-8s -> %s\n", input, likePrefix(input))
	}
}
