package resilience

import (
	"context"
	"errors"
	"fmt"
	"math/rand/v2"
	"time"
)

// permanentError marks an error that retrying cannot fix.
type permanentError struct{ err error }

func (p permanentError) Error() string { return p.err.Error() }
func (p permanentError) Unwrap() error { return p.err }

// Permanent wraps err so that Do stops at once. Use it for failures that will
// repeat identically, such as a 400 Bad Request.
func Permanent(err error) error {
	if err == nil {
		return nil
	}
	return permanentError{err: err}
}

// RetryPolicy describes exponential backoff with jitter.
type RetryPolicy struct {
	MaxAttempts int           // total tries, including the first; default 3
	BaseDelay   time.Duration // wait before the second try, before jitter
	MaxDelay    time.Duration // cap for the wait
	// Jitter picks the real wait from the computed ceiling. The default is
	// "full jitter": a random value between zero and the ceiling.
	Jitter func(ceiling time.Duration) time.Duration
	// Sleep waits for d or until ctx ends. Tests replace it.
	Sleep func(ctx context.Context, d time.Duration) error
}

// Do calls op until it succeeds, returns a Permanent error, runs out of
// attempts or ctx ends while waiting.
func (p RetryPolicy) Do(ctx context.Context, op func(context.Context) error) error {
	if p.MaxAttempts < 1 {
		p.MaxAttempts = 3
	}
	if p.Jitter == nil {
		p.Jitter = fullJitter
	}
	if p.Sleep == nil {
		p.Sleep = sleepContext
	}

	for attempt := 1; ; attempt++ {
		err := op(ctx)
		if err == nil {
			return nil
		}

		var perm permanentError
		if errors.As(err, &perm) {
			return fmt.Errorf("permanent error on attempt %d: %w", attempt, perm.err)
		}
		if attempt >= p.MaxAttempts {
			return fmt.Errorf("gave up after %d attempts: %w", attempt, err)
		}

		wait := p.Jitter(backoff(p.BaseDelay, p.MaxDelay, attempt))
		if serr := p.Sleep(ctx, wait); serr != nil {
			return fmt.Errorf("retry aborted after %d attempts: %w (last error: %v)", attempt, serr, err)
		}
	}
}

// backoff doubles the base delay for every attempt already made and caps it.
func backoff(base, limit time.Duration, attempt int) time.Duration {
	d := base
	for i := 1; i < attempt; i++ {
		d *= 2
		if d >= limit {
			return limit
		}
	}
	return min(d, limit)
}

func fullJitter(ceiling time.Duration) time.Duration {
	if ceiling <= 0 {
		return 0
	}
	return rand.N(ceiling + 1)
}

func sleepContext(ctx context.Context, d time.Duration) error {
	t := time.NewTimer(d)
	defer t.Stop()
	select {
	case <-t.C:
		return nil
	case <-ctx.Done():
		return ctx.Err()
	}
}
