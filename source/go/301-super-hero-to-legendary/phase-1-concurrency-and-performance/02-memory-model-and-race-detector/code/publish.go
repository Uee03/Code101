package main

import "time"

// racyPublish hands a message to another goroutine through two plain
// variables. Nothing orders the write of msg before the read of msg, so this
// is a data race on both variables. The loop is bounded so it cannot hang.
func racyPublish() string {
	var msg string
	var ready bool
	go func() {
		msg = "hello"
		ready = true
	}()
	for i := 0; i < 1000 && !ready; i++ {
		time.Sleep(time.Millisecond)
	}
	return msg
}

// safePublish closes a channel after writing msg. The close happens before
// the receive that observes it, so the read of msg is ordered after the write.
func safePublish() string {
	var msg string
	done := make(chan struct{})
	go func() {
		msg = "hello"
		close(done)
	}()
	<-done
	return msg
}
