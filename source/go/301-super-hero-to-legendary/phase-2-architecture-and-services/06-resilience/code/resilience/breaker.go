package resilience

import (
	"errors"
	"sync"
	"time"
)

// State is the position of a circuit breaker.
type State int

const (
	Closed   State = iota // calls pass through; failures are counted
	Open                  // calls are rejected without running
	HalfOpen              // one probe call is allowed to test recovery
)

func (s State) String() string {
	switch s {
	case Closed:
		return "closed"
	case Open:
		return "open"
	case HalfOpen:
		return "half-open"
	}
	return "unknown"
}

// ErrOpen is returned when the breaker rejects a call.
var ErrOpen = errors.New("circuit breaker is open")

// Breaker opens after threshold consecutive failures, rejects calls for
// openFor, then lets a single probe through.
type Breaker struct {
	mu        sync.Mutex
	threshold int
	openFor   time.Duration
	now       func() time.Time

	state    State
	failures int
	openedAt time.Time
	probing  bool
}

func NewBreaker(threshold int, openFor time.Duration, now func() time.Time) *Breaker {
	return &Breaker{threshold: threshold, openFor: openFor, now: now}
}

func (b *Breaker) State() State {
	b.mu.Lock()
	defer b.mu.Unlock()
	return b.state
}

// Do runs op unless the breaker is open.
func (b *Breaker) Do(op func() error) error {
	if err := b.before(); err != nil {
		return err
	}
	err := op()
	b.after(err)
	return err
}

func (b *Breaker) before() error {
	b.mu.Lock()
	defer b.mu.Unlock()
	switch b.state {
	case Open:
		if b.now().Sub(b.openedAt) < b.openFor {
			return ErrOpen
		}
		b.state = HalfOpen
		b.probing = true
	case HalfOpen:
		if b.probing {
			return ErrOpen
		}
		b.probing = true
	}
	return nil
}

func (b *Breaker) after(err error) {
	b.mu.Lock()
	defer b.mu.Unlock()
	switch b.state {
	case HalfOpen:
		b.probing = false
		if err != nil {
			b.trip()
			return
		}
		b.state = Closed
		b.failures = 0
	case Closed:
		if err == nil {
			b.failures = 0
			return
		}
		b.failures++
		if b.failures >= b.threshold {
			b.trip()
		}
	}
}

func (b *Breaker) trip() {
	b.state = Open
	b.openedAt = b.now()
	b.failures = 0
}
