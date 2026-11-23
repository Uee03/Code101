package main

import (
	"fmt"
	"time"
)

type counter struct {
	resetAt time.Time
	count   int
}

type limiter struct {
	window   time.Duration
	counters map[string]*counter
}

// allow counts one request of key at time now and reports whether it is within limit and how many are left.
// TODO: start a new window when there is none for the key or the old one ended (now is not before resetAt);
// deny when the window already holds limit requests; otherwise count the request.
func (l *limiter) allow(key string, limit int, now time.Time) (ok bool, remaining int) {
	return true, limit
}

func main() {
	l := &limiter{window: 10 * time.Second, counters: map[string]*counter{}}
	start := time.Date(2027, 1, 1, 12, 0, 0, 0, time.UTC)
	for _, offset := range []int{0, 1, 2, 3, 9, 10, 11} {
		ok, remaining := l.allow("user:alice", 3, start.Add(time.Duration(offset)*time.Second))
		if ok {
			fmt.Printf("t+%-2ds allowed remaining=%d\n", offset, remaining)
		} else {
			fmt.Printf("t+%-2ds denied\n", offset)
		}
	}
}
