package main

import (
	"context"
	"sync"
)

// waitAll waits for wg to finish, but returns ctx.Err() if ctx is done first.
func waitAll(ctx context.Context, wg *sync.WaitGroup) error {
	done := make(chan struct{})
	go func() {
		wg.Wait()
		close(done)
	}()
	select {
	case <-done:
		return nil
	case <-ctx.Done():
		return ctx.Err()
	}
}
