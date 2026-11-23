package resilience

import (
	"context"
	"errors"
	"net/http"
	"net/http/httptest"
	"strings"
	"sync"
	"sync/atomic"
	"testing"
	"time"

	"golang.org/x/time/rate"
)

func noSleep(waits *[]time.Duration) func(context.Context, time.Duration) error {
	return func(_ context.Context, d time.Duration) error {
		*waits = append(*waits, d)
		return nil
	}
}

func TestRetryBacksOffExponentiallyAndStopsAtMaxDelay(t *testing.T) {
	var waits []time.Duration
	policy := RetryPolicy{
		MaxAttempts: 6,
		BaseDelay:   100 * time.Millisecond,
		MaxDelay:    300 * time.Millisecond,
		Jitter:      func(d time.Duration) time.Duration { return d },
		Sleep:       noSleep(&waits),
	}

	err := policy.Do(context.Background(), func(context.Context) error { return errors.New("down") })
	if err == nil {
		t.Fatal("expected an error after the last attempt")
	}
	want := []time.Duration{100 * time.Millisecond, 200 * time.Millisecond, 300 * time.Millisecond, 300 * time.Millisecond, 300 * time.Millisecond}
	if len(waits) != len(want) {
		t.Fatalf("waits = %v, want %v", waits, want)
	}
	for i := range want {
		if waits[i] != want[i] {
			t.Fatalf("waits = %v, want %v", waits, want)
		}
	}
}

func TestRetryStopsOnPermanentError(t *testing.T) {
	calls := 0
	policy := RetryPolicy{MaxAttempts: 5, Sleep: noSleep(new([]time.Duration))}

	bad := errors.New("bad request")
	err := policy.Do(context.Background(), func(context.Context) error {
		calls++
		return Permanent(bad)
	})
	if calls != 1 || !errors.Is(err, bad) {
		t.Fatalf("calls = %d, err = %v; want 1 call and an error wrapping %v", calls, err, bad)
	}
}

func TestRetryStopsWhenContextEndsDuringWait(t *testing.T) {
	ctx, cancel := context.WithCancel(context.Background())
	policy := RetryPolicy{MaxAttempts: 5, BaseDelay: time.Hour, MaxDelay: time.Hour}

	err := policy.Do(ctx, func(context.Context) error {
		cancel()
		return errors.New("down")
	})
	if !errors.Is(err, context.Canceled) {
		t.Fatalf("err = %v, want it to wrap context.Canceled", err)
	}
}

func TestBreakerOpensThenRecovers(t *testing.T) {
	now := time.Date(2026, 1, 1, 12, 0, 0, 0, time.UTC)
	b := NewBreaker(2, time.Minute, func() time.Time { return now })
	fail := func() error { return errors.New("down") }

	_ = b.Do(fail)
	_ = b.Do(fail)
	if b.State() != Open {
		t.Fatalf("state = %v, want open", b.State())
	}
	if err := b.Do(func() error { t.Fatal("must not run while open"); return nil }); !errors.Is(err, ErrOpen) {
		t.Fatalf("err = %v, want ErrOpen", err)
	}

	now = now.Add(time.Minute + time.Second)
	if err := b.Do(func() error { return nil }); err != nil {
		t.Fatal(err)
	}
	if b.State() != Closed {
		t.Fatalf("state = %v, want closed after a successful probe", b.State())
	}
}

func TestBreakerReopensWhenProbeFails(t *testing.T) {
	now := time.Date(2026, 1, 1, 12, 0, 0, 0, time.UTC)
	b := NewBreaker(1, time.Minute, func() time.Time { return now })
	fail := func() error { return errors.New("down") }

	_ = b.Do(fail)
	now = now.Add(2 * time.Minute)
	_ = b.Do(fail)
	if b.State() != Open {
		t.Fatalf("state = %v, want open again after a failed probe", b.State())
	}
}

func TestKeyedLimiterIsolatesKeys(t *testing.T) {
	l := NewKeyedLimiter(rate.Every(time.Second), 1)
	t0 := time.Date(2026, 1, 1, 12, 0, 0, 0, time.UTC)

	if ok, _ := l.Allow("a", t0); !ok {
		t.Fatal("first call for a must pass")
	}
	if ok, wait := l.Allow("a", t0); ok || wait != time.Second {
		t.Fatalf("second call for a: ok = %t, wait = %v; want refused with 1s", ok, wait)
	}
	if ok, _ := l.Allow("b", t0); !ok {
		t.Fatal("key b must have its own bucket")
	}
	if removed := l.Sweep(t0.Add(time.Hour), time.Minute); removed != 2 {
		t.Fatalf("removed = %d, want 2", removed)
	}
}

func TestIdempotentRunsHandlerOnceUnderConcurrency(t *testing.T) {
	var runs atomic.Int32
	slow := http.HandlerFunc(func(w http.ResponseWriter, r *http.Request) {
		runs.Add(1)
		time.Sleep(20 * time.Millisecond)
		w.WriteHeader(http.StatusCreated)
	})
	h := Idempotent(NewIdempotencyStore(), slow)

	var wg sync.WaitGroup
	codes := make(chan int, 10)
	for range 10 {
		wg.Go(func() {
			req := httptest.NewRequest(http.MethodPost, "/orders", strings.NewReader(`{"item":"tea"}`))
			req.Header.Set("Idempotency-Key", "k1")
			rec := httptest.NewRecorder()
			h.ServeHTTP(rec, req)
			codes <- rec.Code
		})
	}
	wg.Wait()
	close(codes)

	created := 0
	for code := range codes {
		switch code {
		case http.StatusCreated:
			created++
		case http.StatusConflict:
		default:
			t.Fatalf("unexpected status %d", code)
		}
	}
	if runs.Load() != 1 || created < 1 {
		t.Fatalf("handler ran %d times and %d responses were 201; want exactly 1 run and at least one 201", runs.Load(), created)
	}
}
