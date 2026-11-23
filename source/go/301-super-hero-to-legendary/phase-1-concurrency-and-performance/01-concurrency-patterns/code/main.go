package main

import (
	"context"
	"fmt"
)

func main() {
	ctx := context.Background()

	squares, err := workerPool(ctx, 4, []int{1, 2, 3, 4, 5, 6, 7, 8, 9, 10}, square)
	if err != nil {
		fmt.Println("worker pool failed:", err)
		return
	}
	fmt.Println("worker pool:", squares)

	fmt.Println("pipeline sum of squares 1..10:", sumOfSquares(ctx, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10))

	ids := []int{1, 2, 3, 4, 5}
	items, err := fetchAll(ctx, ids, 2, fakeFetch(0))
	fmt.Println("errgroup ok:", items, err)

	_, err = fetchAll(ctx, ids, 2, fakeFetch(3))
	fmt.Println("errgroup failure:", err)

	fmt.Println("leak demo, unbuffered channel:", countLeaks(false), "leaked goroutine(s)")
	fmt.Println("leak demo, buffered channel:", countLeaks(true), "leaked goroutine(s)")
}
