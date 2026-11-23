package main

import (
	"sort"
	"strings"
	"sync"
)

type result struct {
	Word  string
	Upper string
	Len   int
}

// process sends the words to a fixed number of workers and gathers their results.
func process(words []string, workers int) []result {
	if workers < 1 {
		workers = 1
	}
	jobs := make(chan string)
	results := make(chan result)

	var wg sync.WaitGroup
	for range workers {
		wg.Add(1)
		go func() {
			defer wg.Done()
			for w := range jobs {
				results <- result{Word: w, Upper: strings.ToUpper(w), Len: len(w)}
			}
		}()
	}

	go func() {
		defer close(jobs)
		for _, w := range words {
			jobs <- w
		}
	}()

	go func() {
		wg.Wait()
		close(results)
	}()

	var out []result
	for r := range results {
		out = append(out, r)
	}
	sort.Slice(out, func(i, j int) bool { return out[i].Word < out[j].Word })
	return out
}
