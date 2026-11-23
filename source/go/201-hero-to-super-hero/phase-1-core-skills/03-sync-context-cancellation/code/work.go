package main

import (
	"context"
	"time"
)

// slowCall pretends to call a remote service that takes d. It gives up as soon as ctx is done.
func slowCall(ctx context.Context, d time.Duration) error {
	timer := time.NewTimer(d)
	defer timer.Stop()
	select {
	case <-timer.C:
		return nil
	case <-ctx.Done():
		return ctx.Err()
	}
}

// ticker sends 1, 2, 3, ... on out every interval until ctx is cancelled, then closes out.
func ticker(ctx context.Context, interval time.Duration, out chan<- int) {
	defer close(out)
	t := time.NewTicker(interval)
	defer t.Stop()
	for i := 1; ; i++ {
		select {
		case <-ctx.Done():
			return
		case <-t.C:
		}
		select {
		case out <- i:
		case <-ctx.Done():
			return
		}
	}
}
