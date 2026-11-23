package main

// Cache is a map of strings that many goroutines may read and write at the same time.
type Cache struct {
	// TODO 1: add the fields you need: a lock that lets many readers in at once, and the map.
}

func NewCache() *Cache {
	return &Cache{}
}

// Get returns the value stored under key and whether it was present.
func (c *Cache) Get(key string) (string, bool) {
	return "", false
}

// Set stores value under key.
func (c *Cache) Set(key, value string) {
}
