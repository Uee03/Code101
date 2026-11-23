package main

import (
	"context"
	"errors"
)

// Withdraw takes amountCents out of an account by calling the stored function app.withdraw
// and returns the new balance. Map errors the same way Deposit does.
func (s *Store) Withdraw(ctx context.Context, id int, amountCents int64) (int64, error) {
	// TODO 2: call app.withdraw from Go.
	return 0, errors.New("not implemented")
}
