package main

import (
	"fmt"
	"time"
)

func main() {
	fmt.Println(parallelSquares([]int{1, 2, 3, 4, 5}, 3))

	ready := make(chan string, 1)
	ready <- "ready"
	fmt.Println(waitOrTimeout(ready, 50*time.Millisecond))

	never := make(chan string)
	fmt.Println(waitOrTimeout(never, 20*time.Millisecond))
}
