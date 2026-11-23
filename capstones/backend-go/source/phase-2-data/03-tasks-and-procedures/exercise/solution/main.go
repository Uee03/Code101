package main

import (
	"fmt"
	"strings"
)

// etagMatches implements the weak comparison of If-None-Match: the header is a comma separated list of ETags,
// each may start with W/, and * matches everything.
func etagMatches(header, etag string) bool {
	for _, candidate := range strings.Split(header, ",") {
		candidate = strings.TrimPrefix(strings.TrimSpace(candidate), "W/")
		if candidate == "*" || candidate == etag {
			return true
		}
	}
	return false
}

func main() {
	cases := []struct{ header, etag string }{
		{`"3"`, `"3"`},
		{`W/"3"`, `"3"`},
		{`"2", "3"`, `"3"`},
		{`*`, `"3"`},
		{`"4"`, `"3"`},
		{``, `"3"`},
	}
	for _, c := range cases {
		fmt.Printf("If-None-Match: %-10s ETag: %s -> %t\n", c.header, c.etag, etagMatches(c.header, c.etag))
	}
}
