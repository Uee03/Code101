package idgen

import (
	"strconv"
	"sync/atomic"
)

// Sequential hands out t-1, t-2, ... It is safe for concurrent use.
type Sequential struct {
	n atomic.Int64
}

func (s *Sequential) NewID() string {
	return "t-" + strconv.FormatInt(s.n.Add(1), 10)
}
