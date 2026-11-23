package main

import (
	"context"
	"errors"
	"fmt"
	"net/http"
	"net/http/httptest"
	"strings"
	"time"

	"golang.org/x/time/rate"

	"example.com/code101/go301/l06/resilience"
)

func main() {
	demoRetry()
	demoBreaker()
	demoLimiter()
	demoIdempotency()
}

func demoRetry() {
	var waits []time.Duration
	policy := resilience.RetryPolicy{
		MaxAttempts: 5,
		BaseDelay:   10 * time.Millisecond,
		MaxDelay:    time.Second,
		Jitter:      func(ceiling time.Duration) time.Duration { return ceiling }, // no randomness, for a stable demo
		Sleep: func(_ context.Context, d time.Duration) error {
			waits = append(waits, d)
			return nil
		},
	}
	ctx := context.Background()

	calls := 0
	err := policy.Do(ctx, func(context.Context) error {
		calls++
		if calls < 4 {
			return errors.New("503 service unavailable")
		}
		return nil
	})
	fmt.Printf("retry: err=%v attempts=%d waits=%v\n", err, calls, waits)

	calls = 0
	err = policy.Do(ctx, func(context.Context) error {
		calls++
		return resilience.Permanent(errors.New("400 bad request"))
	})
	fmt.Printf("retry: %d attempt: %v\n", calls, err)

	waits = nil
	err = policy.Do(ctx, func(context.Context) error { return errors.New("503 service unavailable") })
	fmt.Printf("retry: %v (waits %v)\n", err, waits)
}

func demoBreaker() {
	now := time.Date(2026, 1, 1, 12, 0, 0, 0, time.UTC)
	b := resilience.NewBreaker(3, 30*time.Second, func() time.Time { return now })

	for range 3 {
		_ = b.Do(func() error { return errors.New("downstream failed") })
	}
	fmt.Println("breaker: state after 3 failures:", b.State())

	ran := false
	err := b.Do(func() error { ran = true; return nil })
	fmt.Printf("breaker: call while open: err=%v, operation ran=%t\n", err, ran)

	now = now.Add(31 * time.Second)
	err = b.Do(func() error { return nil })
	fmt.Printf("breaker: probe after 31s: err=%v, state=%v\n", err, b.State())
}

func demoLimiter() {
	limiter := resilience.NewKeyedLimiter(rate.Every(time.Second), 2)
	t0 := time.Date(2026, 1, 1, 12, 0, 0, 0, time.UTC)

	var results []bool
	var retryAfter time.Duration
	for range 3 {
		ok, wait := limiter.Allow("client-a", t0)
		results = append(results, ok)
		if !ok {
			retryAfter = wait
		}
	}
	later, _ := limiter.Allow("client-a", t0.Add(time.Second))
	other, _ := limiter.Allow("client-b", t0)
	fmt.Printf("limiter: client-a=%v retry-after=%v; one second later=%t; client-b=%t\n", results, retryAfter, later, other)
}

func demoIdempotency() {
	runs := 0
	create := http.HandlerFunc(func(w http.ResponseWriter, r *http.Request) {
		runs++
		w.Header().Set("Content-Type", "application/json")
		w.WriteHeader(http.StatusCreated)
		fmt.Fprintf(w, "{\"id\":%d}\n", runs)
	})
	handler := resilience.Idempotent(resilience.NewIdempotencyStore(), create)

	post := func(key, body string) *httptest.ResponseRecorder {
		req := httptest.NewRequest(http.MethodPost, "/orders", strings.NewReader(body))
		req.Header.Set("Idempotency-Key", key)
		rec := httptest.NewRecorder()
		handler.ServeHTTP(rec, req)
		return rec
	}

	first := post("k1", `{"item":"tea"}`)
	again := post("k1", `{"item":"tea"}`)
	other := post("k1", `{"item":"coffee"}`)
	fmt.Printf("idempotency: first=%d again=%d replayed=%s handler runs=%d body=%s", first.Code, again.Code, again.Header().Get("Idempotent-Replay"), runs, again.Body.String())
	fmt.Printf("idempotency: same key, different body: %d\n", other.Code)
}
