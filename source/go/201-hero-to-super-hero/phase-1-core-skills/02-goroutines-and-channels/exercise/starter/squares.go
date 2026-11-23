package main

import "time"

// parallelSquares returns the square of every number, in the same order as the input,
// computed by the given number of worker goroutines.
func parallelSquares(nums []int, workers int) []int {
	out := make([]int, len(nums))
	// TODO 1: start the workers, hand each number to a worker together with its position,
	// and wait for all workers before returning. Add the imports you need.
	return out
}

// waitOrTimeout returns the next value from ch, or the text "timeout" if nothing
// arrives within d.
func waitOrTimeout(ch <-chan string, d time.Duration) string {
	// TODO 2: wait for whichever happens first.
	return ""
}
