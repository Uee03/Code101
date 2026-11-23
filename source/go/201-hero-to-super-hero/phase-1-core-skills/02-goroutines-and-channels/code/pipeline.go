package main

// generate sends the numbers on a channel and closes it: the sender owns the closing.
func generate(nums ...int) <-chan int {
	out := make(chan int)
	go func() {
		defer close(out)
		for _, n := range nums {
			out <- n
		}
	}()
	return out
}

// square is one pipeline stage: it reads from in until in is closed.
func square(in <-chan int) <-chan int {
	out := make(chan int)
	go func() {
		defer close(out)
		for n := range in {
			out <- n * n
		}
	}()
	return out
}

// sum is the last stage: it drains its input and returns the total.
func sum(in <-chan int) int {
	total := 0
	for n := range in {
		total += n
	}
	return total
}
