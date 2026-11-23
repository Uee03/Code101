package main

import (
	"context"
	"errors"
	"fmt"
	"strings"

	"golang.org/x/sync/errgroup"
)

type processFunc func(ctx context.Context, word string) (string, error)

// processAll applies fn to every word with at most limit goroutines at once.
func processAll(ctx context.Context, words []string, limit int, fn processFunc) ([]string, error) {
	g, ctx := errgroup.WithContext(ctx)
	g.SetLimit(limit)

	results := make([]string, len(words))
	for i, word := range words {
		g.Go(func() error {
			out, err := fn(ctx, word)
			if err != nil {
				return fmt.Errorf("process %q: %w", word, err)
			}
			results[i] = out
			return nil
		})
	}
	if err := g.Wait(); err != nil {
		return nil, err
	}
	return results, nil
}

func upper(ctx context.Context, word string) (string, error) {
	if err := ctx.Err(); err != nil {
		return "", err
	}
	if word == "boom" {
		return "", errors.New("rejected")
	}
	return strings.ToUpper(word), nil
}

func main() {
	ctx := context.Background()

	got, err := processAll(ctx, []string{"go", "rust", "zig"}, 2, upper)
	fmt.Println(got, err)

	_, err = processAll(ctx, []string{"go", "boom", "zig"}, 2, upper)
	fmt.Println(err)
}
