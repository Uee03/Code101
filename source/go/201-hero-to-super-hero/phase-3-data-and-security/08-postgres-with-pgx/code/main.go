package main

import (
	"context"
	"errors"
	"fmt"
	"os"
	"time"

	"github.com/jackc/pgx/v5/pgxpool"
)

func main() {
	if err := run(); err != nil {
		fmt.Fprintln(os.Stderr, "error:", err)
		os.Exit(1)
	}
}

// newPool creates a connection pool and checks that the database answers.
// The pool is safe for use by many goroutines; create it once and share it.
func newPool(ctx context.Context, url string) (*pgxpool.Pool, error) {
	cfg, err := pgxpool.ParseConfig(url)
	if err != nil {
		// Do not echo err or url: a connection string contains the password.
		return nil, errors.New("DATABASE_URL is not a valid connection string")
	}
	cfg.MaxConns = 5
	cfg.MaxConnLifetime = 30 * time.Minute
	cfg.MaxConnIdleTime = 5 * time.Minute

	pool, err := pgxpool.NewWithConfig(ctx, cfg)
	if err != nil {
		return nil, fmt.Errorf("create pool: %w", err)
	}
	if err := pool.Ping(ctx); err != nil {
		pool.Close()
		return nil, fmt.Errorf("cannot reach the database: %w", err)
	}
	return pool, nil
}

func printAccounts(ctx context.Context, store *Store) error {
	accounts, err := store.List(ctx)
	if err != nil {
		return err
	}
	for _, a := range accounts {
		fmt.Printf("%d %s %d\n", a.ID, a.Owner, a.BalanceCents)
	}
	return nil
}

func run() error {
	url := os.Getenv("DATABASE_URL")
	if url == "" {
		return errors.New("DATABASE_URL is not set (see Run it in the lesson)")
	}
	ctx, cancel := context.WithTimeout(context.Background(), 30*time.Second)
	defer cancel()

	pool, err := newPool(ctx, url)
	if err != nil {
		return err
	}
	defer pool.Close()
	store := NewStore(pool)

	var db, user string
	if err := pool.QueryRow(ctx, `SELECT current_database(), current_user`).Scan(&db, &user); err != nil {
		return fmt.Errorf("who am I: %w", err)
	}
	fmt.Printf("connected: db=%s user=%s\n", db, user)

	// The demo starts from an empty table. Never run this against a database you care about.
	if _, err := pool.Exec(ctx, `TRUNCATE app.accounts RESTART IDENTITY`); err != nil {
		return fmt.Errorf("reset demo data: %w", err)
	}

	ada, err := store.Create(ctx, "ada", 10000)
	if err != nil {
		return err
	}
	fmt.Printf("created %s (id %d) balance %d\n", ada.Owner, ada.ID, ada.BalanceCents)
	linus, err := store.Create(ctx, "linus", 2500)
	if err != nil {
		return err
	}
	fmt.Printf("created %s (id %d) balance %d\n", linus.Owner, linus.ID, linus.BalanceCents)

	if err := store.Transfer(ctx, ada.ID, linus.ID, 3000); err != nil {
		return err
	}
	fmt.Println("transfer ok")
	if err := printAccounts(ctx, store); err != nil {
		return err
	}

	fmt.Println("big transfer:", store.Transfer(ctx, ada.ID, linus.ID, 99999))
	if err := printAccounts(ctx, store); err != nil {
		return err
	}

	_, err = store.Create(ctx, "ada", 1)
	fmt.Println("duplicate owner:", err)

	balance, err := store.Deposit(ctx, ada.ID, 500)
	if err != nil {
		return err
	}
	fmt.Println("deposit ok: new balance", balance)
	_, err = store.Deposit(ctx, ada.ID, -5)
	fmt.Println("deposit rejected:", err)
	_, err = store.Deposit(ctx, 99, 100)
	fmt.Println("deposit rejected:", err)

	_, err = store.Get(ctx, 99)
	fmt.Println("get 99:", err)
	return nil
}
