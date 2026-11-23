package main

import (
	"context"
	"errors"
	"fmt"
	"sync"
	"time"
)

func main() {
	// 1. Shared state: 100 goroutines add 10 each.
	counter := NewSafeCounter()
	var wg sync.WaitGroup
	for range 100 {
		wg.Add(1)
		go func() {
			defer wg.Done()
			for range 10 {
				counter.Inc("hits")
			}
		}()
	}
	wg.Wait()
	fmt.Println("hits:", counter.Get("hits"))

	// 2. A deadline: the call would take 2 seconds, the context allows 50 milliseconds.
	ctx, cancel := context.WithTimeout(context.Background(), 50*time.Millisecond)
	defer cancel()
	err := slowCall(ctx, 2*time.Second)
	fmt.Println("slowCall:", err)
	fmt.Println("deadline exceeded:", errors.Is(err, context.DeadlineExceeded))

	// 3. Manual cancellation: stop the ticker after the third tick.
	tctx, stop := context.WithCancel(context.Background())
	ticks := make(chan int)
	go ticker(tctx, 10*time.Millisecond, ticks)
	for n := range ticks {
		fmt.Println("tick", n)
		if n == 3 {
			stop()
			break
		}
	}
	for range ticks {
	}
	fmt.Println("ticker stopped")
}
