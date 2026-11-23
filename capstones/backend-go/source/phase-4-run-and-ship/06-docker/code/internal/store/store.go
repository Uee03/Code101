// Package store is the data layer: every SQL statement of the service lives here.
package store

import (
	"context"
	"fmt"
	"time"

	"github.com/jackc/pgx/v5"
	"github.com/jackc/pgx/v5/pgconn"
	"github.com/jackc/pgx/v5/pgxpool"
)

// Store wraps a connection pool. It is safe for concurrent use.
type Store struct {
	pool *pgxpool.Pool
}

// querier is the part of *pgxpool.Pool and pgx.Tx that the helpers need, so one function works on both.
type querier interface {
	Query(ctx context.Context, sql string, args ...any) (pgx.Rows, error)
	QueryRow(ctx context.Context, sql string, args ...any) pgx.Row
	Exec(ctx context.Context, sql string, args ...any) (pgconn.CommandTag, error)
}

// Open builds the pool. pgxpool connects lazily, so a database that is still starting does not stop the service;
// /health reports it as down until the first connection works.
func Open(ctx context.Context, databaseURL string) (*Store, error) {
	cfg, err := pgxpool.ParseConfig(databaseURL)
	if err != nil {
		return nil, fmt.Errorf("parse DATABASE_URL: %w", err)
	}
	cfg.MaxConns = 10
	cfg.MaxConnLifetime = time.Hour
	cfg.MaxConnIdleTime = 15 * time.Minute
	cfg.HealthCheckPeriod = 30 * time.Second
	cfg.ConnConfig.ConnectTimeout = 5 * time.Second
	cfg.ConnConfig.RuntimeParams["application_name"] = "tasksteams-go"
	pool, err := pgxpool.NewWithConfig(ctx, cfg)
	if err != nil {
		return nil, fmt.Errorf("create pool: %w", err)
	}
	return &Store{pool: pool}, nil
}

// Close waits for borrowed connections to return and closes the pool.
func (s *Store) Close() { s.pool.Close() }

// Ping checks that the database answers.
func (s *Store) Ping(ctx context.Context) error { return s.pool.Ping(ctx) }

// WithUser runs fn in one transaction in which app.current_user_id is the acting user. The audit trigger of the
// schema reads that setting, so every row change made by fn is attributed to the user. The third argument of
// set_config is true: the value lasts for this transaction only and never leaks to the next pooled use of the connection.
func (s *Store) WithUser(ctx context.Context, userID string, fn func(tx pgx.Tx) error) error {
	tx, err := s.pool.BeginTx(ctx, pgx.TxOptions{})
	if err != nil {
		return mapError(err)
	}
	defer func() { _ = tx.Rollback(ctx) }() // a no-op after Commit
	if _, err := tx.Exec(ctx, "SELECT set_config('app.current_user_id', $1, true)", userID); err != nil {
		return mapError(err)
	}
	if err := fn(tx); err != nil {
		return mapError(err)
	}
	return mapError(tx.Commit(ctx))
}

// collect runs a query and scans every row into T by column position.
func collect[T any](ctx context.Context, q querier, sql string, args ...any) ([]T, error) {
	rows, err := q.Query(ctx, sql, args...)
	if err != nil {
		return nil, mapError(err)
	}
	items, err := pgx.CollectRows(rows, pgx.RowToStructByPos[T])
	return items, mapError(err)
}

// collectOne scans the first row into T; no row at all becomes a not-found error.
func collectOne[T any](ctx context.Context, q querier, sql string, args ...any) (T, error) {
	rows, err := q.Query(ctx, sql, args...)
	if err != nil {
		var zero T
		return zero, mapError(err)
	}
	item, err := pgx.CollectOneRow(rows, pgx.RowToStructByPos[T])
	return item, mapError(err)
}
