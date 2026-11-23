package main

import (
	"context"
	"sync"
)

// generate is the first pipeline stage: it owns and closes its output channel.
func generate(ctx context.Context, nums ...int) <-chan int {
	out := make(chan int)
	go func() {
		defer close(out)
		for _, n := range nums {
			select {
			case out <- n:
			case <-ctx.Done():
				return
			}
		}
	}()
	return out
}

// stage applies fn to every value it receives.
func stage(ctx context.Context, in <-chan int, fn func(int) int) <-chan int {
	out := make(chan int)
	go func() {
		defer close(out)
		for n := range in {
			select {
			case out <- fn(n):
			case <-ctx.Done():
				return
			}
		}
	}()
	return out
}

// merge is the fan-in: it forwards every channel into one and closes it
// only after all inputs are drained.
func merge(ctx context.Context, inputs ...<-chan int) <-chan int {
	out := make(chan int)
	var wg sync.WaitGroup
	for _, in := range inputs {
		wg.Go(func() {
			for n := range in {
				select {
				case out <- n:
				case <-ctx.Done():
					return
				}
			}
		})
	}
	go func() {
		wg.Wait()
		close(out)
	}()
	return out
}

// sumOfSquares fans the squaring stage out to three goroutines that read the
// same source channel, then fans the results back in.
func sumOfSquares(ctx context.Context, nums ...int) int {
	src := generate(ctx, nums...)
	merged := merge(ctx,
		stage(ctx, src, square),
		stage(ctx, src, square),
		stage(ctx, src, square),
	)
	total := 0
	for n := range merged {
		total += n
	}
	return total
}
