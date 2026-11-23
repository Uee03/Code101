package main

import "context"

// Withdraw takes amountCents out of an account by calling the stored function app.withdraw
// and returns the new balance. Map errors the same way Deposit does.
func (s *Store) Withdraw(ctx context.Context, id int, amountCents int64) (int64, error) {
	var newBalance int64
	err := s.pool.QueryRow(ctx, `SELECT app.withdraw($1, $2)`, id, amountCents).Scan(&newBalance)
	if err != nil {
		return 0, translate(err)
	}
	return newBalance, nil
}
