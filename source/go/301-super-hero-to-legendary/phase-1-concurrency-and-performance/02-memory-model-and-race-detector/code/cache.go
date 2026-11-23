package main

import "sync"

// SafeCache guards a map with a read-write mutex: many readers or one writer.
type SafeCache struct {
	mu sync.RWMutex
	m  map[string]string
}

func NewSafeCache() *SafeCache {
	return &SafeCache{m: make(map[string]string)}
}

func (c *SafeCache) Set(key, value string) {
	c.mu.Lock()
	defer c.mu.Unlock()
	c.m[key] = value
}

func (c *SafeCache) Get(key string) (string, bool) {
	c.mu.RLock()
	defer c.mu.RUnlock()
	v, ok := c.m[key]
	return v, ok
}

// config is built once, on first use, by exactly one goroutine. Every later
// call observes the finished map, and nobody writes to it afterwards.
var config = sync.OnceValue(func() map[string]string {
	return map[string]string{"region": "eu-1"}
})

// racyMapWrites writes to one plain map from four goroutines. The Go runtime
// often detects this itself and stops the program with a fatal error.
func racyMapWrites() {
	m := make(map[int]int)
	var wg sync.WaitGroup
	for w := range 4 {
		wg.Go(func() {
			for i := range 1000 {
				m[w*1000+i] = i
			}
		})
	}
	wg.Wait()
}
