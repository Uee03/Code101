package main

import (
	"sync"
	"time"
)

type job struct {
	index int
	value int
}

// parallelSquares returns the square of every number, in the same order as the input,
// computed by the given number of worker goroutines.
func parallelSquares(nums []int, workers int) []int {
	out := make([]int, len(nums))
	if workers < 1 {
		workers = 1
	}
	jobs := make(chan job)
	var wg sync.WaitGroup
	for range workers {
		wg.Add(1)
		go func() {
			defer wg.Done()
			for j := range jobs {
				out[j.index] = j.value * j.value
			}
		}()
	}
	for i, n := range nums {
		jobs <- job{index: i, value: n}
	}
	close(jobs)
	wg.Wait()
	return out
}

// waitOrTimeout returns the next value from ch, or the text "timeout" if nothing
// arrives within d.
func waitOrTimeout(ch <-chan string, d time.Duration) string {
	timer := time.NewTimer(d)
	defer timer.Stop()
	select {
	case v := <-ch:
		return v
	case <-timer.C:
		return "timeout"
	}
}
