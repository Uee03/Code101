package main

import (
	"context"
	"errors"
	"os"
	"testing"
)

// testStore connects to the lesson database, or skips the test when DATABASE_URL is not set.
// It empties the accounts table: use only the disposable database from this lesson.
func testStore(t *testing.T) *Store {
	t.Helper()
	url := os.Getenv("DATABASE_URL")
	if url == "" {
		t.Skip("DATABASE_URL is not set: start the database and export it to run this test")
	}
	ctx := context.Background()
	pool, err := newPool(ctx, url)
	if err != nil {
		t.Fatalf("connect: %v", err)
	}
	t.Cleanup(pool.Close)
	if _, err := pool.Exec(ctx, `TRUNCATE app.accounts RESTART IDENTITY`); err != nil {
		t.Fatalf("reset: %v", err)
	}
	return NewStore(pool)
}

func TestTransferMovesMoney(t *testing.T) {
	store := testStore(t)
	ctx := context.Background()
	a, _ := store.Create(ctx, "a", 1000)
	b, _ := store.Create(ctx, "b", 0)

	if err := store.Transfer(ctx, a.ID, b.ID, 400); err != nil {
		t.Fatalf("transfer: %v", err)
	}
	gotA, _ := store.Get(ctx, a.ID)
	gotB, _ := store.Get(ctx, b.ID)
	if gotA.BalanceCents != 600 || gotB.BalanceCents != 400 {
		t.Fatalf("balances %d and %d, want 600 and 400", gotA.BalanceCents, gotB.BalanceCents)
	}
}

func TestFailedTransferChangesNothing(t *testing.T) {
	store := testStore(t)
	ctx := context.Background()
	a, _ := store.Create(ctx, "a", 1000)
	b, _ := store.Create(ctx, "b", 0)

	err := store.Transfer(ctx, a.ID, b.ID, 5000)
	if !errors.Is(err, ErrInsufficientFunds) {
		t.Fatalf("got %v, want ErrInsufficientFunds", err)
	}
	gotA, _ := store.Get(ctx, a.ID)
	gotB, _ := store.Get(ctx, b.ID)
	if gotA.BalanceCents != 1000 || gotB.BalanceCents != 0 {
		t.Fatalf("balances %d and %d, want 1000 and 0 after a rolled-back transfer", gotA.BalanceCents, gotB.BalanceCents)
	}
}

func TestDepositErrors(t *testing.T) {
	store := testStore(t)
	ctx := context.Background()
	a, _ := store.Create(ctx, "a", 100)

	if _, err := store.Deposit(ctx, a.ID, 0); !errors.Is(err, ErrInvalidAmount) {
		t.Fatalf("deposit 0: got %v, want ErrInvalidAmount", err)
	}
	if _, err := store.Deposit(ctx, 999, 10); !errors.Is(err, ErrNotFound) {
		t.Fatalf("deposit to missing account: got %v, want ErrNotFound", err)
	}
	if got, err := store.Deposit(ctx, a.ID, 50); err != nil || got != 150 {
		t.Fatalf("deposit 50: got %d, %v; want 150, nil", got, err)
	}
}
