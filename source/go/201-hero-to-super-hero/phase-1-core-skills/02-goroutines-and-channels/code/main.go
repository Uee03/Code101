package main

import "fmt"

func main() {
	words := []string{"gopher", "channel", "goroutine", "select", "mutex"}
	for _, r := range process(words, 3) {
		fmt.Println(r.Word, r.Upper, r.Len)
	}

	bufferedDemo()

	fmt.Println(sum(square(generate(1, 2, 3, 4))))

	full := make(chan int, 1)
	fmt.Println(trySend(full, 1), trySend(full, 2))
}

// bufferedDemo shows that a buffered channel accepts sends until it is full,
// and that a closed channel still delivers what it holds.
func bufferedDemo() {
	ch := make(chan string, 2)
	ch <- "first"
	ch <- "second"
	close(ch)
	for v := range ch {
		fmt.Println(v)
	}
	v, ok := <-ch
	fmt.Printf("%q %v\n", v, ok)
}

// trySend uses select with default so it never blocks.
func trySend(ch chan<- int, v int) bool {
	select {
	case ch <- v:
		return true
	default:
		return false
	}
}
