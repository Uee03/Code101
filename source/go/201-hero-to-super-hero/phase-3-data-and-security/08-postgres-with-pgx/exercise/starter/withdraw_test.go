package main

import (
	"context"
	"errors"
	"testing"
)

func TestWithdraw(t *testing.T) {
	store := testStore(t)
	ctx := context.Background()
	a, _ := store.Create(ctx, "a", 1000)

	if got, err := store.Withdraw(ctx, a.ID, 300); err != nil || got != 700 {
		t.Fatalf("withdraw 300: got %d, %v; want 700, nil", got, err)
	}
	if _, err := store.Withdraw(ctx, a.ID, 5000); !errors.Is(err, ErrInsufficientFunds) {
		t.Fatalf("withdraw 5000: got %v, want ErrInsufficientFunds", err)
	}
	if _, err := store.Withdraw(ctx, a.ID, 0); !errors.Is(err, ErrInvalidAmount) {
		t.Fatalf("withdraw 0: got %v, want ErrInvalidAmount", err)
	}
	if _, err := store.Withdraw(ctx, 999, 10); !errors.Is(err, ErrNotFound) {
		t.Fatalf("withdraw from a missing account: got %v, want ErrNotFound", err)
	}
	after, _ := store.Get(ctx, a.ID)
	if after.BalanceCents != 700 {
		t.Fatalf("balance %d, want 700 after the failed withdrawals", after.BalanceCents)
	}
}
