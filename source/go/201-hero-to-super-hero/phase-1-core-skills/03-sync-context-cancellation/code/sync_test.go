package main

import (
	"context"
	"errors"
	"sync"
	"testing"
	"time"
)

func TestSafeCounterCountsEveryIncrement(t *testing.T) {
	c := NewSafeCounter()
	var wg sync.WaitGroup
	for range 50 {
		wg.Add(1)
		go func() {
			defer wg.Done()
			c.Inc("x")
		}()
	}
	wg.Wait()
	if got := c.Get("x"); got != 50 {
		t.Fatalf("got %d, want 50", got)
	}
}

func TestSlowCallStopsWhenContextIsDone(t *testing.T) {
	ctx, cancel := context.WithTimeout(context.Background(), 10*time.Millisecond)
	defer cancel()
	start := time.Now()
	err := slowCall(ctx, 5*time.Second)
	if !errors.Is(err, context.DeadlineExceeded) {
		t.Fatalf("got %v, want deadline exceeded", err)
	}
	if time.Since(start) > time.Second {
		t.Fatal("slowCall ignored the context")
	}
}

func TestTickerClosesItsChannelOnCancel(t *testing.T) {
	ctx, cancel := context.WithCancel(context.Background())
	out := make(chan int)
	go ticker(ctx, time.Millisecond, out)
	<-out
	cancel()

	done := make(chan struct{})
	go func() {
		for range out {
		}
		close(done)
	}()
	select {
	case <-done:
	case <-time.After(time.Second):
		t.Fatal("ticker did not stop after cancel")
	}
}
