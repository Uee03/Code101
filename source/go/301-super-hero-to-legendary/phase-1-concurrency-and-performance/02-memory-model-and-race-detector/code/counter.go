package main

import (
	"sync"
	"sync/atomic"
)

type counter interface {
	Inc()
	Value() int
}

// RacyCounter has a data race: Inc is not synchronised.
type RacyCounter struct{ n int }

func (c *RacyCounter) Inc()       { c.n++ }
func (c *RacyCounter) Value() int { return c.n }

// MutexCounter protects n with a mutex; every access takes the lock.
type MutexCounter struct {
	mu sync.Mutex
	n  int
}

func (c *MutexCounter) Inc() {
	c.mu.Lock()
	defer c.mu.Unlock()
	c.n++
}

func (c *MutexCounter) Value() int {
	c.mu.Lock()
	defer c.mu.Unlock()
	return c.n
}

// AtomicCounter uses a lock-free atomic integer.
type AtomicCounter struct{ n atomic.Int64 }

func (c *AtomicCounter) Inc()       { c.n.Add(1) }
func (c *AtomicCounter) Value() int { return int(c.n.Load()) }

// hammer calls Inc perWorker times from each of workers goroutines and waits.
func hammer(c counter, workers, perWorker int) int {
	var wg sync.WaitGroup
	for range workers {
		wg.Go(func() {
			for range perWorker {
				c.Inc()
			}
		})
	}
	wg.Wait()
	return c.Value()
}
