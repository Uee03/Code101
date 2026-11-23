package main

import (
	"context"
	"sort"
	"sync"
)

func square(n int) int { return n * n }

// workerPool runs fn over every input with a fixed number of workers.
// Results are sorted so the output does not depend on scheduling.
func workerPool(ctx context.Context, workers int, inputs []int, fn func(int) int) ([]int, error) {
	jobs := make(chan int)
	results := make(chan int)

	go func() {
		defer close(jobs)
		for _, n := range inputs {
			select {
			case jobs <- n:
			case <-ctx.Done():
				return
			}
		}
	}()

	var wg sync.WaitGroup
	for range workers {
		wg.Go(func() {
			for n := range jobs {
				select {
				case results <- fn(n):
				case <-ctx.Done():
					return
				}
			}
		})
	}

	go func() {
		wg.Wait()
		close(results)
	}()

	var out []int
	for r := range results {
		out = append(out, r)
	}
	if err := ctx.Err(); err != nil {
		return nil, err
	}
	sort.Ints(out)
	return out, nil
}
