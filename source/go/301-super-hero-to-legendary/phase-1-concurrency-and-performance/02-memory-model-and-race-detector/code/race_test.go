package main

import (
	"fmt"
	"sync"
	"testing"
)

func TestSafeCountersReachTotal(t *testing.T) {
	counters := map[string]counter{
		"mutex":  &MutexCounter{},
		"atomic": &AtomicCounter{},
	}
	for name, c := range counters {
		t.Run(name, func(t *testing.T) {
			if got := hammer(c, 8, 1000); got != 8000 {
				t.Fatalf("got %d, want 8000", got)
			}
		})
	}
}

func TestSafePublish(t *testing.T) {
	if got := safePublish(); got != "hello" {
		t.Fatalf("got %q, want %q", got, "hello")
	}
}

func TestSafeCacheConcurrentWrites(t *testing.T) {
	cache := NewSafeCache()
	var wg sync.WaitGroup
	for w := range 4 {
		wg.Go(func() {
			for i := range 100 {
				cache.Set(fmt.Sprintf("k-%d-%d", w, i), "v")
			}
		})
	}
	wg.Wait()
	if _, ok := cache.Get("k-3-99"); !ok {
		t.Fatal("expected key k-3-99 to exist")
	}
}
