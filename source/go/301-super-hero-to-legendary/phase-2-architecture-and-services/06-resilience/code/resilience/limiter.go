package resilience

import (
	"math"
	"net"
	"net/http"
	"strconv"
	"sync"
	"time"

	"golang.org/x/time/rate"
)

type limiterEntry struct {
	limiter *rate.Limiter
	seen    time.Time
}

// KeyedLimiter keeps one token bucket per key (a user, an API key, an address).
type KeyedLimiter struct {
	mu      sync.Mutex
	limit   rate.Limit
	burst   int
	entries map[string]*limiterEntry
}

func NewKeyedLimiter(limit rate.Limit, burst int) *KeyedLimiter {
	return &KeyedLimiter{limit: limit, burst: burst, entries: make(map[string]*limiterEntry)}
}

// Allow takes one token for key at time now. When it refuses, it also returns
// how long the caller should wait for a token.
func (k *KeyedLimiter) Allow(key string, now time.Time) (bool, time.Duration) {
	k.mu.Lock()
	defer k.mu.Unlock()

	e, ok := k.entries[key]
	if !ok {
		e = &limiterEntry{limiter: rate.NewLimiter(k.limit, k.burst)}
		k.entries[key] = e
	}
	e.seen = now

	r := e.limiter.ReserveN(now, 1)
	if !r.OK() {
		return false, 0
	}
	if delay := r.DelayFrom(now); delay > 0 {
		r.CancelAt(now) // give the token back: we are refusing, not waiting
		return false, delay
	}
	return true, 0
}

// Sweep forgets keys not seen for idle, so the map cannot grow without bound.
func (k *KeyedLimiter) Sweep(now time.Time, idle time.Duration) int {
	k.mu.Lock()
	defer k.mu.Unlock()
	removed := 0
	for key, e := range k.entries {
		if now.Sub(e.seen) > idle {
			delete(k.entries, key)
			removed++
		}
	}
	return removed
}

// RateLimit answers 429 with a Retry-After header when the caller is over its limit.
func RateLimit(l *KeyedLimiter, key func(*http.Request) string, next http.Handler) http.Handler {
	return http.HandlerFunc(func(w http.ResponseWriter, r *http.Request) {
		ok, wait := l.Allow(key(r), time.Now())
		if !ok {
			seconds := max(int(math.Ceil(wait.Seconds())), 1)
			w.Header().Set("Retry-After", strconv.Itoa(seconds))
			http.Error(w, "rate limit exceeded", http.StatusTooManyRequests)
			return
		}
		next.ServeHTTP(w, r)
	})
}

// ClientIP is the address of the direct peer. Behind a proxy it is the proxy's
// address; only read forwarding headers from proxies you control.
func ClientIP(r *http.Request) string {
	host, _, err := net.SplitHostPort(r.RemoteAddr)
	if err != nil {
		return r.RemoteAddr
	}
	return host
}
