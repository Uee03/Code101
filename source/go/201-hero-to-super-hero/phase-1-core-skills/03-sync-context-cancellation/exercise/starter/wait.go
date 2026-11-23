package main

import (
	"context"
	"sync"
)

// waitAll waits for wg to finish, but returns ctx.Err() if ctx is done first.
func waitAll(ctx context.Context, wg *sync.WaitGroup) error {
	// TODO 2: wait for whichever happens first, without blocking the caller past the context.
	return nil
}
