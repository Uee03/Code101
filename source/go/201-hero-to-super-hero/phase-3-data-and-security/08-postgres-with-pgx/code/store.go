package main

import (
	"context"
	"errors"
	"fmt"

	"github.com/jackc/pgx/v5"
	"github.com/jackc/pgx/v5/pgconn"
	"github.com/jackc/pgx/v5/pgxpool"
)

// Errors the rest of the program can test with errors.Is, without knowing anything about Postgres.
var (
	ErrNotFound          = errors.New("account not found")
	ErrOwnerTaken        = errors.New("owner already has an account")
	ErrInsufficientFunds = errors.New("insufficient funds")
	ErrInvalidAmount     = errors.New("amount must be positive")
	ErrSameAccount       = errors.New("cannot transfer to the same account")
)

// Account maps one row. The db tags are the column names RowToStructByName matches.
type Account struct {
	ID           int    `db:"id"`
	Owner        string `db:"owner"`
	BalanceCents int64  `db:"balance_cents"`
}

// Store is the only place that knows SQL. Every method takes a context first.
type Store struct {
	pool *pgxpool.Pool
}

func NewStore(pool *pgxpool.Pool) *Store {
	return &Store{pool: pool}
}

// translate maps database errors to the sentinel errors above, using SQLSTATE codes and constraint names.
// Anything it does not recognise is returned unchanged.
func translate(err error) error {
	var pgErr *pgconn.PgError
	if !errors.As(err, &pgErr) {
		return err
	}
	switch {
	case pgErr.Code == "23505": // unique_violation
		return ErrOwnerTaken
	case pgErr.Code == "23514" && pgErr.ConstraintName == "balance_non_negative": // check_violation
		return ErrInsufficientFunds
	case pgErr.Code == "22023": // invalid_parameter_value, raised by app.deposit
		return ErrInvalidAmount
	case pgErr.Code == "P0002": // no_data_found, raised by app.deposit
		return ErrNotFound
	}
	return err
}

// Create inserts an account and returns it with the generated ID (INSERT ... RETURNING).
func (s *Store) Create(ctx context.Context, owner string, balanceCents int64) (Account, error) {
	if balanceCents < 0 {
		return Account{}, ErrInvalidAmount
	}
	acc := Account{Owner: owner, BalanceCents: balanceCents}
	err := s.pool.QueryRow(ctx,
		`INSERT INTO app.accounts (owner, balance_cents) VALUES ($1, $2) RETURNING id`,
		owner, balanceCents).Scan(&acc.ID)
	if err != nil {
		return Account{}, translate(err)
	}
	return acc, nil
}

// Get returns one account, or ErrNotFound.
func (s *Store) Get(ctx context.Context, id int) (Account, error) {
	var acc Account
	err := s.pool.QueryRow(ctx,
		`SELECT id, owner, balance_cents FROM app.accounts WHERE id = $1`, id,
	).Scan(&acc.ID, &acc.Owner, &acc.BalanceCents)
	if errors.Is(err, pgx.ErrNoRows) {
		return Account{}, ErrNotFound
	}
	if err != nil {
		return Account{}, fmt.Errorf("get account %d: %w", id, err)
	}
	return acc, nil
}

// List returns every account, ordered by ID.
func (s *Store) List(ctx context.Context) ([]Account, error) {
	rows, err := s.pool.Query(ctx, `SELECT id, owner, balance_cents FROM app.accounts ORDER BY id`)
	if err != nil {
		return nil, fmt.Errorf("list accounts: %w", err)
	}
	accounts, err := pgx.CollectRows(rows, pgx.RowToStructByName[Account])
	if err != nil {
		return nil, fmt.Errorf("list accounts: %w", err)
	}
	return accounts, nil
}

// Transfer moves money between two accounts in one transaction: both updates happen or neither does.
func (s *Store) Transfer(ctx context.Context, from, to int, amountCents int64) error {
	if amountCents <= 0 {
		return ErrInvalidAmount
	}
	if from == to {
		return ErrSameAccount
	}

	tx, err := s.pool.Begin(ctx)
	if err != nil {
		return fmt.Errorf("begin transfer: %w", err)
	}
	// After Commit this Rollback is a harmless no-op; on any early return it undoes the work.
	defer func() { _ = tx.Rollback(ctx) }()

	// Lock both rows in ID order, so two opposite transfers cannot wait for each other forever.
	tag, err := tx.Exec(ctx,
		`SELECT 1 FROM app.accounts WHERE id = ANY($1) ORDER BY id FOR UPDATE`, []int{from, to})
	if err != nil {
		return fmt.Errorf("lock accounts: %w", err)
	}
	if tag.RowsAffected() != 2 {
		return ErrNotFound
	}

	if _, err := tx.Exec(ctx,
		`UPDATE app.accounts SET balance_cents = balance_cents - $2 WHERE id = $1`, from, amountCents); err != nil {
		return translate(err)
	}
	if _, err := tx.Exec(ctx,
		`UPDATE app.accounts SET balance_cents = balance_cents + $2 WHERE id = $1`, to, amountCents); err != nil {
		return translate(err)
	}
	if err := tx.Commit(ctx); err != nil {
		return fmt.Errorf("commit transfer: %w", err)
	}
	return nil
}

// Deposit calls the stored function app.deposit and returns the new balance.
func (s *Store) Deposit(ctx context.Context, id int, amountCents int64) (int64, error) {
	var newBalance int64
	err := s.pool.QueryRow(ctx, `SELECT app.deposit($1, $2)`, id, amountCents).Scan(&newBalance)
	if err != nil {
		return 0, translate(err)
	}
	return newBalance, nil
}
