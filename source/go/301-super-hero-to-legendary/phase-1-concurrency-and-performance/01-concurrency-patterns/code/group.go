package main

import (
	"context"
	"errors"
	"fmt"

	"golang.org/x/sync/errgroup"
)

type fetchFunc func(ctx context.Context, id int) (string, error)

// fetchAll runs fetch for every id with at most limit goroutines at a time.
// The first error cancels the shared context and is the one Wait returns.
func fetchAll(ctx context.Context, ids []int, limit int, fetch fetchFunc) ([]string, error) {
	g, ctx := errgroup.WithContext(ctx)
	g.SetLimit(limit)

	results := make([]string, len(ids))
	for i, id := range ids {
		g.Go(func() error {
			v, err := fetch(ctx, id)
			if err != nil {
				return fmt.Errorf("fetch %d: %w", id, err)
			}
			results[i] = v // each goroutine writes its own index: no race
			return nil
		})
	}
	if err := g.Wait(); err != nil {
		return nil, err
	}
	return results, nil
}

// fakeFetch stands in for a network call. It fails for failID.
func fakeFetch(failID int) fetchFunc {
	return func(ctx context.Context, id int) (string, error) {
		if err := ctx.Err(); err != nil {
			return "", err
		}
		if id == failID {
			return "", errors.New("not found")
		}
		return fmt.Sprintf("item-%d", id), nil
	}
}
