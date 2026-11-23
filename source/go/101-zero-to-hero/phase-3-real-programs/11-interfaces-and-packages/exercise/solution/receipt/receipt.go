package receipt

import "fmt"

type Receipt struct {
	Label string
	Cents int
}

func (r Receipt) Summary() string {
	return fmt.Sprintf("%s: %d cents", r.Label, r.Cents)
}
