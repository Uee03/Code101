package main

import (
	"fmt"
	"net/http"
	"strconv"
	"strings"
	"time"
)

// parseRetryAfter reads the value of a Retry-After header relative to now.
func parseRetryAfter(value string, now time.Time) (time.Duration, bool) {
	if seconds, err := strconv.Atoi(strings.TrimSpace(value)); err == nil {
		if seconds < 0 {
			return 0, false
		}
		return time.Duration(seconds) * time.Second, true
	}
	if t, err := http.ParseTime(value); err == nil {
		if d := t.Sub(now); d > 0 {
			return d, true
		}
	}
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
