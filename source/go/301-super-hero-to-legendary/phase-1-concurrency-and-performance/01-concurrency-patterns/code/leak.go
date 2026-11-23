package main

import (
	"context"
	"runtime"
	"time"
)

// slowQuery waits for a result for as long as ctx allows. The worker takes
// 50 ms. With an unbuffered channel the worker blocks forever on its send when
// the caller has already given up; a buffer of one lets it finish and exit.
func slowQuery(ctx context.Context, buffered bool) error {
	size := 0
	if buffered {
		size = 1
	}
	ch := make(chan int, size)
	go func() {
		time.Sleep(50 * time.Millisecond)
		ch <- 42
	}()

	select {
	case <-ch:
		return nil
	case <-ctx.Done():
		return ctx.Err()
	}
}

// countLeaks gives up after 10 ms and reports how many goroutines are left
// over once the worker has had time to finish.
func countLeaks(buffered bool) int {
	time.Sleep(20 * time.Millisecond)
	before := runtime.NumGoroutine()

	ctx, cancel := context.WithTimeout(context.Background(), 10*time.Millisecond)
	defer cancel()
	_ = slowQuery(ctx, buffered)

	time.Sleep(150 * time.Millisecond)
	return runtime.NumGoroutine() - before
}
