package httpapi

import (
	"fmt"
	"math"
	"net"
	"net/http"
	"strconv"
	"sync"
	"time"

	"example.com/tasksteams/internal/auth"
	"example.com/tasksteams/internal/problem"
)

type windowCounter struct {
	resetAt time.Time
	count   int
}

// rateLimiter counts requests per key in fixed windows. It keeps its state in memory, so each API process
// has its own counters: behind a load balancer the real limit is the number of processes times the limit.
// A fixed window is simple and cheap; its weakness is that a client can use the limit twice around a window edge.
type rateLimiter struct {
	mu        sync.Mutex
	window    time.Duration
	counters  map[string]*windowCounter
	lastSweep time.Time
}

func newRateLimiter(window time.Duration) *rateLimiter {
	return &rateLimiter{window: window, counters: map[string]*windowCounter{}}
}

// allow counts one request. It reports whether the request is within the limit, how many requests are left in
// the window and how long until the window ends.
func (l *rateLimiter) allow(key string, limit int) (ok bool, remaining int, resetIn time.Duration) {
	l.mu.Lock()
	defer l.mu.Unlock()
	now := time.Now()
	l.sweep(now)
	counter := l.counters[key]
	if counter == nil || !now.Before(counter.resetAt) {
		counter = &windowCounter{resetAt: now.Add(l.window)}
		l.counters[key] = counter
	}
	resetIn = counter.resetAt.Sub(now)
	if counter.count >= limit {
		return false, 0, resetIn
	}
	counter.count++
	return true, limit - counter.count, resetIn
}

// sweep drops finished windows once per window, so the map does not grow with every client ever seen.
func (l *rateLimiter) sweep(now time.Time) {
	if now.Sub(l.lastSweep) < l.window {
		return
	}
	for key, counter := range l.counters {
		if !now.Before(counter.resetAt) {
			delete(l.counters, key)
		}
	}
	l.lastSweep = now
}

// clientIP is the address of the TCP peer. X-Forwarded-For is deliberately ignored: any client can send it,
// so trusting it would let an attacker pick a fresh "address" for every request. Behind a trusted proxy,
// configure the proxy to enforce limits or read the header only from that proxy.
func clientIP(r *http.Request) string {
	host, _, err := net.SplitHostPort(r.RemoteAddr)
	if err != nil {
		return r.RemoteAddr
	}
	return host
}

// rateLimit limits each signed-in user and, for requests without a valid token, each client address.
// Probes of /health are not counted. Every other response carries the RateLimit headers of the contract.
func (s *Server) rateLimit(next http.Handler) http.Handler {
	return http.HandlerFunc(func(w http.ResponseWriter, r *http.Request) {
		if r.URL.Path == "/health" {
			next.ServeHTTP(w, r)
			return
		}
		key, limit := "ip:"+clientIP(r), s.anonymousLimit
		if principal := auth.FromContext(r.Context()); principal != nil {
			key, limit = "user:"+principal.ID, s.userLimit
		}
		ok, remaining, resetIn := s.limiter.allow(key, limit)
		seconds := int(math.Ceil(resetIn.Seconds()))
		header := w.Header()
		header.Set("RateLimit-Limit", strconv.Itoa(limit))
		header.Set("RateLimit-Remaining", strconv.Itoa(remaining))
		header.Set("RateLimit-Reset", strconv.Itoa(seconds))
		if !ok {
			info := infoFrom(r.Context())
			s.logger.Warn("rate limit exceeded", "user_id", info.userID, "trace_id", info.traceID)
			problem.Write(w, r, problem.New(http.StatusTooManyRequests, "rate-limited", "Too many requests",
				fmt.Sprintf("Retry in %d seconds.", seconds)).WithHeader("Retry-After", strconv.Itoa(seconds)))
			return
		}
		next.ServeHTTP(w, r)
	})
}
