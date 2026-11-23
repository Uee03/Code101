package main

import (
	"context"
	"fmt"
	"sync"
	"time"
)

func main() {
	cache := NewCache()
	cache.Set("greeting", "hello")
	v, ok := cache.Get("greeting")
	fmt.Println("cache:", v, ok)
	v, ok = cache.Get("missing")
	fmt.Printf("cache: %q %v\n", v, ok)

	var fast sync.WaitGroup
	fast.Add(1)
	go func() {
		defer fast.Done()
	}()
	fmt.Println("waitAll fast:", waitAll(context.Background(), &fast))

	var slow sync.WaitGroup
	slow.Add(1)
	go func() {
		defer slow.Done()
		time.Sleep(time.Second)
	}()
	ctx, cancel := context.WithTimeout(context.Background(), 20*time.Millisecond)
	defer cancel()
	fmt.Println("waitAll slow:", waitAll(ctx, &slow))
}
