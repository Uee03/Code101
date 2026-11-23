package main

import (
	"context"
	"errors"
	"fmt"
	"strings"
)

type processFunc func(ctx context.Context, word string) (string, error)

// processAll applies fn to every word with at most limit goroutines at once.
// TODO 1: use errgroup.WithContext and SetLimit(limit).
// TODO 2: write each result to its own index so the output keeps the input order.
// TODO 3: on failure return no results and the first error, as: process "boom": rejected
func processAll(ctx context.Context, words []string, limit int, fn processFunc) ([]string, error) {
	return nil, errors.New("not implemented")
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
