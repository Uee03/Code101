---
track: go
level: 201
phase: 3
phase_name: data-and-security
lesson: 08
title: "Postgres with pgx: pool, queries, transactions and a stored function"
time: 60 min
prerequisites: [go.201.1.03, go.201.2.07]
versions: { go: "1.22.0 or newer", postgres: "17", pgx: "v5.7.2", docker: "Docker Engine with Compose v2" }
verified: not yet run
source: source/go/201-hero-to-super-hero/phase-3-data-and-security/08-postgres-with-pgx/
assets: []
---

# 08. Postgres with pgx: pool, queries, transactions and a stored function

> **Draft: written but not yet run.** The code and the expected output in this lesson were prepared by reading the code and the official documentation. They have not been executed yet. If something does not behave as described, trust your tool's real output and report it.

## What you will be able to do
By the end of this lesson you will be able to:
- run PostgreSQL 17 in Docker Compose with a `.env` file, a health check and an initialisation script;
- connect with a `pgxpool` connection pool and run parameterised queries (`QueryRow`, `Query`, `Exec`);
- write a transaction that is all-or-nothing (`Begin`, `Commit`, a deferred `Rollback`) and explain row locking;
- call a stored function and map Postgres error codes (SQLSTATE) to your own Go errors.

## Recap
1. (Lesson 03) Why does every database call take a `context.Context`?
   <details><summary>Answer</summary>So a cancelled request or a timeout stops the query instead of leaving it running for nobody.</details>
2. (Lesson 07) Where does the database password come from, and why not from code?
   <details><summary>Answer</summary>From the environment (`DATABASE_URL`), so the same code runs everywhere and no secret is committed.</details>
3. (Lesson 01) What does `errors.Is(err, ErrNotFound)` let a caller do without knowing about Postgres?
   <details><summary>Answer</summary>Handle "not found" by meaning. The store translates database details into its own error values.</details>

## Why it matters
Almost every service ends up writing to a relational database. Three things separate a toy from a service you can run: **a pool** (opening a connection per request is slow and the server has a connection limit), **parameters** (never build SQL by joining strings: that is how SQL injection happens), and **transactions** (a transfer that debits one account and fails before crediting the other would lose money). `pgx` is the most used Postgres driver for Go; it speaks the Postgres protocol directly, supports Postgres types well and includes a pool. This lesson uses a small bank-style example because money makes the need for transactions obvious.

## What you will build
A `docker-compose.yml` that starts Postgres, a schema with a table and a stored function, and a Go `Store` with five operations. A demo program exercises it and prints what happens, including a failed transfer that is rolled back.

```mermaid
flowchart LR
    subgraph Host
        APP["Go program: Store"]
        POOL["pgxpool: at most 5 connections"]
    end
    subgraph Docker
        PG[("PostgreSQL 17: schema app, table accounts, function app.deposit")]
    end
    APP --> POOL
    POOL -->|"127.0.0.1:5433 to 5432"| PG
    ENV[".env: password and port"] -.-> PG
    URL["DATABASE_URL"] -.-> APP
```

## Before you start
- **Prerequisites:** Go 201 lessons [03, sync, context and cancellation](../phase-1-core-skills/03-sync-context-cancellation.md) and [07, config, slog and shutdown](../phase-2-http-and-json/07-config-slog-shutdown.md).
- Phases 1 and 2 finished. Go 1.22.0 or newer, internet access for `go mod tidy` (it downloads `pgx`), and Docker with Compose v2 (`docker compose version` works; Docker Desktop on Windows and macOS, Docker Engine on Linux). The Docker engine must be **running**.
- Port **5433** free on your machine (the container's 5432 is published as 5433 so it does not clash with a Postgres you may already have).
- Time: 60 minutes (the first start downloads the Postgres image).
- Source pack (optional): every file is shown in full in this lesson, so you can follow without it. The finished code, the exercise starter and the solution are in the
  course repository https://github.com/Uee03/Code101 under `source/go/201-hero-to-super-hero/phase-3-data-and-security/08-postgres-with-pgx/` (on that page choose **Code, Download ZIP**, or run
  `git clone https://github.com/Uee03/Code101.git`).
- Passwords in this lesson are for a disposable local database only. Never reuse them anywhere else.

## Steps

### Step 1. Create the folder and the module
As in [lesson 01, Step 1](../phase-1-core-skills/01-interfaces-and-embedding.md#step-1-create-the-folder-and-the-module), with folder `lesson08`. Do **not** run `go mod init` yet; you will write `go.mod` yourself in Step 6 so the `pgx` version is pinned. Inside `lesson08` create a folder `db`.

### Step 2. Environment files
Compose and the Go program need a few settings. Create `.env.example` (a template you commit) and `.gitignore`:

**File: `.env.example`**
```text
# Copy this file to .env (it is ignored by git). These values are for local development only.
POSTGRES_USER=app
POSTGRES_PASSWORD=change-me-locally
POSTGRES_DB=wallet
POSTGRES_PORT=5433
# Read by the Go program, not by Compose: export it in your terminal (see the lesson).
DATABASE_URL=postgres://app:change-me-locally@127.0.0.1:5433/wallet?sslmode=disable
```
**File: `.gitignore`**
```text
.env
```

Then copy the template to a real `.env` file in `lesson08`:

PowerShell (Windows):
```powershell
Copy-Item .env.example .env
```
macOS and Linux:
```bash
cp .env.example .env
```
Compose reads `.env` from the folder you run it in. `.env` is the file you may change (it never gets committed, because `.gitignore` lists it); `.env.example` documents the keys. `POSTGRES_PORT=5433` is the *host* port. `DATABASE_URL` is read by the Go program, not by Compose.

### Step 3. The Compose file
Create `docker-compose.yml`.

**File: `docker-compose.yml`**
```yaml
# Compose file for lesson 08: one PostgreSQL 17 server for local development.
name: code101-go201-lesson08

services:
  db:
    image: postgres:17-alpine
    environment:
      POSTGRES_USER: ${POSTGRES_USER:?copy .env.example to .env first}
      POSTGRES_PASSWORD: ${POSTGRES_PASSWORD:?copy .env.example to .env first}
      POSTGRES_DB: ${POSTGRES_DB:?copy .env.example to .env first}
    ports:
      - "127.0.0.1:${POSTGRES_PORT:-5433}:5432"
    volumes:
      - pgdata:/var/lib/postgresql/data
      - ./db:/docker-entrypoint-initdb.d:ro
    healthcheck:
      test: ["CMD-SHELL", "pg_isready -U $${POSTGRES_USER} -d $${POSTGRES_DB}"]
      interval: 3s
      timeout: 3s
      retries: 20

volumes:
  pgdata:
```

Line by line:
| Line | What it does, and what happens if you change it |
|---|---|
| `name: code101-go201-lesson08` | The Compose *project* name, used to name containers, the network and the volume. Without it Compose uses the folder name |
| `image: postgres:17-alpine` | The official image, major version 17, on the small Alpine base. Pinning the major version avoids a surprise upgrade; a new major version needs a data migration |
| `POSTGRES_USER`, `POSTGRES_PASSWORD`, `POSTGRES_DB` | The image creates this user, password and database the first time it starts with an empty data folder. `${VAR:?message}` makes Compose stop with `message` if the variable is empty, instead of starting with a blank password |
| `"127.0.0.1:${POSTGRES_PORT:-5433}:5432"` | Publishes the container's port 5432 on the host, **only on the loopback address**, so other computers on your network cannot reach it. `:-5433` is a default if the variable is unset. Without `127.0.0.1` the database would be reachable from the network |
| `pgdata:/var/lib/postgresql/data` | A named volume keeps the data when the container is removed. `docker compose down -v` deletes it |
| `./db:/docker-entrypoint-initdb.d:ro` | Every `.sql` file in `db/` runs once, in name order, **only when the data volume is brand new**. `:ro` mounts it read-only |
| `healthcheck` | Runs `pg_isready` every 3 seconds. `$${...}` escapes the dollar sign so the *container's* shell expands the variable, not Compose. `--wait` (Step 5) uses this to know when the database accepts connections |
| `volumes: pgdata:` | Declares the named volume |

### Step 4. The schema and the stored function
Create `db/01-schema.sql`.

**File: `db/01-schema.sql`**
```sql
-- Runs once, when the database volume is created empty (files run in name order).
CREATE SCHEMA IF NOT EXISTS app;

CREATE TABLE app.accounts (
    id            integer GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    owner         text    NOT NULL,
    balance_cents bigint  NOT NULL DEFAULT 0,
    CONSTRAINT owner_unique UNIQUE (owner),
    CONSTRAINT owner_length CHECK (length(owner) BETWEEN 1 AND 100),
    CONSTRAINT balance_non_negative CHECK (balance_cents >= 0)
);

-- A stored function: the rule "amount must be positive" and the update live in the database.
CREATE FUNCTION app.deposit(p_account_id integer, p_amount_cents bigint)
RETURNS bigint
LANGUAGE plpgsql
AS $$
DECLARE
    new_balance bigint;
BEGIN
    IF p_amount_cents <= 0 THEN
        RAISE EXCEPTION 'amount must be positive' USING ERRCODE = '22023';
    END IF;

    UPDATE app.accounts
       SET balance_cents = balance_cents + p_amount_cents
     WHERE id = p_account_id
    RETURNING balance_cents INTO new_balance;

    IF NOT FOUND THEN
        RAISE EXCEPTION 'account % not found', p_account_id USING ERRCODE = 'P0002';
    END IF;

    RETURN new_balance;
END;
$$;
```

Why it looks like this:
- **Constraints in the database** (`UNIQUE`, `CHECK`) are the last line of defence: whatever code or person touches the table, a negative balance or a duplicate owner is refused. Naming them (`balance_non_negative`) lets the Go code recognise which rule failed.
- **`balance_cents bigint`**: money as whole cents, never floating point (you did this in Go 101 lesson 12).
- **A stored function** runs inside the database, next to the data. `app.deposit` validates the amount, updates the row and returns the new balance in one round trip. `RAISE EXCEPTION ... USING ERRCODE` attaches a SQLSTATE code, a five-character error identifier, that the Go code can read. `22023` is the standard code "invalid parameter value" and `P0002` is "no data found".
- **When to use a stored function:** logic that must be identical for every client (several services, reports, manual SQL), or that benefits from fewer round trips. **When not:** logic that changes with the application and needs normal testing, review and deployment; keep that in Go. Most code in this lesson is in Go; the function is here so you see how to call one.

### Step 5. Start the database
In `lesson08`:
```text
docker compose up -d --wait
```
`-d` runs it in the background; `--wait` returns when the health check passes. The first run downloads the image, so it takes a while. Expected output: progress lines, ending with the container reported as healthy (the exact wording depends on your Compose version, so this is a typical output, not exact):
```text
 Container code101-go201-lesson08-db-1  Healthy
```
Check the status and the logs:
```text
docker compose ps
docker compose logs db
```
`ps` lists the service `db` with a status like `Up ... (healthy)`. The logs end with the Postgres line below (typical, with other lines before it):
```text
database system is ready to accept connections
```
Check that the init script ran by counting rows in the new table, using `psql` inside the container:
```text
docker compose exec db psql -U app -d wallet -c "SELECT count(*) FROM app.accounts"
```
Typical output (psql's table formatting):
```text
 count 
-------
     0
(1 row)
```
If the table does not exist, the volume was created earlier without the script: run `docker compose down -v` and `up -d --wait` again.

### Step 6. The module
Create `go.mod` in `lesson08`.

**File: `go.mod`**
```text
module example.com/code101/go201/lesson08

go 1.22.0

require github.com/jackc/pgx/v5 v5.7.2
```

The `require` line pins `pgx` to an exact version. The libraries `pgx` itself needs are added in Step 9; do not write `go.sum` by hand.

### Step 7. The store
Create `store.go`.

**File: `store.go`**
```go
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
```

The pieces, in order of appearance:
1. **Sentinel errors and `translate`.** The rest of the program should not know about Postgres codes. `errors.As` pulls the `*pgconn.PgError` out of the error chain; its `Code` is the SQLSTATE and `ConstraintName` names the broken constraint. Mapping them to `ErrOwnerTaken`, `ErrInsufficientFunds` and so on keeps the storage details inside `Store`.
2. **Placeholders `$1`, `$2`.** Values travel separately from the SQL text, so the database never interprets them as SQL: this is what prevents SQL injection. **Never** build a query with `fmt.Sprintf` and user input. Placeholders only stand for *values*; table and column names cannot be parameters.
3. **`QueryRow(...).Scan(...)`** runs a query that returns at most one row and copies the columns into your variables, which must match in number and order. `INSERT ... RETURNING id` returns the generated key in the same round trip. When no row matches, `Scan` returns `pgx.ErrNoRows`, which `Get` turns into `ErrNotFound`.
4. **`Query` and `CollectRows`.** `Query` returns rows you must close. `pgx.CollectRows(rows, pgx.RowToStructByName[Account])` reads them all into a slice of structs and closes the rows; the `db` tags give the column names.
5. **`Transfer`.** `Begin` takes a connection from the pool and starts a transaction. Everything through `tx` runs on that one connection. `defer tx.Rollback` guarantees that any early `return` undoes the work; after `Commit` the rollback does nothing. The first statement locks both rows (`SELECT ... FOR UPDATE`) **in ID order**: if two transfers between the same accounts run in opposite directions, locking in a fixed order prevents a deadlock where each waits for the other. The debit then fails with the check violation if the balance would go negative; the credit is never reached; the deferred rollback cancels the debit.
6. **`Deposit`** calls the stored function with an ordinary `SELECT`; the function's return value is the single column.

### Step 8. The program and the tests
Create `main.go` and `store_test.go`.

**File: `main.go`**
```go
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
```
**File: `store_test.go`**
```go
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
```

Notes on `main.go`:
- **`newPool`** parses the URL, caps the pool at 5 connections (`MaxConns`), recycles old and idle connections, and `Ping`s the database so a wrong password fails now, not at the first query. The error for an invalid URL deliberately does **not** include the URL: it contains the password.
- A **pool** is shared by all goroutines. `pool.QueryRow(...).Scan(...)` borrows a connection and returns it automatically. Code that borrows explicitly (`Begin`, `Acquire`) must give it back.
- `TRUNCATE ... RESTART IDENTITY` empties the table so the demo prints the same thing every time. It is in the demo and in the tests; **never** do that in code that talks to a database you care about.
- `store_test.go` is an **integration test**: it needs a real database. When `DATABASE_URL` is not set it calls `t.Skip`, so `go test ./...` still passes on a machine without Docker.

### Step 9. Fetch the dependencies
In `lesson08`:
```text
go mod tidy
```n`go mod tidy` reads your imports, downloads `pgx` and the libraries it needs, adds them to `go.mod` as indirect requirements and **creates `go.sum`**, a file of checksums that makes later downloads verifiable. The pack does not include `go.sum` for that reason. Commit `go.sum` in your own projects.

### Step 10. Predict, then run
Before you run it, predict: (1) the balances after the first transfer; (2) the balances after the transfer of 99,999 cents; (3) what `Deposit` with -5 returns, and who raised that error, Go or Postgres.

## Run it
Set `DATABASE_URL` in the terminal you use for Go. It is the same value as in `.env.example`.

PowerShell (Windows):
```powershell
$env:DATABASE_URL = "postgres://app:change-me-locally@127.0.0.1:5433/wallet?sslmode=disable"
```
macOS and Linux:
```bash
export DATABASE_URL="postgres://app:change-me-locally@127.0.0.1:5433/wallet?sslmode=disable"
```
The URL reads: user `app`, password `change-me-locally`, host `127.0.0.1`, port `5433`, database `wallet`. `sslmode=disable` turns off TLS, acceptable only for a database on your own machine; for any remote database use `sslmode=verify-full`.

In `lesson08`:
```text
go run .
```
Expected output (derived by reading the code, not yet run):
```text
connected: db=wallet user=app
created ada (id 1) balance 10000
created linus (id 2) balance 2500
transfer ok
1 ada 7000
2 linus 5500
big transfer: insufficient funds
1 ada 7000
2 linus 5500
duplicate owner: owner already has an account
deposit ok: new balance 7500
deposit rejected: amount must be positive
deposit rejected: account not found
get 99: account not found
```
Run the tests (they use the same `DATABASE_URL`; they empty the table):
```text
go test ./...
```
It should end with a line starting `ok`. Without `DATABASE_URL` the database tests are skipped; `go test -v ./...` shows `--- SKIP:` for them.

Stop and clean up when you are done:
```text
docker compose down
```
That removes the container and keeps the data. `docker compose down -v` also deletes the volume (use it to start from scratch).

## How it works
1. `newPool` opens up to five connections lazily and checks one. Every `Store` method borrows a connection for the duration of one call and returns it.
2. The first transfer moves 3,000 cents inside one transaction: `ada` 10,000 to 7,000 and `linus` 2,500 to 5,500, committed together.
3. The second transfer asks for 99,999 cents. The `UPDATE` that subtracts it would leave `ada` below zero, so Postgres raises error `23514` with constraint `balance_non_negative`. `translate` returns `ErrInsufficientFunds`. The deferred rollback ends the transaction, so the list shows 7,000 and 5,500 again: **nothing was applied**.
4. Creating `ada` twice violates `owner_unique` (error `23505`), mapped to `ErrOwnerTaken`.
5. `Deposit(-5)` is rejected by **Postgres**: the function raises `22023`; Go only translated it. `Deposit(99, ...)` raises `P0002`, mapped to `ErrNotFound`.

**Misconception:** "the pool is slow or complicated, I will open one connection". A single connection serves one query at a time, so concurrent requests would queue or race on it. The pool is how a web server serves many requests with a bounded number of database connections.

## Why this, not that
| Choice | Use | Instead of | Reason |
|---|---|---|---|
| Driver | `pgx` (native interface) | `database/sql` with pgx as driver | Richer Postgres types, `CollectRows`, `CopyFrom`, batches. Use `database/sql` only if a library requires it |
| Queries | Hand-written SQL in a `Store` | An ORM | You see exactly what runs; fewer surprises. A code generator (`sqlc`) gives you typed Go from SQL files if you want more help |
| Pool | `pgxpool` | A new connection per request | Postgres has a connection limit; connecting is slow |
| Business rule | Constraint in the table | Only an `if` in Go | The database refuses bad data from every client |
| Multi-step change | Transaction | Separate statements | All-or-nothing |
| Lock order | `ORDER BY id FOR UPDATE` | Locking in argument order | Prevents deadlocks between opposite transfers |
| Local database | Compose with a volume | Installing Postgres on the host | Reproducible; deleted with one command |
| Money | Integer cents | `float64` | Exact arithmetic |

## Try it
This exercise adds to your lesson folder instead of starting a new program. Copy the whole `lesson08` folder to a new folder `try08` beside it (copy the folder, rename the copy `try08`; do not put it inside `lesson08`). Keep your `.env` file in it. Then add the three files from `exercise/starter` into `try08` (the `db` folder first, then the two `.go` files). The starter files are shown below.

1. **Guided.** Write the SQL function `app.withdraw` in `db/02-withdraw.sql`, the mirror image of `deposit`.
2. **Change.** Write `Store.Withdraw` in `withdraw.go`: it calls the function and returns the new balance with the same error mapping as `Deposit`. A test file is given and already describes the behaviour, including what must happen when the balance is too small.
3. **Stretch (no single answer).** `Transfer` is written in Go. Would you move it into a stored function `app.transfer`? List one gain and one cost (think about testing, versioning, who can change it, how many round trips).

**File: `db/02-withdraw.sql (starter)`**
```sql
-- TODO 1: create the function app.withdraw(p_account_id integer, p_amount_cents bigint) RETURNS bigint.
-- It behaves like app.deposit, but subtracts: reject an amount of zero or less with SQLSTATE 22023,
-- raise SQLSTATE P0002 when the account does not exist, and return the new balance.
-- Do not write your own overdraft check: the table's CHECK constraint already refuses a negative balance.
```
**File: `withdraw.go (starter)`**
```go
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
```
**File: `withdraw_test.go (starter)`**
```go
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
```

Init scripts only run on a **new** volume, so after you write the SQL, recreate the database. In `try08`:
```text
docker compose down -v
docker compose up -d --wait
```
Then, with `DATABASE_URL` set, run:
```text
go mod tidy
go test ./...
```
With the starter's stub, the test fails at the first check (the message names the call): `withdraw 300: got 0, not implemented; want 700, nil`. When you are finished the last line starts with `ok`.

<details><summary>Solution</summary>

Replace the two starter files in `try08` (the test file is unchanged):

**File: `db/02-withdraw.sql (solution)`**
```sql
CREATE FUNCTION app.withdraw(p_account_id integer, p_amount_cents bigint)
RETURNS bigint
LANGUAGE plpgsql
AS $$
DECLARE
    new_balance bigint;
BEGIN
    IF p_amount_cents <= 0 THEN
        RAISE EXCEPTION 'amount must be positive' USING ERRCODE = '22023';
    END IF;

    UPDATE app.accounts
       SET balance_cents = balance_cents - p_amount_cents
     WHERE id = p_account_id
    RETURNING balance_cents INTO new_balance;

    IF NOT FOUND THEN
        RAISE EXCEPTION 'account % not found', p_account_id USING ERRCODE = 'P0002';
    END IF;

    RETURN new_balance;
END;
$$;
```
**File: `withdraw.go (solution)`**
```go
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
```

`withdraw` does not check the balance: the `CHECK (balance_cents >= 0)` constraint does, and `translate` already maps it. One rule in one place.

Stretch: moving `Transfer` into the database saves round trips and makes the rule available to every client, but the logic then lives in SQL: harder to unit-test, versioned through migrations rather than your normal release, and visible to fewer reviewers.

</details>

## Check yourself
1. Why must `Transfer` use `defer tx.Rollback(ctx)` even though it calls `Commit`?
   <details><summary>Answer</summary>Any early return or panic before `Commit` would otherwise leave the transaction open. After a successful `Commit`, the rollback does nothing.</details>
2. What is wrong with `fmt.Sprintf("SELECT ... WHERE owner = '%s'", owner)`?
   <details><summary>Answer</summary>It is SQL injection: the value becomes part of the SQL. Use a placeholder (`$1`) and pass the value as an argument.</details>
3. Why is the `docker-compose.yml` port written as `127.0.0.1:5433:5432`?
   <details><summary>Answer</summary>It publishes the database only on the loopback interface, so other machines cannot connect to it.</details>
4. After the failed 99,999-cent transfer, what are the balances, and why?
   <details><summary>Answer</summary>Unchanged (7,000 and 5,500). The debit hit the check constraint, and the deferred rollback discarded the transaction.</details>
5. Find the bug: after changing `POSTGRES_PASSWORD` in `.env` the old password still works.
   <details><summary>Answer</summary>The password is set only when the data volume is created. Run `docker compose down -v` and start again (this deletes the data).</details>

## Common mistakes
These are typical messages unless the text comes from this lesson's own code; Docker, Compose and pgx wording changes between versions.

| Symptom or error text | Cause | Fix |
|---|---|---|
| `error: DATABASE_URL is not set (see Run it in the lesson)` | The variable is not set in this terminal | Set it as shown in Run it; each new terminal needs it again |
| `required variable POSTGRES_PASSWORD is missing a value: copy .env.example to .env first` (typical message) | No `.env` file in the folder where you ran `docker compose` | Copy `.env.example` to `.env` (Step 2) |
| `error: cannot reach the database: ...` with a connection refused or timeout text | The container is not running or not healthy, or the port or password in the URL is wrong | `docker compose ps`; compare the port and password with `.env` |
| `missing go.sum entry for module providing package github.com/jackc/pgx/v5` (typical message) | `go.sum` does not exist yet | Run `go mod tidy` |
| A "Cannot connect to the Docker daemon" or similar message (typical message) | The Docker engine is not running | Start Docker Desktop (or the Docker service) and wait until it is ready |
| Port is already allocated (typical message) | Something else uses port 5433 | Change `POSTGRES_PORT` and the port in `DATABASE_URL`, then `docker compose up -d --wait` again |
| `relation "app.accounts" does not exist` (typical message) | The init script did not run: the volume existed before the script | `docker compose down -v` and `up -d --wait` |
| Tests print `SKIP` | `DATABASE_URL` is not set | Set it and run `go test -v ./...` |

## Best practice
Use a connection pool, pass values as parameters, wrap multi-step changes in a transaction with a deferred rollback, keep the rules that must always hold as database constraints, and translate driver errors at the boundary of your store. Source: pgx documentation https://pkg.go.dev/github.com/jackc/pgx/v5, pgxpool https://pkg.go.dev/github.com/jackc/pgx/v5/pgxpool, PostgreSQL error codes https://www.postgresql.org/docs/17/errcodes-appendix.html and OWASP SQL Injection Prevention Cheat Sheet https://cheatsheetseries.owasp.org/cheatsheets/SQL_Injection_Prevention_Cheat_Sheet.html

## Going further
- Postgres in depth (indexes, migrations, roles) is in the Databases track; the capstone shows a full store layer with stored functions, an audit trail and idempotency keys: [`capstones/backend-go`, data chapters](../../../../capstones/backend-go/tutorials/phase-2-data/02-store-and-teams.md).
- Batch work: `pgx.Batch` and `CopyFrom`: https://pkg.go.dev/github.com/jackc/pgx/v5#Batch
- Next lesson, 09, protects an API with token authentication.

## Summary
- You ran Postgres 17 in Compose with a `.env` file, a loopback-only port, a volume, init scripts and a health check.
- You used a `pgxpool` pool and parameterised `QueryRow`, `Query` and `Exec` calls.
- You wrote an atomic transfer with a deferred rollback and ordered row locks, and saw a failed one leave the data unchanged.
- You called a stored function and mapped SQLSTATE codes and constraint names to Go errors.

## Next lesson
**[09. Authentication middleware (JWT basics)](09-auth-middleware-jwt.md):** protect routes by validating bearer tokens in middleware.
