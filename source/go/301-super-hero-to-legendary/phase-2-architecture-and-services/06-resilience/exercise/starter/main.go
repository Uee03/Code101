package main

import (
	"fmt"
	"time"
)

// parseRetryAfter reads the value of a Retry-After header relative to now.
// TODO: support both forms HTTP defines: a whole number of seconds ("3") and
// an HTTP date ("Mon, 02 Jan 2006 15:04:10 GMT"). Return (0, false) for
// anything else, for negative numbers and for dates that are not in the future.
func parseRetryAfter(value string, now time.Time) (time.Duration, bool) {
	return 0, false
}

func main() {
	now := time.Date(2006, time.January, 2, 15, 4, 5, 0, time.UTC)
	values := []string{
		"3",
		"Mon, 02 Jan 2006 15:04:10 GMT",
		"-4",
		"soon",
		"Mon, 02 Jan 2006 15:04:00 GMT",
	}
	for _, v := range values {
		d, ok := parseRetryAfter(v, now)
		fmt.Printf("%q -> %v %t\n", v, d, ok)
	}
}
