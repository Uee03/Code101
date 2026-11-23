---
track: capstone
level: 201
phase: 2
phase_name: data
lesson: 02
title: "The data layer: pgx, the store, teams, members and projects"
time: 120 min
prerequisites: [capstone-backend-go-01, databases-101]
versions: { go: "1.27.4", pgx: "v5.13.0", postgres_image: "17-alpine" }
verified: 2026-11-23 on Windows 11, Go 1.27.4, Docker 29.9.3, Compose 5.7.0, curl 8.22.0
source: capstones/backend-go/source/phase-2-data/02-store-and-teams/
assets: []
---

# 02. The data layer: pgx, the store, teams, members and projects

## Why it matters
Think of a library. Visitors talk to the front desk (the HTTP layer); only the librarians behind the desk walk into the stacks (the database). If every visitor could wander into the stacks, one wrong turn would damage a book and nobody could tell who did it. The `store` package is the stacks door: it holds every SQL statement, it is the only code that knows table names, and every change it makes is signed with the name of the person who asked.

## What you will build
- A `pgxpool` connection pool and a `store` package with typed queries, keyset pagination and error mapping from Postgres to the API.
- Write transactions that set `app.current_user_id` so the database's audit trigger records the right actor.
- Team, member, project and user endpoints with ETag and `If-Match`, JSON Merge Patch, filtering and cursor pagination.
- Team authorization (member, lead, admin, and 404 for strangers).
- A **development stand-in for sign-in** (`X-Dev-User` headers) so you can test who-may-do-what before Keycloak arrives in chapter 05. It is removed there.

Conformance after this chapter (real run): **6 passed, 12 failed**. The failing checks all need a bearer token, which this build does not understand yet.

## Before you start
- Chapter 01 done, or unzip `backend-go-phase-2-data.zip` and open `02-store-and-teams/code` (every phase pack holds the whole project at that point).
- Docker running; host port 5432 free (stop other Postgres labs). The platform's Compose file starts the database.
- `curl` (PowerShell: `curl.exe`).

## Steps
### Step 1. Bring the platform files into the project
The database schema, the seed data, the Keycloak realm, the Compose file and the conformance script belong to the **platform** capstone. This project never edits them. Copy them from `capstones/platform/source/phase-4-conformance/04-conformance-script/code` into your project, keeping the relative paths:

```text
tasksteams-go/
  docker-compose.yml          platform file, byte-identical
  .env.example                platform file, byte-identical
  db/schema.sql, db/seed.sql  platform files, byte-identical
  keycloak/realm-tasksteams.json   platform file (used from chapter 05)
  scripts/conformance.py      platform file (used from chapter 05)
```
Copy in a terminal (PowerShell; folder `tasksteams-go`; replace the source path with yours):
```powershell
$p = "..\path\to\capstones\platform\source\phase-4-conformance\04-conformance-script\code"
New-Item -ItemType Directory -Force db, keycloak, scripts | Out-Null
Copy-Item "$p\docker-compose.yml", "$p\.env.example" .
Copy-Item "$p\db\schema.sql", "$p\db\seed.sql" db
Copy-Item "$p\keycloak\realm-tasksteams.json" keycloak
Copy-Item "$p\scripts\conformance.py" scripts
```
macOS or Linux: `mkdir -p db keycloak scripts && cp $p/docker-compose.yml $p/.env.example . && cp $p/db/schema.sql $p/db/seed.sql db/ && cp $p/keycloak/realm-tasksteams.json keycloak/ && cp $p/scripts/conformance.py scripts/` with `p=../path/to/...`.

`schema.sql`, `seed.sql`, the realm file and `conformance.py` are explained line by line in the platform chapters 02, 03 and 04 and are not repeated here. The Compose file and the `.env.example` are what you start with, so here they are in full:

**File: `docker-compose.yml`**
```yaml
services:
  db:
    image: postgres:17-alpine
    environment:
      POSTGRES_DB: ${POSTGRES_DB}
      POSTGRES_USER: ${POSTGRES_USER}
      POSTGRES_PASSWORD: ${POSTGRES_PASSWORD}
    ports:
      - "127.0.0.1:${POSTGRES_PORT:-5432}:5432"
    volumes:
      - pg_data:/var/lib/postgresql/data
      - ./db/schema.sql:/docker-entrypoint-initdb.d/01-schema.sql:ro
      - ./db/seed.sql:/docker-entrypoint-initdb.d/02-seed.sql:ro
      - ./db:/scripts:ro
    healthcheck:
      test: ["CMD-SHELL", "pg_isready -h 127.0.0.1 -U $$POSTGRES_USER -d $$POSTGRES_DB"]
      interval: 3s
      timeout: 3s
      retries: 30
      start_period: 5s
    networks:
      - tasksteams
  keycloak:
    image: quay.io/keycloak/keycloak:26.8.2
    command: ["start-dev", "--import-realm"]
    environment:
      KC_BOOTSTRAP_ADMIN_USERNAME: ${KEYCLOAK_ADMIN}
      KC_BOOTSTRAP_ADMIN_PASSWORD: ${KEYCLOAK_ADMIN_PASSWORD}
      KC_HOSTNAME: http://localhost:${KEYCLOAK_PORT:-8180}
      KC_HOSTNAME_BACKCHANNEL_DYNAMIC: "true"
      KC_HEALTH_ENABLED: "true"
    ports:
      - "127.0.0.1:${KEYCLOAK_PORT:-8180}:8080"
    volumes:
      - ./keycloak/realm-tasksteams.json:/opt/keycloak/data/import/realm-tasksteams.json:ro
    healthcheck:
      test: ["CMD", "bash", "-c", "exec 3<>/dev/tcp/127.0.0.1/9000 && printf 'GET /health/ready HTTP/1.1\\r\\nHost: localhost\\r\\nConnection: close\\r\\n\\r\\n' >&3 && grep -q UP <&3"]
      interval: 5s
      timeout: 5s
      retries: 60
      start_period: 30s
    networks:
      - tasksteams
networks:
  tasksteams:
    name: ${TASKS_NETWORK:-tasksteams-net}
volumes:
  pg_data:
```
- `db` is `postgres:17-alpine`. The two `.sql` files are mounted into `/docker-entrypoint-initdb.d`, which the image runs **once**, on an empty data directory, in file-name order: schema first, then seed. That is why a changed schema needs `down -v` (delete the volume) before the next start.
- `ports: "127.0.0.1:5432:5432"` publishes the database on your own machine only; with a plain `5432:5432` every computer on your network could try to log in.
- The `healthcheck` runs `pg_isready` every 3 seconds; `up --wait` returns when the container is healthy.
- `keycloak` is used from chapter 05; the `networks` block names the network `tasksteams-net`, which the API container joins in chapter 06.

**File: `.env.example`**
```text
# Disposable local practice only. Never reuse these values for a real system.
POSTGRES_DB=tasksteams
POSTGRES_USER=tasks_admin
POSTGRES_PASSWORD=tasks_admin_local_only
POSTGRES_PORT=5432
KEYCLOAK_ADMIN=kcadmin
KEYCLOAK_ADMIN_PASSWORD=kcadmin_local_only
KEYCLOAK_PORT=8180
TASKS_NETWORK=tasksteams-net
```
Compose reads a file called `.env` next to the Compose file. The repository keeps only `.env.example` (fake, disposable values) and ignores `.env`, so a real secret can never be committed by accident. Create your copy:
```bash
cp .env.example .env
```
(PowerShell: `Copy-Item .env.example .env`.)

### Step 2. Start the database
```bash
docker compose -p tasksteams up -d --wait db
```
`-p tasksteams` names the Compose project (it prefixes container, network and volume names), `up -d` starts in the background, `--wait` returns when the health check passes, and `db` starts only that service. Expected:
```text
 Container tasksteams-db-1 Starting
 Container tasksteams-db-1 Started
 Container tasksteams-db-1 Waiting
 Container tasksteams-db-1 Healthy
```
Check that the seed ran (the three users alice, bob, carol):
```bash
docker compose -p tasksteams exec -T db psql -U tasks_admin -d tasksteams -tA -c "SELECT count(*) FROM users"
```
```text
3
```
To read the database logs use `docker compose -p tasksteams logs db`; to stop and delete everything use `docker compose -p tasksteams down -v --remove-orphans`.

### Step 3. Add the driver
```bash
go get github.com/jackc/pgx/v5@v5.13.0
```
**pgx** is the PostgreSQL driver. Version 5 has a native interface (`pgxpool` for the connection pool, typed scanning, batch support) and also plugs into `database/sql`; this project uses the native one. Resolve the dependencies:
```bash
go mod tidy
```
**File: `go.mod`**
```text
module example.com/tasksteams

go 1.27.4

require github.com/jackc/pgx/v5 v5.13.0

require (
	github.com/jackc/pgpassfile v1.0.0 // indirect
	github.com/jackc/pgservicefile v0.0.0-20240606120523-5a60cdf6a761 // indirect
	github.com/jackc/puddle/v2 v2.2.3 // indirect
	golang.org/x/sync v0.22.0 // indirect
	golang.org/x/text v0.41.0 // indirect
)
```
`// indirect` marks modules that pgx needs but your code does not import. `go.sum` holds the cryptographic hashes of every module version; Go checks them against its checksum database, so a tampered download fails. `go.sum` is generated, never edited and not reproduced here (it is excluded from the text check, with `go.mod` shown in full).

### Step 4. The store
Everything below lives in `internal/store`. Create the folder: `mkdir -p internal/store internal/auth`.

**Errors.** The HTTP layer must not know Postgres error codes. The platform's stored functions raise four custom SQLSTATEs (`TS404` not found, `TS409` rule violated, `TS412` stale version, `TS422` invalid input) and the constraints raise standard ones (`23505` unique violation, `23503` foreign key, `23514` check). `mapError` is the one place that translates them into a small `*Error` with a `Kind`.

**File: `internal/store/errors.go`**
```go
package store

import (
	"errors"
	"fmt"

	"github.com/jackc/pgx/v5"
	"github.com/jackc/pgx/v5/pgconn"
)

// Kind says which problem type the HTTP layer should answer with.
type Kind int

const (
	KindNotFound  Kind = iota + 1 // 404
	KindConflict                  // 409
	KindStale                     // 412
	KindInvalid                   // 422
	KindBadCursor                 // 400
)

// Error is the only error type the HTTP layer needs to understand. Anything else is a 500.
type Error struct {
	Kind    Kind
	Message string
	Code    string // optional machine-readable code, for example last_lead
}

func (e *Error) Error() string { return e.Message }

func notFound(what string) *Error { return &Error{Kind: KindNotFound, Message: what + " not found."} }

func stale(current int) *Error {
	return &Error{Kind: KindStale, Message: fmt.Sprintf("The resource changed since you read it (current version %d).", current)}
}

// ErrBadCursor is returned when a cursor cannot be decoded.
var ErrBadCursor = &Error{Kind: KindBadCursor, Message: "The cursor is not valid."}

// conflictMessages names the unique constraints a client can run into.
var conflictMessages = map[string]string{
	"teams_name_key":           "A team with this name already exists.",
	"projects_team_id_key_key": "A project with this key already exists in the team.",
}

// mapError translates a pgx error into a store.Error. The functions of the schema raise custom SQLSTATE codes
// (TS404, TS409, TS412, TS422) and the constraints raise the standard ones.
func mapError(err error) error {
	if err == nil {
		return nil
	}
	var known *Error
	if errors.As(err, &known) {
		return err
	}
	if errors.Is(err, pgx.ErrNoRows) {
		return &Error{Kind: KindNotFound, Message: "Not found."}
	}
	var pgErr *pgconn.PgError
	if !errors.As(err, &pgErr) {
		return err
	}
	switch pgErr.Code {
	case "TS404":
		return &Error{Kind: KindNotFound, Message: pgErr.Message}
	case "TS409":
		return &Error{Kind: KindConflict, Message: pgErr.Message}
	case "TS412":
		return &Error{Kind: KindStale, Message: pgErr.Message}
	case "TS422":
		return &Error{Kind: KindInvalid, Message: pgErr.Message}
	case "23505": // unique_violation
		message, ok := conflictMessages[pgErr.ConstraintName]
		if !ok {
			message = "A resource with the same unique value already exists."
		}
		return &Error{Kind: KindConflict, Message: message}
	case "23503": // foreign_key_violation
		return &Error{Kind: KindInvalid, Message: "A referenced resource does not exist."}
	case "23514": // check_violation
		return &Error{Kind: KindInvalid, Message: "A value is outside the allowed range."}
	}
	return err
}
```
**The pool, the transaction helper and two generic scan helpers.**

**File: `internal/store/store.go`**
```go
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
```
- `pgxpool.ParseConfig` reads the URL; the pool settings are explicit: at most 10 connections, a connection lives at most an hour, is closed after 15 idle minutes and is health-checked every 30 seconds. `application_name` shows up in `pg_stat_activity`, which helps when you look for the culprit of a slow query.
- The pool **connects lazily**: `Open` succeeds even while the database is still starting, and `/health` reports the truth (`503 degraded`) until the first connection works.
- `WithUser` is the heart of the design. It opens a transaction, runs `SELECT set_config('app.current_user_id', $1, true)` and then your function. The third argument `true` means "local to this transaction": the value disappears at commit or rollback, so a pooled connection never carries one user's id into another request. The schema's audit trigger reads this setting, so **every row change in the transaction is attributed to the user**.
- `defer tx.Rollback(ctx)` is the Go idiom for "undo unless committed": after `Commit` the rollback is a harmless no-op, after an early `return err` it undoes the work.
- `collect` and `collectOne` use **generics** (`[T any]`): one function scans rows into any struct, by column position (`pgx.RowToStructByPos`). The column order of each query must therefore match the field order of its struct; the store files keep the column list and the struct side by side for that reason.

**Pagination, the query builder and LIKE patterns.**

**File: `internal/store/page.go`**
```go
package store

import (
	"encoding/base64"
	"encoding/json"
	"fmt"
	"regexp"
	"strconv"
	"strings"
	"time"
)

// PageParams is what the HTTP layer asks for: a page size and the opaque cursor of the previous page.
type PageParams struct {
	Limit  int
	Cursor string
}

// Page is one page of items and the cursor of the next page (empty on the last page).
type Page[T any] struct {
	Items      []T
	NextCursor string
}

// Cursor is the decoded keyset position of the last item of a page: the sort value and the id that breaks ties.
// Clients only ever see the base64url text, never these fields.
type Cursor struct {
	Sort string    `json:"s"`
	Time time.Time `json:"t,omitzero"`
	Due  string    `json:"d,omitempty"`
	ID   string    `json:"i"`
}

func encodeCursor(c Cursor) string {
	c.Time = c.Time.UTC()
	raw, _ := json.Marshal(c) // a struct of strings and a time cannot fail to encode
	return base64.RawURLEncoding.EncodeToString(raw)
}

var uuidPattern = regexp.MustCompile(`^[0-9a-fA-F]{8}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{12}$`)

func uuidID(s string) bool { return uuidPattern.MatchString(s) }

func numberID(s string) bool {
	_, err := strconv.ParseInt(s, 10, 64)
	return err == nil
}

// decodeCursor returns nil for an empty cursor. A cursor made for another sort order or with a malformed id is
// rejected, so a client cannot turn a cursor into a SQL error.
func decodeCursor(raw, sort string, validID func(string) bool) (*Cursor, error) {
	if raw == "" {
		return nil, nil
	}
	data, err := base64.RawURLEncoding.DecodeString(raw)
	if err != nil {
		return nil, ErrBadCursor
	}
	var c Cursor
	if err := json.Unmarshal(data, &c); err != nil || c.Sort != sort || !validID(c.ID) {
		return nil, ErrBadCursor
	}
	if c.Due != "" {
		if _, err := time.Parse(time.DateOnly, c.Due); err != nil {
			return nil, ErrBadCursor
		}
	}
	return &c, nil
}

// finishPage expects limit+1 rows: the extra row only proves that another page exists.
func finishPage[T any](items []T, limit int, cursorOf func(T) Cursor) Page[T] {
	if len(items) <= limit {
		return Page[T]{Items: items}
	}
	items = items[:limit]
	return Page[T]{Items: items, NextCursor: encodeCursor(cursorOf(items[limit-1]))}
}

// builder collects WHERE conditions and their parameters. Values never go into the SQL text, only placeholders do.
type builder struct {
	conds []string
	args  []any
}

// arg stores a value and returns its placeholder, for example "$3".
func (b *builder) arg(value any) string {
	b.args = append(b.args, value)
	return "$" + strconv.Itoa(len(b.args))
}

func (b *builder) where(condition string) { b.conds = append(b.conds, condition) }

func (b *builder) whereSQL() string {
	if len(b.conds) == 0 {
		return ""
	}
	return " WHERE " + strings.Join(b.conds, " AND ")
}

// afterTime adds the keyset condition "rows after the cursor" for ORDER BY timeCol, idCol.
func (b *builder) afterTime(timeCol, idCol string, desc bool, c *Cursor) {
	if c == nil {
		return
	}
	op := ">"
	if desc {
		op = "<"
	}
	b.where(fmt.Sprintf("(%s, %s) %s (%s, %s)", timeCol, idCol, op, b.arg(c.Time), b.arg(c.ID)))
}

func orderBy(timeCol, idCol string, desc bool) string {
	if desc {
		return fmt.Sprintf(" ORDER BY %s DESC, %s DESC", timeCol, idCol)
	}
	return fmt.Sprintf(" ORDER BY %s, %s", timeCol, idCol)
}

var likeEscaper = strings.NewReplacer(`\`, `\\`, `%`, `\%`, `_`, `\_`)

// likePrefix makes the pattern for "starts with, ignoring case". User input cannot add wildcards.
func likePrefix(s string) string { return likeEscaper.Replace(strings.ToLower(s)) + "%" }

// likeContains makes the pattern for "contains".
func likeContains(s string) string { return "%" + likeEscaper.Replace(s) + "%" }
```
**Keyset pagination** instead of `OFFSET`: the cursor holds the sort value and the id of the last row (`(created_at, id)`), and the next page asks for rows *after* that pair, `WHERE (created_at, id) < ($1, $2)`. It stays correct while rows are inserted, and it is fast on the `(created_at DESC, id DESC)` indexes because Postgres seeks instead of counting and skipping rows. The price: no "jump to page 7". The cursor is base64url of a small JSON document and carries the sort name, so a cursor made for one list cannot be replayed on another. The store asks for `limit + 1` rows; the extra row only proves that a next page exists. `builder` collects `WHERE` conditions and parameters; values never enter the SQL text, only `$1`-style placeholders do, which is what stops SQL injection. `likePrefix` escapes `\`, `%` and `_`, so a user cannot smuggle wildcards into a search.

**Users, teams, members, projects.**

**File: `internal/store/users.go`**
```go
package store

import (
	"context"
	"time"
)

// User is a row of the users table. Its id is the Keycloak sub claim.
type User struct {
	ID          string
	Username    string
	Email       string
	DisplayName string
	CreatedAt   time.Time
}

const userColumns = "u.id, u.username, u.email, u.display_name, u.created_at"

// GetUser returns the user or a not-found error.
func (s *Store) GetUser(ctx context.Context, id string) (User, error) {
	return collectOne[User](ctx, s.pool, "SELECT "+userColumns+" FROM users u WHERE u.id = $1", id)
}

// ListUsers returns users whose username or display name starts with prefix, oldest first.
func (s *Store) ListUsers(ctx context.Context, prefix string, page PageParams) (Page[User], error) {
	cursor, err := decodeCursor(page.Cursor, "users", uuidID)
	if err != nil {
		return Page[User]{}, err
	}
	var b builder
	if prefix != "" {
		pattern := b.arg(likePrefix(prefix))
		b.where("(lower(u.username) LIKE " + pattern + " OR lower(u.display_name) LIKE " + pattern + ")")
	}
	b.afterTime("u.created_at", "u.id", false, cursor)
	sql := "SELECT " + userColumns + " FROM users u" + b.whereSQL() + orderBy("u.created_at", "u.id", false) +
		" LIMIT " + b.arg(page.Limit+1)
	items, err := collect[User](ctx, s.pool, sql, b.args...)
	if err != nil {
		return Page[User]{}, err
	}
	return finishPage(items, page.Limit, func(u User) Cursor {
		return Cursor{Sort: "users", Time: u.CreatedAt, ID: u.ID}
	}), nil
}

// MyTeam is one membership of a user.
type MyTeam struct {
	TeamID string
	Name   string
	Role   string
}

// UserTeams lists the teams a user belongs to, by name.
func (s *Store) UserTeams(ctx context.Context, userID string) ([]MyTeam, error) {
	return collect[MyTeam](ctx, s.pool, `SELECT m.team_id, t.name, m.role
		FROM team_members m JOIN teams t ON t.id = m.team_id
		WHERE m.user_id = $1 ORDER BY lower(t.name), t.id`, userID)
}
```
**File: `internal/store/teams.go`**
```go
package store

import (
	"context"
	"errors"
	"time"

	"github.com/jackc/pgx/v5"
)

// Team is a row of the teams table plus its member count.
type Team struct {
	ID          string
	Name        string
	Description string
	MemberCount int
	CreatedBy   string
	Version     int
	CreatedAt   time.Time
	UpdatedAt   time.Time
}

const teamColumns = `t.id, t.name, t.description, (SELECT count(*) FROM team_members m WHERE m.team_id = t.id),
	t.created_by, t.version, t.created_at, t.updated_at`

// TeamAccess says whether a team exists and which role the user has in it ("" when the user is not a member).
type TeamAccess struct {
	Exists bool
	Role   string
}

// TeamAccess answers both questions the authorization rules need with one query.
func (s *Store) TeamAccess(ctx context.Context, teamID, userID string) (TeamAccess, error) {
	var role *string
	err := s.pool.QueryRow(ctx,
		`SELECT m.role FROM teams t LEFT JOIN team_members m ON m.team_id = t.id AND m.user_id = $2 WHERE t.id = $1`,
		teamID, userID).Scan(&role)
	if errors.Is(err, pgx.ErrNoRows) {
		return TeamAccess{}, nil
	}
	if err != nil {
		return TeamAccess{}, mapError(err)
	}
	access := TeamAccess{Exists: true}
	if role != nil {
		access.Role = *role
	}
	return access, nil
}

func (s *Store) GetTeam(ctx context.Context, id string) (Team, error) {
	team, err := collectOne[Team](ctx, s.pool, "SELECT "+teamColumns+" FROM teams t WHERE t.id = $1", id)
	if err != nil {
		return Team{}, translateNoRows(err, "Team")
	}
	return team, nil
}

// TeamFilter describes the list of teams a caller may see.
type TeamFilter struct {
	UserID string // the caller
	All    bool   // true for admins: every team, not only the caller's
	Prefix string // case-insensitive start of the name
	Desc   bool   // newest first
	Page   PageParams
}

func (s *Store) ListTeams(ctx context.Context, f TeamFilter) (Page[Team], error) {
	sort := "createdAt"
	if f.Desc {
		sort = "-createdAt"
	}
	cursor, err := decodeCursor(f.Page.Cursor, "teams:"+sort, uuidID)
	if err != nil {
		return Page[Team]{}, err
	}
	var b builder
	if !f.All {
		b.where("EXISTS (SELECT 1 FROM team_members mm WHERE mm.team_id = t.id AND mm.user_id = " + b.arg(f.UserID) + ")")
	}
	if f.Prefix != "" {
		b.where("lower(t.name) LIKE " + b.arg(likePrefix(f.Prefix)))
	}
	b.afterTime("t.created_at", "t.id", f.Desc, cursor)
	sql := "SELECT " + teamColumns + " FROM teams t" + b.whereSQL() + orderBy("t.created_at", "t.id", f.Desc) +
		" LIMIT " + b.arg(f.Page.Limit+1)
	items, err := collect[Team](ctx, s.pool, sql, b.args...)
	if err != nil {
		return Page[Team]{}, err
	}
	return finishPage(items, f.Page.Limit, func(t Team) Cursor {
		return Cursor{Sort: "teams:" + sort, Time: t.CreatedAt, ID: t.ID}
	}), nil
}

// CreateTeam calls the create_team stored function: it inserts the team and its first lead in one step.
func (s *Store) CreateTeam(ctx context.Context, actorID, leadID, name, description string) (Team, error) {
	var team Team
	err := s.WithUser(ctx, actorID, func(tx pgx.Tx) error {
		var id string
		if err := tx.QueryRow(ctx, "SELECT id FROM create_team($1, $2, $3, $4)", name, description, leadID, actorID).Scan(&id); err != nil {
			return err
		}
		var err error
		team, err = collectOne[Team](ctx, tx, "SELECT "+teamColumns+" FROM teams t WHERE t.id = $1", id)
		return err
	})
	return team, err
}

// TeamPatch holds the fields a JSON Merge Patch may change; nil means "leave as it is".
type TeamPatch struct {
	Name        *string
	Description *string
}

// UpdateTeam changes a team if its version is still expected (0 skips the check).
func (s *Store) UpdateTeam(ctx context.Context, actorID, id string, expected int, patch TeamPatch) (Team, error) {
	var team Team
	err := s.WithUser(ctx, actorID, func(tx pgx.Tx) error {
		current, err := collectOne[Team](ctx, tx, "SELECT "+teamColumns+" FROM teams t WHERE t.id = $1 FOR UPDATE OF t", id)
		if err != nil {
			return translateNoRows(err, "Team")
		}
		if expected != 0 && current.Version != expected {
			return stale(current.Version)
		}
		if _, err := tx.Exec(ctx, "UPDATE teams SET name = COALESCE($2, name), description = COALESCE($3, description) WHERE id = $1",
			id, patch.Name, patch.Description); err != nil {
			return err
		}
		team, err = collectOne[Team](ctx, tx, "SELECT "+teamColumns+" FROM teams t WHERE t.id = $1", id)
		return err
	})
	return team, err
}

// DeleteTeam removes a team; projects, tasks and comments follow through ON DELETE CASCADE.
func (s *Store) DeleteTeam(ctx context.Context, actorID, id string) error {
	return s.WithUser(ctx, actorID, func(tx pgx.Tx) error {
		tag, err := tx.Exec(ctx, "DELETE FROM teams WHERE id = $1", id)
		if err != nil {
			return err
		}
		if tag.RowsAffected() == 0 {
			return notFound("Team")
		}
		return nil
	})
}

// translateNoRows gives a not-found error a message that names the missing thing.
func translateNoRows(err error, what string) error {
	var se *Error
	if errors.As(err, &se) && se.Kind == KindNotFound {
		return notFound(what)
	}
	return err
}
```
- `TeamAccess` answers two questions in one query: does the team exist, and which role does the caller have? A `LEFT JOIN` returns the team row with a null role for a stranger.
- `CreateTeam` calls the platform's stored function `create_team`, which inserts the team **and** its first lead in one step. The schema keeps that rule, so every backend gets it for free.
- `UpdateTeam` locks the row (`FOR UPDATE`), compares the version with the one the client sent, and only then updates. The `COALESCE($2, name)` trick applies a **merge patch**: a nil pointer becomes SQL `NULL`, and `COALESCE` keeps the old value.
- The database trigger `bump_version` raises `version` on a real change; the code never touches it.

**File: `internal/store/members.go`**
```go
package store

import (
	"context"
	"time"

	"github.com/jackc/pgx/v5"
)

// Member is a user inside a team.
type Member struct {
	UserID      string
	Username    string
	DisplayName string
	Role        string
	JoinedAt    time.Time
}

const memberColumns = "m.user_id, u.username, u.display_name, m.role, m.joined_at"

// ListMembers returns the members of a team, in the order they joined.
func (s *Store) ListMembers(ctx context.Context, teamID string, page PageParams) (Page[Member], error) {
	cursor, err := decodeCursor(page.Cursor, "members", uuidID)
	if err != nil {
		return Page[Member]{}, err
	}
	var b builder
	b.where("m.team_id = " + b.arg(teamID))
	b.afterTime("m.joined_at", "m.user_id", false, cursor)
	sql := "SELECT " + memberColumns + " FROM team_members m JOIN users u ON u.id = m.user_id" + b.whereSQL() +
		orderBy("m.joined_at", "m.user_id", false) + " LIMIT " + b.arg(page.Limit+1)
	items, err := collect[Member](ctx, s.pool, sql, b.args...)
	if err != nil {
		return Page[Member]{}, err
	}
	return finishPage(items, page.Limit, func(m Member) Cursor {
		return Cursor{Sort: "members", Time: m.JoinedAt, ID: m.UserID}
	}), nil
}

// roles returns the role of every member of a team and locks those rows until the transaction ends,
// so two requests cannot both remove "the other" lead.
func roles(ctx context.Context, tx pgx.Tx, teamID string) (map[string]string, error) {
	rows, err := tx.Query(ctx, "SELECT user_id, role FROM team_members WHERE team_id = $1 FOR UPDATE", teamID)
	if err != nil {
		return nil, mapError(err)
	}
	defer rows.Close()
	result := map[string]string{}
	for rows.Next() {
		var userID, role string
		if err := rows.Scan(&userID, &role); err != nil {
			return nil, mapError(err)
		}
		result[userID] = role
	}
	return result, mapError(rows.Err())
}

func leadCount(roles map[string]string) int {
	n := 0
	for _, role := range roles {
		if role == "lead" {
			n++
		}
	}
	return n
}

var errLastLead = &Error{Kind: KindConflict, Code: "last_lead", Message: "A team must keep at least one lead."}

// PutMember adds a user to a team or changes the role of an existing member. created is true for a new member.
func (s *Store) PutMember(ctx context.Context, actorID, teamID, userID, role string) (member Member, created bool, err error) {
	err = s.WithUser(ctx, actorID, func(tx pgx.Tx) error {
		var exists bool
		if err := tx.QueryRow(ctx, "SELECT EXISTS (SELECT 1 FROM users WHERE id = $1)", userID).Scan(&exists); err != nil {
			return err
		}
		if !exists {
			return notFound("User")
		}
		current, err := roles(ctx, tx, teamID)
		if err != nil {
			return err
		}
		previous, isMember := current[userID]
		created = !isMember
		if previous == "lead" && role != "lead" && leadCount(current) == 1 {
			return errLastLead
		}
		if _, err := tx.Exec(ctx, `INSERT INTO team_members (team_id, user_id, role) VALUES ($1, $2, $3)
			ON CONFLICT (team_id, user_id) DO UPDATE SET role = EXCLUDED.role`, teamID, userID, role); err != nil {
			return err
		}
		member, err = collectOne[Member](ctx, tx, "SELECT "+memberColumns+
			" FROM team_members m JOIN users u ON u.id = m.user_id WHERE m.team_id = $1 AND m.user_id = $2", teamID, userID)
		return err
	})
	return member, created, err
}

// RemoveMember deletes a membership. The last lead of a team cannot be removed.
func (s *Store) RemoveMember(ctx context.Context, actorID, teamID, userID string) error {
	return s.WithUser(ctx, actorID, func(tx pgx.Tx) error {
		current, err := roles(ctx, tx, teamID)
		if err != nil {
			return err
		}
		role, isMember := current[userID]
		if !isMember {
			return notFound("Member")
		}
		if role == "lead" && leadCount(current) == 1 {
			return errLastLead
		}
		_, err = tx.Exec(ctx, "DELETE FROM team_members WHERE team_id = $1 AND user_id = $2", teamID, userID)
		return err
	})
}
```
`roles` locks every member row of the team (`FOR UPDATE`) before the decision "is this the last lead?", so two requests cannot both demote "the other" lead at the same moment. The last lead can neither be removed nor demoted (`409`, code `last_lead`).

**File: `internal/store/projects.go`**
```go
package store

import (
	"context"
	"time"

	"github.com/jackc/pgx/v5"
)

// Project is a row of the projects table.
type Project struct {
	ID          string
	TeamID      string
	Key         string
	Name        string
	Description string
	Archived    bool
	Version     int
	CreatedAt   time.Time
	UpdatedAt   time.Time
}

const projectColumns = "p.id, p.team_id, p.key, p.name, p.description, p.archived, p.version, p.created_at, p.updated_at"

func (s *Store) GetProject(ctx context.Context, id string) (Project, error) {
	project, err := collectOne[Project](ctx, s.pool, "SELECT "+projectColumns+" FROM projects p WHERE p.id = $1", id)
	return project, translateNoRows(err, "Project")
}

// TeamOfProject finds the team that owns a project, for the authorization check.
func (s *Store) TeamOfProject(ctx context.Context, projectID string) (string, error) {
	var teamID string
	err := s.pool.QueryRow(ctx, "SELECT team_id FROM projects WHERE id = $1", projectID).Scan(&teamID)
	return teamID, translateNoRows(mapError(err), "Project")
}

// ListProjects returns a team's projects. Archived projects are hidden unless includeArchived is true.
func (s *Store) ListProjects(ctx context.Context, teamID string, includeArchived, desc bool, page PageParams) (Page[Project], error) {
	sort := "createdAt"
	if desc {
		sort = "-createdAt"
	}
	cursor, err := decodeCursor(page.Cursor, "projects:"+sort, uuidID)
	if err != nil {
		return Page[Project]{}, err
	}
	var b builder
	b.where("p.team_id = " + b.arg(teamID))
	if !includeArchived {
		b.where("NOT p.archived")
	}
	b.afterTime("p.created_at", "p.id", desc, cursor)
	sql := "SELECT " + projectColumns + " FROM projects p" + b.whereSQL() + orderBy("p.created_at", "p.id", desc) +
		" LIMIT " + b.arg(page.Limit+1)
	items, err := collect[Project](ctx, s.pool, sql, b.args...)
	if err != nil {
		return Page[Project]{}, err
	}
	return finishPage(items, page.Limit, func(p Project) Cursor {
		return Cursor{Sort: "projects:" + sort, Time: p.CreatedAt, ID: p.ID}
	}), nil
}

func (s *Store) CreateProject(ctx context.Context, actorID, teamID, key, name, description string) (Project, error) {
	var project Project
	err := s.WithUser(ctx, actorID, func(tx pgx.Tx) error {
		var err error
		project, err = collectOne[Project](ctx, tx, `INSERT INTO projects AS p (team_id, key, name, description, created_by)
			VALUES ($1, $2, $3, $4, $5) RETURNING `+projectColumns, teamID, key, name, description, actorID)
		return err
	})
	return project, err
}

// ProjectPatch holds the fields a JSON Merge Patch may change; nil means "leave as it is".
type ProjectPatch struct {
	Name        *string
	Description *string
	Archived    *bool
}

func (s *Store) UpdateProject(ctx context.Context, actorID, id string, expected int, patch ProjectPatch) (Project, error) {
	var project Project
	err := s.WithUser(ctx, actorID, func(tx pgx.Tx) error {
		current, err := collectOne[Project](ctx, tx, "SELECT "+projectColumns+" FROM projects p WHERE p.id = $1 FOR UPDATE", id)
		if err != nil {
			return translateNoRows(err, "Project")
		}
		if expected != 0 && current.Version != expected {
			return stale(current.Version)
		}
		project, err = collectOne[Project](ctx, tx, `UPDATE projects AS p SET name = COALESCE($2, name),
			description = COALESCE($3, description), archived = COALESCE($4, archived)
			WHERE p.id = $1 RETURNING `+projectColumns, id, patch.Name, patch.Description, patch.Archived)
		return err
	})
	return project, err
}

func (s *Store) DeleteProject(ctx context.Context, actorID, id string) error {
	return s.WithUser(ctx, actorID, func(tx pgx.Tx) error {
		tag, err := tx.Exec(ctx, "DELETE FROM projects WHERE id = $1", id)
		if err != nil {
			return err
		}
		if tag.RowsAffected() == 0 {
			return notFound("Project")
		}
		return nil
	})
}
```

### Step 5. The caller: `internal/auth`
**File: `internal/auth/principal.go`**
```go
// Package auth identifies the caller of a request and describes what the caller may do.
package auth

import (
	"context"
	"net/http"
	"slices"
)

// Scopes of the contract: what the client application may do on behalf of the user.
const (
	ScopeRead  = "tasks:read"
	ScopeWrite = "tasks:write"
	ScopeAdmin = "tasks:admin"
)

// Realm roles of the contract: what the user may do.
const (
	RoleAdmin  = "admin"
	RoleMember = "member"
)

// Principal is the authenticated caller.
type Principal struct {
	ID          string // the Keycloak sub, equal to users.id
	Username    string
	Email       string
	DisplayName string
	Roles       []string
	Scopes      []string
}

func (p *Principal) HasRole(role string) bool   { return slices.Contains(p.Roles, role) }
func (p *Principal) HasScope(scope string) bool { return slices.Contains(p.Scopes, scope) }
func (p *Principal) IsAdmin() bool              { return p.HasRole(RoleAdmin) }

// Authenticator turns the credentials of a request into a Principal.
//
// It returns (nil, nil) when the request carries no credentials at all, and (nil, err) when it carries
// credentials that are not valid. The HTTP layer answers both with 401, with a different message.
type Authenticator interface {
	Authenticate(r *http.Request) (*Principal, error)
}

type principalKey struct{}
type failureKey struct{}

// NewContext stores the outcome of authentication in the request context.
func NewContext(ctx context.Context, p *Principal, failure error) context.Context {
	ctx = context.WithValue(ctx, principalKey{}, p)
	return context.WithValue(ctx, failureKey{}, failure)
}

// FromContext returns the caller, or nil when the request is anonymous or its credentials were rejected.
func FromContext(ctx context.Context) *Principal {
	p, _ := ctx.Value(principalKey{}).(*Principal)
	return p
}

// FailureFromContext returns why the credentials were rejected, or nil.
func FailureFromContext(ctx context.Context) error {
	err, _ := ctx.Value(failureKey{}).(error)
	return err
}
```
A `Principal` is the authenticated caller: id, profile, **roles** (what the person may do: `admin`, `member`) and **scopes** (what the client application may do on their behalf: `tasks:read`, `tasks:write`, `tasks:admin`). `Authenticator` is an interface with one method; the HTTP layer depends on the interface, not on how credentials are checked. That is why chapter 05 can replace the implementation without touching a handler. The context helpers carry the outcome through the request: a principal, or the reason the credentials were refused.

**File: `internal/auth/dev.go`**
```go
package auth

import (
	"context"
	"errors"
	"net/http"
	"strings"

	"example.com/tasksteams/internal/store"
)

// UserLookup is the one thing the development authenticator needs from the data layer.
type UserLookup interface {
	GetUser(ctx context.Context, id string) (store.User, error)
}

// Dev is a stand-in for Keycloak until chapter 05. It trusts three request headers:
//
//	X-Dev-User    the id of a user in the users table
//	X-Dev-Roles   comma separated realm roles (default: member)
//	X-Dev-Scopes  comma separated scopes (default: all three)
//
// Anyone can send those headers, so this type must never run anywhere but on your own machine.
// Chapter 05 deletes it.
type Dev struct {
	Users UserLookup
}

func (d Dev) Authenticate(r *http.Request) (*Principal, error) {
	id := r.Header.Get("X-Dev-User")
	if id == "" {
		return nil, nil
	}
	user, err := d.Users.GetUser(r.Context(), id)
	if err != nil {
		return nil, errors.New("X-Dev-User is not a known user")
	}
	return &Principal{
		ID:          user.ID,
		Username:    user.Username,
		Email:       user.Email,
		DisplayName: user.DisplayName,
		Roles:       headerList(r, "X-Dev-Roles", RoleMember),
		Scopes:      headerList(r, "X-Dev-Scopes", ScopeRead, ScopeWrite, ScopeAdmin),
	}, nil
}

// headerList splits a comma separated header, or returns the defaults when the header is absent.
func headerList(r *http.Request, name string, defaults ...string) []string {
	raw := r.Header.Get(name)
	if raw == "" {
		return defaults
	}
	items := strings.Split(raw, ",")
	for i := range items {
		items[i] = strings.TrimSpace(items[i])
	}
	return items
}
```
`Dev` is a **stand-in**: it believes the headers `X-Dev-User`, `X-Dev-Roles` and `X-Dev-Scopes`. Anyone can send those headers. The program therefore logs a loud warning at start-up, and chapter 05 deletes this file. A stand-in that is honest about being unsafe is a normal way to build the next layer without waiting for the previous one.

### Step 6. The HTTP layer, part 2
New files in `internal/http`.

**File: `internal/http/request.go`**
```go
package httpapi

import (
	"net/http"
	"strconv"
	"strings"

	"example.com/tasksteams/internal/problem"
	"example.com/tasksteams/internal/store"
)

const (
	defaultLimit = 25
	maxLimit     = 100
)

// pageParams reads limit and cursor. The cursor stays opaque here; the store decodes it.
func pageParams(r *http.Request) (store.PageParams, *problem.Problem) {
	query := r.URL.Query()
	params := store.PageParams{Limit: defaultLimit, Cursor: query.Get("cursor")}
	if raw := query.Get("limit"); raw != "" {
		n, err := strconv.Atoi(raw)
		if err != nil || n < 1 || n > maxLimit {
			return params, problem.BadRequest("limit must be a whole number from 1 to 100.")
		}
		params.Limit = n
	}
	if len(params.Cursor) > 512 {
		return params, problem.BadRequest(store.ErrBadCursor.Message)
	}
	return params, nil
}

// sortParam returns the sort query parameter; the first allowed value is the default.
func sortParam(r *http.Request, allowed ...string) (string, *problem.Problem) {
	value := r.URL.Query().Get("sort")
	if value == "" {
		return allowed[0], nil
	}
	for _, candidate := range allowed {
		if value == candidate {
			return value, nil
		}
	}
	return "", problem.BadRequest("sort must be one of: " + strings.Join(allowed, ", ") + ".")
}

// textParam returns a free-text query parameter such as q, limited to max characters.
func textParam(r *http.Request, name string, max int) (string, *problem.Problem) {
	value := strings.TrimSpace(r.URL.Query().Get(name))
	if len([]rune(value)) > max {
		return "", problem.BadRequest(name + " must be at most " + strconv.Itoa(max) + " characters.")
	}
	return value, nil
}

// pathID reads a UUID from the URL. Text that is not a UUID cannot be the id of anything, so the answer is 404.
func pathID(w http.ResponseWriter, r *http.Request, name string) (string, bool) {
	id := r.PathValue(name)
	if !isUUID(id) {
		problem.Write(w, r, problem.NotFound("The resource does not exist."))
		return "", false
	}
	return id, true
}

type pageInfo struct {
	Limit      int     `json:"limit"`
	NextCursor *string `json:"nextCursor"` // null on the last page
}

type pageDTO[T any] struct {
	Items []T      `json:"items"`
	Page  pageInfo `json:"page"`
}

// toPage converts a page of store items into the contract's page object.
func toPage[S, D any](page store.Page[S], limit int, convert func(S) D) pageDTO[D] {
	out := pageDTO[D]{Items: make([]D, 0, len(page.Items)), Page: pageInfo{Limit: limit}}
	for _, item := range page.Items {
		out.Items = append(out.Items, convert(item))
	}
	if page.NextCursor != "" {
		out.Page.NextCursor = &page.NextCursor
	}
	return out
}
```
`pageParams`, `sortParam`, `textParam` and `pathID` read and check the query string and the path. A malformed path id is a `404`, not a `400` or a database error: text that is not a UUID cannot be the id of anything. `pageDTO[T]` is a generic page body (`items` and `page.nextCursor`, which is `null` on the last page because the field is a `*string`).

**File: `internal/http/etag.go`**
```go
package httpapi

import (
	"net/http"
	"strconv"
	"strings"

	"example.com/tasksteams/internal/problem"
)

// etagOf makes the strong ETag of a resource: its version in quotes, for example "3".
func etagOf(version int) string { return `"` + strconv.Itoa(version) + `"` }

func parseETag(raw string) (int, bool) {
	if len(raw) < 3 || raw[0] != '"' || raw[len(raw)-1] != '"' {
		return 0, false
	}
	version, err := strconv.Atoi(raw[1 : len(raw)-1])
	return version, err == nil && version >= 1
}

// ifMatch reads the If-Match header. It returns the version the client last saw, or 0 for "any version"
// (the header is absent and optional, or it is *). A required header that is missing is the 428 problem.
func ifMatch(r *http.Request, required bool) (int, *problem.Problem) {
	raw := strings.TrimSpace(r.Header.Get("If-Match"))
	switch {
	case raw == "" && required:
		return 0, problem.PreconditionRequired("Send If-Match with the ETag you last read.")
	case raw == "" || raw == "*":
		return 0, nil
	}
	version, ok := parseETag(raw)
	if !ok {
		return 0, problem.BadRequest(`If-Match must be a quoted version such as "3".`)
	}
	return version, nil
}

// etagMatches implements the weak comparison of If-None-Match: a list of ETags, or *.
func etagMatches(header, etag string) bool {
	for _, candidate := range strings.Split(header, ",") {
		candidate = strings.TrimPrefix(strings.TrimSpace(candidate), "W/")
		if candidate == "*" || candidate == etag {
			return true
		}
	}
	return false
}

// respondEntity sends one resource with its ETag. A GET whose If-None-Match already names this version gets 304 and no body.
func respondEntity(w http.ResponseWriter, r *http.Request, status, version int, body any) {
	etag := etagOf(version)
	w.Header().Set("ETag", etag)
	if r.Method == http.MethodGet && etagMatches(r.Header.Get("If-None-Match"), etag) {
		w.WriteHeader(http.StatusNotModified)
		return
	}
	writeJSON(w, r, status, body)
}
```
A **strong ETag** here is the quoted `version` (`"3"`). `ifMatch` parses the `If-Match` header: missing and required is `428 Precondition Required`, `*` means "any version", anything else must be a quoted number or it is `400`. `etagMatches` implements the weak comparison of `If-None-Match`, so a client that already holds version 3 gets `304 Not Modified` and no body. `respondEntity` sets the `ETag` header for every single resource.

**File: `internal/http/errors.go`**
```go
package httpapi

import (
	"errors"
	"net/http"

	"example.com/tasksteams/internal/problem"
	"example.com/tasksteams/internal/store"
)

// storeProblem maps a store error to the problem it stands for. Errors the store does not know become a
// 500 whose body says nothing about the cause; the cause goes to the log with the trace id.
func (s *Server) storeProblem(r *http.Request, err error) *problem.Problem {
	var se *store.Error
	if !errors.As(err, &se) {
		s.logger.Error("request failed", "error", err, "trace_id", problem.TraceID(r.Context()))
		return problem.Internal()
	}
	var p *problem.Problem
	switch se.Kind {
	case store.KindNotFound:
		p = problem.NotFound(se.Message)
	case store.KindConflict:
		p = problem.Conflict(se.Message)
	case store.KindStale:
		p = problem.PreconditionFailed(se.Message)
	case store.KindInvalid:
		p = problem.Validation(se.Message)
	case store.KindBadCursor:
		p = problem.BadRequest(se.Message)
	default:
		return problem.Internal()
	}
	if se.Code != "" {
		p.WithCode(se.Code)
	}
	return p
}

// fail writes the problem for a store error.
func (s *Server) fail(w http.ResponseWriter, r *http.Request, err error) {
	problem.Write(w, r, s.storeProblem(r, err))
}
```
`storeProblem` is the bridge from `store.Error` kinds to problem types (404, 409, 412, 422, 400). An error the store does not recognise becomes a 500 whose body says nothing about the cause; the real error goes to the log together with the trace id, so a user can quote the id and you can find the cause. Internal details in an error body are an information leak.

**File: `internal/http/authz.go`**
```go
package httpapi

import (
	"net/http"
	"strings"

	"example.com/tasksteams/internal/auth"
	"example.com/tasksteams/internal/problem"
)

// authenticate runs on every /v1 request. It never rejects: it records who the caller is, or why the credentials
// were refused, and leaves the 401 to the route (see handle), so that /health and unknown paths stay open.
func (s *Server) authenticate(next http.Handler) http.Handler {
	return http.HandlerFunc(func(w http.ResponseWriter, r *http.Request) {
		if !strings.HasPrefix(r.URL.Path, "/v1/") {
			next.ServeHTTP(w, r)
			return
		}
		principal, err := s.auth.Authenticate(r)
		if err != nil {
			s.logger.Warn("authentication failed", "reason", err.Error(), "trace_id", problem.TraceID(r.Context()))
		}
		if principal != nil {
			infoFrom(r.Context()).userID = principal.ID
		}
		next.ServeHTTP(w, r.WithContext(auth.NewContext(r.Context(), principal, err)))
	})
}

// handle registers a route that needs a signed-in caller whose token carries the given scope.
func (s *Server) handle(mux *http.ServeMux, pattern, scope string, h http.HandlerFunc) {
	mux.HandleFunc(pattern, func(w http.ResponseWriter, r *http.Request) {
		principal := auth.FromContext(r.Context())
		if principal == nil {
			p := problem.Unauthorized("A bearer access token is required.")
			if auth.FailureFromContext(r.Context()) != nil {
				p = problem.Unauthorized("The access token is invalid or expired.").
					WithHeader("WWW-Authenticate", `Bearer realm="tasksteams", error="invalid_token"`)
			}
			problem.Write(w, r, p)
			return
		}
		if !principal.HasScope(scope) {
			problem.Write(w, r, problem.Forbidden("The token needs the scope "+scope+"."))
			return
		}
		h(w, r)
	})
}

// requireAdmin answers 403 unless the caller has the admin realm role.
func requireAdmin(w http.ResponseWriter, r *http.Request) (*auth.Principal, bool) {
	principal := auth.FromContext(r.Context())
	if !principal.IsAdmin() {
		problem.Write(w, r, problem.Forbidden("The admin role is required."))
		return nil, false
	}
	return principal, true
}

type teamLevel int

const (
	levelMember teamLevel = iota // any member of the team
	levelLead                    // a lead of the team
)

// authorize decides whether the caller may act on a team's objects. what names the object for the message.
//
// A caller who is not in the team gets 404, the same answer as for an id that does not exist, so ids cannot be probed.
// A member who lacks the lead role gets 403: they already know the object exists. Admins pass for every team.
func (s *Server) authorize(w http.ResponseWriter, r *http.Request, teamID string, need teamLevel, what string) bool {
	principal := auth.FromContext(r.Context())
	access, err := s.store.TeamAccess(r.Context(), teamID, principal.ID)
	if err != nil {
		s.fail(w, r, err)
		return false
	}
	switch {
	case !access.Exists, access.Role == "" && !principal.IsAdmin():
		problem.Write(w, r, problem.NotFound("The "+what+" does not exist."))
		return false
	case need == levelLead && access.Role != "lead" && !principal.IsAdmin():
		problem.Write(w, r, problem.Forbidden("Only a team lead or an admin can do this."))
		return false
	}
	return true
}
```
- `authenticate` never rejects. It records who the caller is (or why the credentials failed) in the context, and sets the user id for the access log. Rejecting is the job of each route, so `/health` and unknown paths stay open.
- `handle` registers a route with the **scope** it needs. No principal is `401` (with `WWW-Authenticate: Bearer`), a missing scope is `403`.
- `authorize` is the object-level rule of the whole API. A stranger to a team gets **404**, the same answer as for an id that does not exist, so nobody can probe which ids exist (OWASP API1). A member without the lead role gets **403**: they already know the object exists. An admin passes for every team.

**File: `internal/http/server.go`**
```go
package httpapi

import (
	"log/slog"
	"net/http"

	"example.com/tasksteams/internal/auth"
	"example.com/tasksteams/internal/problem"
	"example.com/tasksteams/internal/store"
)

// apiVersion is reported by /health. It follows the contract version.
const apiVersion = "1.0.0"

// Deps is everything the HTTP layer needs from the outside. main builds it once.
type Deps struct {
	Logger    *slog.Logger
	Store     *store.Store
	Auth      auth.Authenticator
	PublicURL string // absolute base URL for Location headers, for example http://localhost:8000
}

// Server holds what the handlers share and the finished handler chain.
type Server struct {
	logger    *slog.Logger
	store     *store.Store
	auth      auth.Authenticator
	publicURL string
	handler   http.Handler
}

// NewServer registers every route and wraps them in the middleware chain.
func NewServer(d Deps) *Server {
	s := &Server{logger: d.Logger, store: d.Store, auth: d.Auth, publicURL: d.PublicURL}
	mux := http.NewServeMux()
	mux.HandleFunc("GET /health", s.health)
	s.handle(mux, "GET /v1/me", auth.ScopeRead, s.me)
	s.handle(mux, "GET /v1/users", auth.ScopeRead, s.listUsers)
	s.registerTeams(mux)
	s.registerMembers(mux)
	s.registerProjects(mux)
	s.handler = chain(routeErrors(mux), withTrace, s.accessLog, s.recoverer, s.authenticate)
	return s
}

// Handler returns the handler to give to http.Server.
func (s *Server) Handler() http.Handler { return s.handler }

// routeErrors replaces the plain-text 404 and 405 answers of http.ServeMux with problem details.
func routeErrors(mux *http.ServeMux) http.Handler {
	return http.HandlerFunc(func(w http.ResponseWriter, r *http.Request) {
		handler, pattern := mux.Handler(r)
		if pattern != "" {
			mux.ServeHTTP(w, r) // ServeHTTP, not handler.ServeHTTP: only the mux fills in the path values
			return
		}
		probe := &statusProbe{header: http.Header{}}
		handler.ServeHTTP(probe, r) // the mux's own "not found" or "method not allowed" handler
		if probe.status == http.StatusMethodNotAllowed {
			problem.Write(w, r, problem.New(http.StatusMethodNotAllowed, "method-not-allowed", "Method not allowed",
				"This path does not support "+r.Method+".").WithHeader("Allow", probe.header.Get("Allow")))
			return
		}
		problem.Write(w, r, problem.NotFound("There is no such path."))
	})
}

// statusProbe is a ResponseWriter that keeps the status and headers and throws the body away.
type statusProbe struct {
	header http.Header
	status int
}

func (p *statusProbe) Header() http.Header         { return p.header }
func (p *statusProbe) Write(b []byte) (int, error) { return len(b), nil }
func (p *statusProbe) WriteHeader(status int)      { p.status = status }
```
`Deps` is everything the HTTP layer receives from `main`; handlers are methods of `*Server`, so they reach the store and the logger through the receiver and not through global variables. Routes are registered per resource (`registerTeams`, and so on), each with its scope.

**File: `internal/http/health.go`**
```go
package httpapi

import (
	"context"
	"net/http"
	"time"
)

type healthDTO struct {
	Status   string `json:"status"`
	Version  string `json:"version"`
	Database string `json:"database,omitempty"`
}

// health answers without a token. It pings the database with a short deadline: 200 when it answers, 503 when not.
func (s *Server) health(w http.ResponseWriter, r *http.Request) {
	ctx, cancel := context.WithTimeout(r.Context(), 2*time.Second)
	defer cancel()
	if err := s.store.Ping(ctx); err != nil {
		s.logger.Warn("health: database is down", "error", err)
		writeJSON(w, r, http.StatusServiceUnavailable, healthDTO{Status: "degraded", Version: apiVersion, Database: "down"})
		return
	}
	writeJSON(w, r, http.StatusOK, healthDTO{Status: "ok", Version: apiVersion, Database: "up"})
}
```
`/health` now pings the database with a two-second deadline (`context.WithTimeout`) and answers `503` with `"status":"degraded"` when the ping fails, as the contract says.

**File: `internal/http/me.go`**
```go
package httpapi

import (
	"net/http"
	"slices"

	"example.com/tasksteams/internal/auth"
)

type meTeamDTO struct {
	TeamID string `json:"teamId"`
	Name   string `json:"name"`
	Role   string `json:"role"`
}

type meDTO struct {
	ID          string      `json:"id"`
	Username    string      `json:"username"`
	Email       string      `json:"email"`
	DisplayName string      `json:"displayName"`
	Roles       []string    `json:"roles"`
	Scopes      []string    `json:"scopes"`
	Teams       []meTeamDTO `json:"teams"`
}

// me describes the caller: the profile comes from the users table, roles and scopes from the credentials.
func (s *Server) me(w http.ResponseWriter, r *http.Request) {
	principal := auth.FromContext(r.Context())
	user, err := s.store.GetUser(r.Context(), principal.ID)
	if err != nil {
		s.fail(w, r, err)
		return
	}
	teams, err := s.store.UserTeams(r.Context(), principal.ID)
	if err != nil {
		s.fail(w, r, err)
		return
	}
	dto := meDTO{
		ID:          user.ID,
		Username:    user.Username,
		Email:       user.Email,
		DisplayName: user.DisplayName,
		Roles:       []string{}, // never null in JSON
		Scopes:      slices.Clone(principal.Scopes),
		Teams:       make([]meTeamDTO, 0, len(teams)),
	}
	for _, role := range []string{auth.RoleAdmin, auth.RoleMember} { // only the roles the contract knows, in a fixed order
		if principal.HasRole(role) {
			dto.Roles = append(dto.Roles, role)
		}
	}
	for _, t := range teams {
		dto.Teams = append(dto.Teams, meTeamDTO{TeamID: t.TeamID, Name: t.Name, Role: t.Role})
	}
	writeJSON(w, r, http.StatusOK, dto)
}
```
**File: `internal/http/teams.go`**
```go
package httpapi

import (
	"net/http"
	"time"

	"example.com/tasksteams/internal/auth"
	"example.com/tasksteams/internal/problem"
	"example.com/tasksteams/internal/store"
)

// teamDTO is the response body for a team (schema Team in the contract). It is not the store's Team:
// the names are the contract's, and the store type can change without changing the API.
type teamDTO struct {
	ID          string    `json:"id"`
	Name        string    `json:"name"`
	Description string    `json:"description"`
	MemberCount int       `json:"memberCount"`
	CreatedBy   string    `json:"createdBy"`
	Version     int       `json:"version"`
	CreatedAt   time.Time `json:"createdAt"`
	UpdatedAt   time.Time `json:"updatedAt"`
}

func toTeamDTO(t store.Team) teamDTO {
	return teamDTO{
		ID: t.ID, Name: t.Name, Description: t.Description, MemberCount: t.MemberCount, CreatedBy: t.CreatedBy,
		Version: t.Version, CreatedAt: t.CreatedAt.UTC(), UpdatedAt: t.UpdatedAt.UTC(),
	}
}

// teamCreateDTO is the request body of POST /v1/teams (schema TeamCreate).
type teamCreateDTO struct {
	Name        string `json:"name"`
	Description string `json:"description"`
	LeadUserID  string `json:"leadUserId"`
}

func (d *teamCreateDTO) validate() *problem.Problem {
	var v validator
	d.Name = v.text("/name", d.Name, 1, 80)
	d.Description = v.text("/description", d.Description, 0, 500)
	if d.LeadUserID != "" {
		v.uuid("/leadUserId", d.LeadUserID)
	}
	return v.result()
}

// teamUpdateDTO is a JSON Merge Patch: a field that is absent stays as it is.
type teamUpdateDTO struct {
	Name        *string `json:"name"`
	Description *string `json:"description"`
}

func (d *teamUpdateDTO) validate() *problem.Problem {
	var v validator
	if d.Name == nil && d.Description == nil {
		v.add("", "send at least one field to change")
	}
	if d.Name != nil {
		*d.Name = v.text("/name", *d.Name, 1, 80)
	}
	if d.Description != nil {
		*d.Description = v.text("/description", *d.Description, 0, 500)
	}
	return v.result()
}

func (s *Server) registerTeams(mux *http.ServeMux) {
	s.handle(mux, "GET /v1/teams", auth.ScopeRead, s.listTeams)
	s.handle(mux, "POST /v1/teams", auth.ScopeWrite, s.createTeam)
	s.handle(mux, "GET /v1/teams/{teamId}", auth.ScopeRead, s.getTeam)
	s.handle(mux, "PATCH /v1/teams/{teamId}", auth.ScopeWrite, s.updateTeam)
	s.handle(mux, "DELETE /v1/teams/{teamId}", auth.ScopeAdmin, s.deleteTeam)
}

func (s *Server) listTeams(w http.ResponseWriter, r *http.Request) {
	principal := auth.FromContext(r.Context())
	page, p := pageParams(r)
	if p != nil {
		problem.Write(w, r, p)
		return
	}
	sort, p := sortParam(r, "-createdAt", "createdAt")
	if p != nil {
		problem.Write(w, r, p)
		return
	}
	prefix, p := textParam(r, "q", 100)
	if p != nil {
		problem.Write(w, r, p)
		return
	}
	result, err := s.store.ListTeams(r.Context(), store.TeamFilter{
		UserID: principal.ID, All: principal.IsAdmin(), Prefix: prefix, Desc: sort == "-createdAt", Page: page,
	})
	if err != nil {
		s.fail(w, r, err)
		return
	}
	writeJSON(w, r, http.StatusOK, toPage(result, page.Limit, toTeamDTO))
}

func (s *Server) createTeam(w http.ResponseWriter, r *http.Request) {
	principal, ok := requireAdmin(w, r)
	if !ok {
		return
	}
	var dto teamCreateDTO
	if p := decodeJSON(r, &dto); p != nil {
		problem.Write(w, r, p)
		return
	}
	if p := dto.validate(); p != nil {
		problem.Write(w, r, p)
		return
	}
	lead := dto.LeadUserID
	if lead == "" {
		lead = principal.ID
	}
	team, err := s.store.CreateTeam(r.Context(), principal.ID, lead, dto.Name, dto.Description)
	if err != nil {
		s.fail(w, r, err)
		return
	}
	w.Header().Set("Location", s.publicURL+"/v1/teams/"+team.ID)
	respondEntity(w, r, http.StatusCreated, team.Version, toTeamDTO(team))
}

func (s *Server) getTeam(w http.ResponseWriter, r *http.Request) {
	id, ok := pathID(w, r, "teamId")
	if !ok || !s.authorize(w, r, id, levelMember, "team") {
		return
	}
	team, err := s.store.GetTeam(r.Context(), id)
	if err != nil {
		s.fail(w, r, err)
		return
	}
	respondEntity(w, r, http.StatusOK, team.Version, toTeamDTO(team))
}

func (s *Server) updateTeam(w http.ResponseWriter, r *http.Request) {
	id, ok := pathID(w, r, "teamId")
	if !ok || !s.authorize(w, r, id, levelLead, "team") {
		return
	}
	expected, p := ifMatch(r, true)
	if p != nil {
		problem.Write(w, r, p)
		return
	}
	var dto teamUpdateDTO
	if p := decodeJSON(r, &dto); p != nil {
		problem.Write(w, r, p)
		return
	}
	if p := dto.validate(); p != nil {
		problem.Write(w, r, p)
		return
	}
	team, err := s.store.UpdateTeam(r.Context(), auth.FromContext(r.Context()).ID, id, expected,
		store.TeamPatch{Name: dto.Name, Description: dto.Description})
	if err != nil {
		s.fail(w, r, err)
		return
	}
	respondEntity(w, r, http.StatusOK, team.Version, toTeamDTO(team))
}

func (s *Server) deleteTeam(w http.ResponseWriter, r *http.Request) {
	principal, ok := requireAdmin(w, r)
	if !ok {
		return
	}
	id, ok := pathID(w, r, "teamId")
	if !ok {
		return
	}
	if err := s.store.DeleteTeam(r.Context(), principal.ID, id); err != nil {
		s.fail(w, r, err)
		return
	}
	w.WriteHeader(http.StatusNoContent)
}
```
**File: `internal/http/members.go`**
```go
package httpapi

import (
	"net/http"
	"time"

	"example.com/tasksteams/internal/auth"
	"example.com/tasksteams/internal/problem"
	"example.com/tasksteams/internal/store"
)

type memberDTO struct {
	UserID      string    `json:"userId"`
	Username    string    `json:"username"`
	DisplayName string    `json:"displayName"`
	Role        string    `json:"role"`
	JoinedAt    time.Time `json:"joinedAt"`
}

func toMemberDTO(m store.Member) memberDTO {
	return memberDTO{UserID: m.UserID, Username: m.Username, DisplayName: m.DisplayName, Role: m.Role, JoinedAt: m.JoinedAt.UTC()}
}

type memberPutDTO struct {
	Role string `json:"role"`
}

func (d *memberPutDTO) validate() *problem.Problem {
	var v validator
	v.oneOf("/role", d.Role, "lead", "member")
	return v.result()
}

func (s *Server) registerMembers(mux *http.ServeMux) {
	s.handle(mux, "GET /v1/teams/{teamId}/members", auth.ScopeRead, s.listMembers)
	s.handle(mux, "PUT /v1/teams/{teamId}/members/{userId}", auth.ScopeWrite, s.putMember)
	s.handle(mux, "DELETE /v1/teams/{teamId}/members/{userId}", auth.ScopeWrite, s.removeMember)
}

func (s *Server) listMembers(w http.ResponseWriter, r *http.Request) {
	teamID, ok := pathID(w, r, "teamId")
	if !ok || !s.authorize(w, r, teamID, levelMember, "team") {
		return
	}
	page, p := pageParams(r)
	if p != nil {
		problem.Write(w, r, p)
		return
	}
	result, err := s.store.ListMembers(r.Context(), teamID, page)
	if err != nil {
		s.fail(w, r, err)
		return
	}
	writeJSON(w, r, http.StatusOK, toPage(result, page.Limit, toMemberDTO))
}

func (s *Server) putMember(w http.ResponseWriter, r *http.Request) {
	teamID, ok := pathID(w, r, "teamId")
	if !ok || !s.authorize(w, r, teamID, levelLead, "team") {
		return
	}
	userID, ok := pathID(w, r, "userId")
	if !ok {
		return
	}
	var dto memberPutDTO
	if p := decodeJSON(r, &dto); p != nil {
		problem.Write(w, r, p)
		return
	}
	if p := dto.validate(); p != nil {
		problem.Write(w, r, p)
		return
	}
	member, created, err := s.store.PutMember(r.Context(), auth.FromContext(r.Context()).ID, teamID, userID, dto.Role)
	if err != nil {
		s.fail(w, r, err)
		return
	}
	status := http.StatusOK
	if created {
		status = http.StatusCreated
	}
	writeJSON(w, r, status, toMemberDTO(member))
}

func (s *Server) removeMember(w http.ResponseWriter, r *http.Request) {
	teamID, ok := pathID(w, r, "teamId")
	if !ok || !s.authorize(w, r, teamID, levelLead, "team") {
		return
	}
	userID, ok := pathID(w, r, "userId")
	if !ok {
		return
	}
	if err := s.store.RemoveMember(r.Context(), auth.FromContext(r.Context()).ID, teamID, userID); err != nil {
		s.fail(w, r, err)
		return
	}
	w.WriteHeader(http.StatusNoContent)
}
```
**File: `internal/http/projects.go`**
```go
package httpapi

import (
	"net/http"
	"regexp"
	"time"

	"example.com/tasksteams/internal/auth"
	"example.com/tasksteams/internal/problem"
	"example.com/tasksteams/internal/store"
)

var projectKeyPattern = regexp.MustCompile(`^[A-Z][A-Z0-9]{1,9}$`)

type projectDTO struct {
	ID          string    `json:"id"`
	TeamID      string    `json:"teamId"`
	Key         string    `json:"key"`
	Name        string    `json:"name"`
	Description string    `json:"description"`
	Archived    bool      `json:"archived"`
	Version     int       `json:"version"`
	CreatedAt   time.Time `json:"createdAt"`
	UpdatedAt   time.Time `json:"updatedAt"`
}

func toProjectDTO(p store.Project) projectDTO {
	return projectDTO{
		ID: p.ID, TeamID: p.TeamID, Key: p.Key, Name: p.Name, Description: p.Description, Archived: p.Archived,
		Version: p.Version, CreatedAt: p.CreatedAt.UTC(), UpdatedAt: p.UpdatedAt.UTC(),
	}
}

type projectCreateDTO struct {
	Key         string `json:"key"`
	Name        string `json:"name"`
	Description string `json:"description"`
}

func (d *projectCreateDTO) validate() *problem.Problem {
	var v validator
	v.matches("/key", d.Key, projectKeyPattern, "must be 2 to 10 characters: a capital letter, then capital letters or digits")
	d.Name = v.text("/name", d.Name, 1, 120)
	d.Description = v.text("/description", d.Description, 0, 2000)
	return v.result()
}

type projectUpdateDTO struct {
	Name        *string `json:"name"`
	Description *string `json:"description"`
	Archived    *bool   `json:"archived"`
}

func (d *projectUpdateDTO) validate() *problem.Problem {
	var v validator
	if d.Name == nil && d.Description == nil && d.Archived == nil {
		v.add("", "send at least one field to change")
	}
	if d.Name != nil {
		*d.Name = v.text("/name", *d.Name, 1, 120)
	}
	if d.Description != nil {
		*d.Description = v.text("/description", *d.Description, 0, 2000)
	}
	return v.result()
}

func (s *Server) registerProjects(mux *http.ServeMux) {
	s.handle(mux, "GET /v1/teams/{teamId}/projects", auth.ScopeRead, s.listProjects)
	s.handle(mux, "POST /v1/teams/{teamId}/projects", auth.ScopeWrite, s.createProject)
	s.handle(mux, "GET /v1/projects/{projectId}", auth.ScopeRead, s.getProject)
	s.handle(mux, "PATCH /v1/projects/{projectId}", auth.ScopeWrite, s.updateProject)
	s.handle(mux, "DELETE /v1/projects/{projectId}", auth.ScopeWrite, s.deleteProject)
}

func (s *Server) listProjects(w http.ResponseWriter, r *http.Request) {
	teamID, ok := pathID(w, r, "teamId")
	if !ok || !s.authorize(w, r, teamID, levelMember, "team") {
		return
	}
	page, p := pageParams(r)
	if p != nil {
		problem.Write(w, r, p)
		return
	}
	sort, p := sortParam(r, "-createdAt", "createdAt")
	if p != nil {
		problem.Write(w, r, p)
		return
	}
	archived := r.URL.Query().Get("archived")
	if archived != "" && archived != "true" && archived != "false" {
		problem.Write(w, r, problem.BadRequest("archived must be true or false."))
		return
	}
	// archived=true includes archived projects next to the active ones; the default hides them.
	result, err := s.store.ListProjects(r.Context(), teamID, archived == "true", sort == "-createdAt", page)
	if err != nil {
		s.fail(w, r, err)
		return
	}
	writeJSON(w, r, http.StatusOK, toPage(result, page.Limit, toProjectDTO))
}

func (s *Server) createProject(w http.ResponseWriter, r *http.Request) {
	teamID, ok := pathID(w, r, "teamId")
	if !ok || !s.authorize(w, r, teamID, levelLead, "team") {
		return
	}
	var dto projectCreateDTO
	if p := decodeJSON(r, &dto); p != nil {
		problem.Write(w, r, p)
		return
	}
	if p := dto.validate(); p != nil {
		problem.Write(w, r, p)
		return
	}
	project, err := s.store.CreateProject(r.Context(), auth.FromContext(r.Context()).ID, teamID, dto.Key, dto.Name, dto.Description)
	if err != nil {
		s.fail(w, r, err)
		return
	}
	w.Header().Set("Location", s.publicURL+"/v1/projects/"+project.ID)
	respondEntity(w, r, http.StatusCreated, project.Version, toProjectDTO(project))
}

// projectTeam finds the team of the project in the URL and checks that the caller may act on it.
func (s *Server) projectTeam(w http.ResponseWriter, r *http.Request, need teamLevel) (projectID string, ok bool) {
	projectID, ok = pathID(w, r, "projectId")
	if !ok {
		return "", false
	}
	teamID, err := s.store.TeamOfProject(r.Context(), projectID)
	if err != nil {
		s.fail(w, r, err)
		return "", false
	}
	return projectID, s.authorize(w, r, teamID, need, "project")
}

func (s *Server) getProject(w http.ResponseWriter, r *http.Request) {
	id, ok := s.projectTeam(w, r, levelMember)
	if !ok {
		return
	}
	project, err := s.store.GetProject(r.Context(), id)
	if err != nil {
		s.fail(w, r, err)
		return
	}
	respondEntity(w, r, http.StatusOK, project.Version, toProjectDTO(project))
}

func (s *Server) updateProject(w http.ResponseWriter, r *http.Request) {
	id, ok := s.projectTeam(w, r, levelLead)
	if !ok {
		return
	}
	expected, p := ifMatch(r, true)
	if p != nil {
		problem.Write(w, r, p)
		return
	}
	var dto projectUpdateDTO
	if p := decodeJSON(r, &dto); p != nil {
		problem.Write(w, r, p)
		return
	}
	if p := dto.validate(); p != nil {
		problem.Write(w, r, p)
		return
	}
	project, err := s.store.UpdateProject(r.Context(), auth.FromContext(r.Context()).ID, id, expected,
		store.ProjectPatch{Name: dto.Name, Description: dto.Description, Archived: dto.Archived})
	if err != nil {
		s.fail(w, r, err)
		return
	}
	respondEntity(w, r, http.StatusOK, project.Version, toProjectDTO(project))
}

func (s *Server) deleteProject(w http.ResponseWriter, r *http.Request) {
	id, ok := s.projectTeam(w, r, levelLead)
	if !ok {
		return
	}
	if err := s.store.DeleteProject(r.Context(), auth.FromContext(r.Context()).ID, id); err != nil {
		s.fail(w, r, err)
		return
	}
	w.WriteHeader(http.StatusNoContent)
}
```
**File: `internal/http/users.go`**
```go
package httpapi

import (
	"net/http"

	"example.com/tasksteams/internal/problem"
	"example.com/tasksteams/internal/store"
)

type userDTO struct {
	ID          string `json:"id"`
	Username    string `json:"username"`
	DisplayName string `json:"displayName"`
}

func toUserDTO(u store.User) userDTO {
	return userDTO{ID: u.ID, Username: u.Username, DisplayName: u.DisplayName}
}

// listUsers lets any signed-in user find people, for example to add a team member. It exposes no e-mail addresses.
func (s *Server) listUsers(w http.ResponseWriter, r *http.Request) {
	page, p := pageParams(r)
	if p != nil {
		problem.Write(w, r, p)
		return
	}
	prefix, p := textParam(r, "q", 100)
	if p != nil {
		problem.Write(w, r, p)
		return
	}
	result, err := s.store.ListUsers(r.Context(), prefix, page)
	if err != nil {
		s.fail(w, r, err)
		return
	}
	writeJSON(w, r, http.StatusOK, toPage(result, page.Limit, toUserDTO))
}
```
Read one handler from top to bottom, for example `updateTeam`: path id, then `authorize` (404 or 403), then `If-Match` (428), then decode (400 or 422), then validate (422), then the store call (412, 409 or 200). The order is deliberate: authorization comes before anything that reveals more about the resource, and cheap checks come before database work. Handlers contain no SQL and no business rule that the database already enforces.

### Step 7. Configuration and the program
**File: `internal/config/config.go`**
```go
// Package config reads the settings of the service from environment variables.
package config

import (
	"fmt"
	"log/slog"
	"os"
	"strings"
)

// Config holds every setting the service needs. It is built once at start-up and never changed.
type Config struct {
	ListenAddr  string
	LogLevel    slog.Level
	LogFormat   string
	DatabaseURL string
	PublicURL   string
}

// Load reads the environment and returns an error for a value it cannot use.
func Load() (Config, error) {
	cfg := Config{
		ListenAddr: env("LISTEN_ADDR", "127.0.0.1:8000"),
		LogFormat:  env("LOG_FORMAT", "text"),
		// The default is the disposable password of the platform stack. Real deployments set DATABASE_URL.
		DatabaseURL: env("DATABASE_URL", "postgres://tasks_app:tasks_app_local_only@127.0.0.1:5432/tasksteams"),
		PublicURL:   strings.TrimRight(env("PUBLIC_URL", "http://localhost:8000"), "/"),
	}
	if err := cfg.LogLevel.UnmarshalText([]byte(env("LOG_LEVEL", "info"))); err != nil {
		return Config{}, fmt.Errorf("LOG_LEVEL: %w", err)
	}
	if cfg.LogFormat != "text" && cfg.LogFormat != "json" {
		return Config{}, fmt.Errorf("LOG_FORMAT must be text or json, got %q", cfg.LogFormat)
	}
	return cfg, nil
}

// env returns the variable when it is set and not blank, otherwise the fallback.
func env(key, fallback string) string {
	if value, ok := os.LookupEnv(key); ok && strings.TrimSpace(value) != "" {
		return value
	}
	return fallback
}
```
`DATABASE_URL` defaults to the platform's disposable local password. A real deployment sets the variable from a secret store; chapter 07 adds a redacted configuration log so the password never reaches a log line.

**File: `cmd/api/main.go`**
```go
// Command api is the Tasks and Teams backend written in Go.
package main

import (
	"context"
	"errors"
	"fmt"
	"log/slog"
	"net/http"
	"os"
	"os/signal"
	"syscall"
	"time"

	"example.com/tasksteams/internal/auth"
	"example.com/tasksteams/internal/config"
	httpapi "example.com/tasksteams/internal/http"
	"example.com/tasksteams/internal/store"
)

func main() {
	if err := run(); err != nil {
		fmt.Fprintln(os.Stderr, "fatal:", err)
		os.Exit(1)
	}
}

func run() error {
	cfg, err := config.Load()
	if err != nil {
		return err
	}
	logger := newLogger(cfg)
	slog.SetDefault(logger)

	// ctx is cancelled by Ctrl+C (os.Interrupt) or by `docker stop` (SIGTERM).
	ctx, stop := signal.NotifyContext(context.Background(), os.Interrupt, syscall.SIGTERM)
	defer stop()

	db, err := store.Open(ctx, cfg.DatabaseURL)
	if err != nil {
		return err
	}
	defer db.Close()

	logger.Warn("DEVELOPMENT AUTHENTICATION: the X-Dev-User header is trusted. Never run this build on a shared machine.")
	srv := &http.Server{
		Addr: cfg.ListenAddr,
		Handler: httpapi.NewServer(httpapi.Deps{
			Logger:    logger,
			Store:     db,
			Auth:      auth.Dev{Users: db},
			PublicURL: cfg.PublicURL,
		}).Handler(),
		ReadHeaderTimeout: 5 * time.Second,
		ReadTimeout:       15 * time.Second,
		WriteTimeout:      30 * time.Second,
		IdleTimeout:       60 * time.Second,
		ErrorLog:          slog.NewLogLogger(logger.Handler(), slog.LevelWarn),
	}

	serveErr := make(chan error, 1)
	go func() {
		logger.Info("listening", "addr", cfg.ListenAddr)
		serveErr <- srv.ListenAndServe()
	}()

	select {
	case err := <-serveErr:
		return err // ListenAndServe only returns before Shutdown when it failed, for example "address already in use"
	case <-ctx.Done():
		logger.Info("shutting down", "reason", "signal received")
	}

	shutdownCtx, cancel := context.WithTimeout(context.Background(), 10*time.Second)
	defer cancel()
	if err := srv.Shutdown(shutdownCtx); err != nil && !errors.Is(err, http.ErrServerClosed) {
		return fmt.Errorf("graceful shutdown: %w", err)
	}
	logger.Info("stopped")
	return nil
}

func newLogger(cfg config.Config) *slog.Logger {
	opts := &slog.HandlerOptions{Level: cfg.LogLevel}
	if cfg.LogFormat == "json" {
		return slog.New(slog.NewJSONHandler(os.Stdout, opts))
	}
	return slog.New(slog.NewTextHandler(os.Stdout, opts))
}
```
`main` now opens the store, closes it on the way out and gives `NewServer` its dependencies. `auth.Dev{Users: db}` is the stand-in; the store's `GetUser` satisfies the one-method `UserLookup` interface without any adapter code.

### Step 8. Request files
**File: `requests/team-patch.json`**
```json
{"description": "Updated with If-Match"}
```
**File: `requests/member-put.json`**
```json
{"role": "member"}
```
**File: `requests/project-create.json`**
```json
{"key": "NEW", "name": "New project"}
```
**File: `requests/project-invalid.json`**
```json
{"key": "x", "name": ""}
```
Three small files hold one header each, because the double quotes in `If-Match: "1"` break in Windows PowerShell 5.1 when typed on the command line. `curl -H @file` reads the header from the file:
**File: `requests/if-match-1.txt`**
```text
If-Match: "1"
```
**File: `requests/if-match-99.txt`**
```text
If-Match: "99"
```
**File: `requests/if-none-match-1.txt`**
```text
If-None-Match: "1"
```

### Step 9. Format, check, run
```bash
gofmt -l .
go vet ./...
go run ./cmd/api
```
The development stand-in prints its warning first:
```text
time=2026-11-23T10:36:25.825+02:00 level=WARN msg="DEVELOPMENT AUTHENTICATION: the X-Dev-User header is trusted. Never run this build on a shared machine."
time=2026-11-23T10:36:25.826+02:00 level=INFO msg=listening addr=127.0.0.1:8000
time=2026-11-23T10:36:26.401+02:00 level=INFO msg=request method=GET path=/v1/me status=200 bytes=291 duration_ms=8.737 trace_id=911ceacdb74447921bbceae2977911aa user_id=a11ce000-0000-4000-8000-000000000001
time=2026-11-23T10:36:26.424+02:00 level=INFO msg=request method=GET path=/v1/me status=200 bytes=376 duration_ms=2.13 trace_id=c4606ed5c2d4a929373faedbab82adf8 user_id=b0b00000-0000-4000-8000-000000000002
time=2026-11-23T10:36:26.444+02:00 level=WARN msg=request method=GET path=/v1/me status=401 bytes=203 duration_ms=0 trace_id=ffe8801369bec84d479d74a66663b4f4
```

#### The `.gitignore` of this chapter (unchanged from chapter 01)
This chapter works with your own `.env`, so the `.gitignore` matters now. It is the same file as in chapter 01, shown again so you can check your copy.

<details>
<summary><code>.gitignore</code> (same as chapter 01)</summary>

**File: `.gitignore`**
```text
bin/
*.exe
.env
```

- `bin/`: compiled programs (`go build -o bin/...`); rebuilt on every machine.
- `*.exe`: Windows programs that `go build` writes next to the source. Any file ending in `.exe` is ignored.
- `.env`: your local copy of the platform settings. Never commit it; real secrets must never reach Git.

`.git` itself is never listed: Git does not track its own folder. `node_modules/` does not appear because this project has no Node.js part.
</details>

## Run it
The three seed users: **alice** `a11ce000-0000-4000-8000-000000000001` (admin, lead of Platform Team), **bob** `b0b00000-0000-4000-8000-000000000002` and **carol** `ca401000-0000-4000-8000-000000000003` (members). Platform Team has id `7ea00000-0000-4000-8000-000000000001`. All commands below use `-s -w "\nHTTP %{http_code}\n"` as in chapter 01.

1. Health now includes the database:
```bash
curl -s -w "\nHTTP %{http_code}\n" http://127.0.0.1:8000/health
```
```text
{"status":"ok","version":"1.0.0","database":"up"}
HTTP 200
```

2. Who am I? (alice, then bob, then nobody, then a user id that does not exist)
```bash
curl -s -w "\nHTTP %{http_code}\n" -H "X-Dev-User: a11ce000-0000-4000-8000-000000000001" -H "X-Dev-Roles: admin" http://127.0.0.1:8000/v1/me
curl -s -w "\nHTTP %{http_code}\n" -H "X-Dev-User: b0b00000-0000-4000-8000-000000000002" http://127.0.0.1:8000/v1/me
curl -s -w "\nHTTP %{http_code}\n" http://127.0.0.1:8000/v1/me
curl -s -w "\nHTTP %{http_code}\n" -H "X-Dev-User: 11111111-1111-4111-8111-111111111111" http://127.0.0.1:8000/v1/me
```
```text
{"id":"a11ce000-0000-4000-8000-000000000001","username":"alice","email":"alice@tasksteams.test","displayName":"Alice Admin","roles":["admin"],"scopes":["tasks:read","tasks:write","tasks:admin"],"teams":[{"teamId":"7ea00000-0000-4000-8000-000000000001","name":"Platform Team","role":"lead"}]}
HTTP 200
```
```text
{"id":"b0b00000-0000-4000-8000-000000000002","username":"bob","email":"bob@tasksteams.test","displayName":"Bob Member","roles":["member"],"scopes":["tasks:read","tasks:write","tasks:admin"],"teams":[{"teamId":"7ea00000-0000-4000-8000-000000000002","name":"Mobile Team","role":"member"},{"teamId":"7ea00000-0000-4000-8000-000000000001","name":"Platform Team","role":"member"}]}
HTTP 200
```
```text
{"type":"https://code101.example/problems/unauthorized","title":"Unauthorized","status":401,"detail":"A bearer access token is required.","instance":"/v1/me","traceId":"ffe8801369bec84d479d74a66663b4f4"}
HTTP 401
```
```text
{"type":"https://code101.example/problems/unauthorized","title":"Unauthorized","status":401,"detail":"The access token is invalid or expired.","instance":"/v1/me","traceId":"6198be18f916ac0eb1d5abe0dadfe59f"}
HTTP 401
```

3. Cursor pagination, one team per page (bob belongs to two teams). Copy `nextCursor` from the first answer into the second command:
```bash
curl -s -w "\nHTTP %{http_code}\n" -H "X-Dev-User: b0b00000-0000-4000-8000-000000000002" "http://127.0.0.1:8000/v1/teams?limit=1"
curl -s -w "\nHTTP %{http_code}\n" -H "X-Dev-User: b0b00000-0000-4000-8000-000000000002" "http://127.0.0.1:8000/v1/teams?limit=1&cursor=PASTE_NEXTCURSOR_HERE"
```
```text
{"items":[{"id":"7ea00000-0000-4000-8000-000000000002","name":"Mobile Team","description":"Builds the phone apps.","memberCount":2,"createdBy":"a11ce000-0000-4000-8000-000000000001","version":1,"createdAt":"2026-11-23T08:36:19.267336Z","updatedAt":"2026-11-23T08:36:19.267336Z"}],"page":{"limit":1,"nextCursor":"eyJzIjoidGVhbXM6LWNyZWF0ZWRBdCIsInQiOiIyMDI2LTExLTIzVDA4OjM2OjE5LjI2NzMzNloiLCJpIjoiN2VhMDAwMDAtMDAwMC00MDAwLTgwMDAtMDAwMDAwMDAwMDAyIn0"}}
HTTP 200
```
```text
{"items":[{"id":"7ea00000-0000-4000-8000-000000000001","name":"Platform Team","description":"Builds and runs the shared platform.","memberCount":3,"createdBy":"a11ce000-0000-4000-8000-000000000001","version":1,"createdAt":"2026-11-23T08:36:19.267336Z","updatedAt":"2026-11-23T08:36:19.267336Z"}],"page":{"limit":1,"nextCursor":null}}
HTTP 200
```
The second page has `"nextCursor":null`, the end of the list. Decode a cursor to see that it is only data: the text is base64url of `{"s":"teams:-createdAt","t":"...","i":"..."}`.

4. Search users by prefix:
```bash
curl -s -w "\nHTTP %{http_code}\n" -H "X-Dev-User: b0b00000-0000-4000-8000-000000000002" "http://127.0.0.1:8000/v1/users?q=c"
```
```text
{"items":[{"id":"ca401000-0000-4000-8000-000000000003","username":"carol","displayName":"Carol Member"}],"page":{"limit":25,"nextCursor":null}}
HTTP 200
```

5. Create a team (admin only). `-i` also shows the response headers: `Location` and the strong `ETag`.
```bash
curl -s -i -X POST -H "X-Dev-User: a11ce000-0000-4000-8000-000000000001" -H "X-Dev-Roles: admin" -H "Content-Type: application/json" --data-binary @requests/team-valid.json http://127.0.0.1:8000/v1/teams
```
```text
HTTP/1.1 201 Created
Content-Type: application/json
Etag: "1"
Location: http://localhost:8000/v1/teams/8d4d4549-1c8d-45e5-a2d0-79585568d731
X-Trace-Id: 3e0f8b920307ca59f5581851eed88b32
Date: Mon, 23 Nov 2026 08:36:26 GMT
Content-Length: 261

{"id":"8d4d4549-1c8d-45e5-a2d0-79585568d731","name":"Demo Team","description":"Created with curl","memberCount":1,"createdBy":"a11ce000-0000-4000-8000-000000000001","version":1,"createdAt":"2026-11-23T08:36:26.677938Z","updatedAt":"2026-11-23T08:36:26.677938Z"}
```
Go writes the header as `Etag`; HTTP header names are case-insensitive, clients treat `Etag` and `ETag` as the same.

6. Who may not: bob (member) creating a team, an invalid team, and an admin whose client only holds the read scope:
```bash
curl -s -w "\nHTTP %{http_code}\n" -X POST -H "X-Dev-User: b0b00000-0000-4000-8000-000000000002" -H "Content-Type: application/json" --data-binary @requests/team-valid.json http://127.0.0.1:8000/v1/teams
curl -s -w "\nHTTP %{http_code}\n" -X POST -H "X-Dev-User: a11ce000-0000-4000-8000-000000000001" -H "X-Dev-Roles: admin" -H "Content-Type: application/json" --data-binary @requests/team-invalid.json http://127.0.0.1:8000/v1/teams
curl -s -w "\nHTTP %{http_code}\n" -X POST -H "X-Dev-User: a11ce000-0000-4000-8000-000000000001" -H "X-Dev-Roles: admin" -H "X-Dev-Scopes: tasks:read" -H "Content-Type: application/json" --data-binary @requests/team-valid.json http://127.0.0.1:8000/v1/teams
```
```text
{"type":"https://code101.example/problems/forbidden","title":"Forbidden","status":403,"detail":"The admin role is required.","instance":"/v1/teams","traceId":"4f6f958558c9229437e0f778194f2854"}
HTTP 403
```
```text
{"type":"https://code101.example/problems/validation-error","title":"Validation failed","status":422,"detail":"One or more fields are invalid.","instance":"/v1/teams","traceId":"849f7dc9d88d942572625f05634d5f5a","errors":[{"pointer":"/name","detail":"must be between 1 and 80 characters"}]}
HTTP 422
```
```text
{"type":"https://code101.example/problems/forbidden","title":"Forbidden","status":403,"detail":"The token needs the scope tasks:write.","instance":"/v1/teams","traceId":"b570a4b3e8af38991e1de60333a99638"}
HTTP 403
```
**Roles and scopes are different checks** and both must pass: the role says what the person may do, the scope says what this client may do for them.

7. Read a team and its members as carol:
```bash
curl -s -w "\nHTTP %{http_code}\n" -H "X-Dev-User: ca401000-0000-4000-8000-000000000003" http://127.0.0.1:8000/v1/teams/7ea00000-0000-4000-8000-000000000001
curl -s -w "\nHTTP %{http_code}\n" -H "X-Dev-User: ca401000-0000-4000-8000-000000000003" http://127.0.0.1:8000/v1/teams/7ea00000-0000-4000-8000-000000000001/members
```
```text
{"id":"7ea00000-0000-4000-8000-000000000001","name":"Platform Team","description":"Builds and runs the shared platform.","memberCount":3,"createdBy":"a11ce000-0000-4000-8000-000000000001","version":1,"createdAt":"2026-11-23T08:36:19.267336Z","updatedAt":"2026-11-23T08:36:19.267336Z"}
HTTP 200
```
```text
{"items":[{"userId":"a11ce000-0000-4000-8000-000000000001","username":"alice","displayName":"Alice Admin","role":"lead","joinedAt":"2026-11-23T08:36:19.272202Z"},{"userId":"b0b00000-0000-4000-8000-000000000002","username":"bob","displayName":"Bob Member","role":"member","joinedAt":"2026-11-23T08:36:19.272202Z"},{"userId":"ca401000-0000-4000-8000-000000000003","username":"carol","displayName":"Carol Member","role":"member","joinedAt":"2026-11-23T08:36:19.272202Z"}],"page":{"limit":25,"nextCursor":null}}
HTTP 200
```

8. **Optimistic concurrency** with ETag and `If-Match`. The team is at version 1.
```bash
curl -s -w "\nHTTP %{http_code}\n" -X PATCH -H "X-Dev-User: a11ce000-0000-4000-8000-000000000001" -H "X-Dev-Roles: admin" -H "Content-Type: application/json" --data-binary @requests/team-patch.json http://127.0.0.1:8000/v1/teams/7ea00000-0000-4000-8000-000000000001
curl -s -w "\nHTTP %{http_code}\n" -X PATCH -H "X-Dev-User: a11ce000-0000-4000-8000-000000000001" -H "X-Dev-Roles: admin" -H "Content-Type: application/json" -H @requests/if-match-99.txt --data-binary @requests/team-patch.json http://127.0.0.1:8000/v1/teams/7ea00000-0000-4000-8000-000000000001
curl -s -w "\nHTTP %{http_code}\n" -X PATCH -H "X-Dev-User: a11ce000-0000-4000-8000-000000000001" -H "X-Dev-Roles: admin" -H "Content-Type: application/json" -H @requests/if-match-1.txt --data-binary @requests/team-patch.json http://127.0.0.1:8000/v1/teams/7ea00000-0000-4000-8000-000000000001
```
```text
{"type":"https://code101.example/problems/precondition-required","title":"Precondition required","status":428,"detail":"Send If-Match with the ETag you last read.","instance":"/v1/teams/7ea00000-0000-4000-8000-000000000001","traceId":"06c6106b1aae0c368c4f375a3f67efa5"}
HTTP 428
```
```text
{"type":"https://code101.example/problems/precondition-failed","title":"Precondition failed","status":412,"detail":"The resource changed since you read it (current version 1).","instance":"/v1/teams/7ea00000-0000-4000-8000-000000000001","traceId":"4db7e213f6f6c1b9f93fc00791de8441"}
HTTP 412
```
```text
{"id":"7ea00000-0000-4000-8000-000000000001","name":"Platform Team","description":"Updated with If-Match","memberCount":3,"createdBy":"a11ce000-0000-4000-8000-000000000001","version":2,"createdAt":"2026-11-23T08:36:19.267336Z","updatedAt":"2026-11-23T08:36:26.877635Z"}
HTTP 200
```
No header: `428`. A version that is no longer current: `412`. The right version: `200` and `"version":2`. Two people editing the same team can no longer overwrite each other silently: the second one gets `412`, reloads and decides.

9. Team members:
```bash
curl -s -w "\nHTTP %{http_code}\n" -X PUT -H "X-Dev-User: ca401000-0000-4000-8000-000000000003" -H "Content-Type: application/json" --data-binary @requests/member-put.json http://127.0.0.1:8000/v1/teams/7ea00000-0000-4000-8000-000000000001/members/b0b00000-0000-4000-8000-000000000002
curl -s -w "\nHTTP %{http_code}\n" -X PUT -H "X-Dev-User: a11ce000-0000-4000-8000-000000000001" -H "X-Dev-Roles: admin" -H "Content-Type: application/json" --data-binary @requests/member-put.json http://127.0.0.1:8000/v1/teams/7ea00000-0000-4000-8000-000000000001/members/b0b00000-0000-4000-8000-000000000002
curl -s -w "\nHTTP %{http_code}\n" -X DELETE -H "X-Dev-User: a11ce000-0000-4000-8000-000000000001" -H "X-Dev-Roles: admin" http://127.0.0.1:8000/v1/teams/7ea00000-0000-4000-8000-000000000001/members/a11ce000-0000-4000-8000-000000000001
```
```text
{"type":"https://code101.example/problems/forbidden","title":"Forbidden","status":403,"detail":"Only a team lead or an admin can do this.","instance":"/v1/teams/7ea00000-0000-4000-8000-000000000001/members/b0b00000-0000-4000-8000-000000000002","traceId":"4d88e819dff31d952d9b33bf87d55ff3"}
HTTP 403
```
```text
{"userId":"b0b00000-0000-4000-8000-000000000002","username":"bob","displayName":"Bob Member","role":"member","joinedAt":"2026-11-23T08:36:19.272202Z"}
HTTP 200
```
```text
{"type":"https://code101.example/problems/conflict","title":"Conflict","status":409,"detail":"A team must keep at least one lead.","instance":"/v1/teams/7ea00000-0000-4000-8000-000000000001/members/a11ce000-0000-4000-8000-000000000001","traceId":"0c6b0edcc6a6c2d6e4c8b344e9d7b844","code":"last_lead"}
HTTP 409
```
Carol is only a member of Platform Team: `403`. Alice may change roles: `200` (the member existed; a new member would be `201`). The last lead cannot be removed: `409` with the machine-readable `code`.

10. Projects, a duplicate key, an invalid body and a conditional GET:
```bash
curl -s -w "\nHTTP %{http_code}\n" -H "X-Dev-User: b0b00000-0000-4000-8000-000000000002" "http://127.0.0.1:8000/v1/teams/7ea00000-0000-4000-8000-000000000001/projects?limit=1"
curl -s -w "\nHTTP %{http_code}\n" -X POST -H "X-Dev-User: a11ce000-0000-4000-8000-000000000001" -H "X-Dev-Roles: admin" -H "Content-Type: application/json" --data-binary @requests/project-create.json http://127.0.0.1:8000/v1/teams/7ea00000-0000-4000-8000-000000000001/projects
curl -s -w "\nHTTP %{http_code}\n" -X POST -H "X-Dev-User: a11ce000-0000-4000-8000-000000000001" -H "X-Dev-Roles: admin" -H "Content-Type: application/json" --data-binary @requests/project-create.json http://127.0.0.1:8000/v1/teams/7ea00000-0000-4000-8000-000000000001/projects
curl -s -w "\nHTTP %{http_code}\n" -X POST -H "X-Dev-User: a11ce000-0000-4000-8000-000000000001" -H "X-Dev-Roles: admin" -H "Content-Type: application/json" --data-binary @requests/project-invalid.json http://127.0.0.1:8000/v1/teams/7ea00000-0000-4000-8000-000000000001/projects
curl -s -w "\nHTTP %{http_code}\n" -H "X-Dev-User: a11ce000-0000-4000-8000-000000000001" -H "X-Dev-Roles: admin" -H @requests/if-none-match-1.txt http://127.0.0.1:8000/v1/projects/9a000000-0000-4000-8000-000000000001
```
```text
{"items":[{"id":"9a000000-0000-4000-8000-000000000002","teamId":"7ea00000-0000-4000-8000-000000000001","key":"DOCS","name":"Documentation","description":"Guides and API reference.","archived":false,"version":1,"createdAt":"2026-11-23T08:36:19.275031Z","updatedAt":"2026-11-23T08:36:19.275031Z"}],"page":{"limit":1,"nextCursor":"eyJzIjoicHJvamVjdHM6LWNyZWF0ZWRBdCIsInQiOiIyMDI2LTExLTIzVDA4OjM2OjE5LjI3NTAzMVoiLCJpIjoiOWEwMDAwMDAtMDAwMC00MDAwLTgwMDAtMDAwMDAwMDAwMDAyIn0"}}
HTTP 200
```
```text
{"id":"4d61c15d-9818-44b9-b853-ec3595f773fb","teamId":"7ea00000-0000-4000-8000-000000000001","key":"NEW","name":"New project","description":"","archived":false,"version":1,"createdAt":"2026-11-23T08:36:26.997152Z","updatedAt":"2026-11-23T08:36:26.997152Z"}
HTTP 201
```
```text
{"type":"https://code101.example/problems/conflict","title":"Conflict","status":409,"detail":"A project with this key already exists in the team.","instance":"/v1/teams/7ea00000-0000-4000-8000-000000000001/projects","traceId":"19f11e7618cdad584efefcb1cf0919f5"}
HTTP 409
```
```text
{"type":"https://code101.example/problems/validation-error","title":"Validation failed","status":422,"detail":"One or more fields are invalid.","instance":"/v1/teams/7ea00000-0000-4000-8000-000000000001/projects","traceId":"0e3be907275d5ded5596b6e4b78880a2","errors":[{"pointer":"/key","detail":"must be 2 to 10 characters: a capital letter, then capital letters or digits"},{"pointer":"/name","detail":"must be between 1 and 120 characters"}]}
HTTP 422
```
```text
HTTP 304
```

11. Bad input never reaches the database:
```bash
curl -s -w "\nHTTP %{http_code}\n" -H "X-Dev-User: a11ce000-0000-4000-8000-000000000001" -H "X-Dev-Roles: admin" "http://127.0.0.1:8000/v1/teams?cursor=abc"
curl -s -w "\nHTTP %{http_code}\n" -H "X-Dev-User: a11ce000-0000-4000-8000-000000000001" -H "X-Dev-Roles: admin" http://127.0.0.1:8000/v1/teams/xyz
```
```text
{"type":"https://code101.example/problems/bad-request","title":"Bad request","status":400,"detail":"The cursor is not valid.","instance":"/v1/teams","traceId":"09e0eed8bd4100e7c29541c90c0fb2b0"}
HTTP 400
```
```text
{"type":"https://code101.example/problems/not-found","title":"Not found","status":404,"detail":"The resource does not exist.","instance":"/v1/teams/xyz","traceId":"95aa3cd8973b83fa4450fa73ae2dff87"}
HTTP 404
```

Stop the server (Ctrl+C), then clean up: `docker compose -p tasksteams down -v --remove-orphans`.

Conformance after this chapter (platform script, Keycloak and Postgres running):
```text
PASS  keycloak discovery (issuer matches, PKCE S256 offered)
PASS  token for alice (iss, aud tasks-api, sub, role admin, three scopes)
PASS  token for bob (role member only)
PASS  postgres reachable (127.0.0.1:5432 answers the Postgres protocol)
PASS  health (200, status ok, no token needed)
FAIL  me: expected HTTP 200, got 401: {"type":"https://code101.example/problems/unauthorized","title":"Unauthorized","status":401,"detail":"A bearer access token is required.","instance":"/v1/me","traceId":"f86e70795d5f43b36d9efe7e242b72e
FAIL  create team: expected HTTP 201, got 401: {"type":"https://code101.example/problems/unauthorized","title":"Unauthorized","status":401,"detail":"A bearer access token is required.","instance":"/v1/teams","traceId":"d3c71090868a59d5d1792dc6228f
FAIL  create project: needs the result of an earlier check (team)
FAIL  create task with Idempotency-Key: needs the result of an earlier check (project)
FAIL  get task with ETag: needs the result of an earlier check (task)
FAIL  update with If-Match: needs the result of an earlier check (task)
FAIL  stale If-Match gives 412: needs the result of an earlier check (task)
FAIL  cursor pagination: needs the result of an earlier check (project)
PASS  401 without token (401 problem details with a Bearer challenge)
FAIL  403 for member on admin route: expected HTTP 403, got 404: {"type":"https://code101.example/problems/not-found","title":"Not found","status":404,"detail":"There is no such path.","instance":"/v1/audit-log","traceId":"d10f4c183872a246026ecdd46a6656cc"}
FAIL  problem details shape: expected HTTP 422, got 401: {"type":"https://code101.example/problems/unauthorized","title":"Unauthorized","status":401,"detail":"A bearer access token is required.","instance":"/v1/teams","traceId":"1db7e56ecec874e87f7baabd393f
FAIL  audit log: needs the result of an earlier check (task)
FAIL  cleanup: needs the result of an earlier check (team)
6 passed, 12 failed
```

## How it works
```mermaid
sequenceDiagram
    autonumber
    participant C as Client
    participant H as HTTP layer
    participant S as store.WithUser
    participant D as Postgres
    C->>H: PATCH /v1/teams/{id} with If-Match "1"
    H->>H: authenticate, scope, authorize (404 or 403)
    H->>H: ifMatch (428), decode (400, 422), validate (422)
    H->>S: UpdateTeam(actor, id, expected 1, patch)
    S->>D: BEGIN
    S->>D: SELECT set_config('app.current_user_id', actor, true)
    S->>D: SELECT ... FROM teams WHERE id FOR UPDATE
    D-->>S: row, version 1
    S->>D: UPDATE teams SET ... (trigger: version 2, audit row with the actor)
    S->>D: COMMIT
    S-->>H: Team
    H-->>C: 200, ETag "2"
```
- The **layers** point one way: `cmd` to `http` to `store` and `auth` and `problem`. The `store` knows SQL but not HTTP; `http` knows status codes but not SQL.
- **DTO versus entity.** `store.Team` is what the database says; `teamDTO` is what the API promises. They look alike today; they will not tomorrow (a column added for internal use must not leak into the contract).
- **Parameterised queries only.** Every value reaches Postgres as a parameter. Even the dynamic filters add placeholders (`$3`), never text.
- **Least privilege.** The API connects as `tasks_app`, which can read and write rows, run the stored functions and append to the audit log, but cannot change the schema or edit the audit trail (see the grants at the end of `schema.sql`).
- **Locking.** `FOR UPDATE` plus a version comparison is *pessimistic locking inside a very short transaction* combined with *optimistic concurrency across requests*: the client never holds a lock, yet a stale write is detected.

New terms: **connection pool**, **driver**, **transaction**, **SQLSTATE**, **keyset pagination**, **ETag**, **If-Match**, **optimistic concurrency**, **JSON Merge Patch**, **principal**, **role**, **scope**, **generics**. See the [glossary](../../GLOSSARY.md).

Why this, not that:

| Decision | Alternative | Consequence |
|----------|-------------|-------------|
| Hand-written SQL in a `store` package | sqlc (generates the Go from `.sql` files), an ORM | Nothing to install or regenerate, and every query is visible; you maintain the column lists by hand. sqlc would generate the same functions from the same SQL and is a good next step |
| `pgx` native interface | `database/sql` plus the pgx stdlib adapter | Generic scanning helpers, `pgtype` and batches; the code is tied to pgx |
| Keyset pagination | `LIMIT`/`OFFSET` | Stable and fast, no page numbers |
| `If-Match` with the integer `version` | Compare `updated_at` | No clock problems; the trigger guarantees the number only grows |
| Stored function `create_team` | Two inserts from Go | The rule "a team always has a lead" exists once for every backend |

## Try it
**Exercise.** In `store/page.go` the function `likePrefix` makes the pattern for a "starts with" search. Write it yourself: lower-case the text, escape `\`, `%` and `_` with a backslash and add `%` at the end. Starter:

**File: `exercise/starter/main.go`**
```go
package main

import (
	"fmt"
	"strings"
)

// likePrefix builds the LIKE pattern for "starts with, ignoring case".
// TODO: lower-case the text, put a backslash in front of each backslash, percent sign and underscore,
// and add a percent sign at the end. Use strings.NewReplacer.
func likePrefix(s string) string {
	return s
}

func main() {
	for _, input := range []string{"Plat", "50%_off", `a\b`} {
		fmt.Printf("%-8s -> %s\n", input, likePrefix(input))
	}
	_ = strings.ToLower // remove this line once you use the strings package
}
```
Run `go run .` in a new folder with `go mod init exercise`. Before your change each line prints the input unchanged.

<details><summary>Solution</summary>

**File: `exercise/solution/main.go`**
```go
package main

import (
	"fmt"
	"strings"
)

var likeEscaper = strings.NewReplacer(`\`, `\\`, `%`, `\%`, `_`, `\_`)

// likePrefix builds the LIKE pattern for "starts with, ignoring case".
func likePrefix(s string) string {
	return likeEscaper.Replace(strings.ToLower(s)) + "%"
}

func main() {
	for _, input := range []string{"Plat", "50%_off", `a\b`} {
		fmt.Printf("%-8s -> %s\n", input, likePrefix(input))
	}
}
```
`strings.NewReplacer` replaces all pairs in one pass; doing three `strings.ReplaceAll` calls in the wrong order would escape the backslashes that the other two calls just added. Output:
```text
Plat     -> plat%
50%_off  -> 50\%\_off%
a\b      -> a\\b%
```
</details>

## Check yourself
1. Why does `set_config('app.current_user_id', $1, true)` use `true`?
   <details><summary>Answer</summary>The value then lasts only for the current transaction. A pooled connection serves many users; a session-wide value could leak one user's id into the next request's audit rows.</details>
2. A user who is not in a team asks for `GET /v1/teams/{id}`. 403 or 404? Why?
   <details><summary>Answer</summary>404. A 403 would confirm that the id exists. Only members get 403, for things they know exist but may not change.</details>
3. What happens when two clients PATCH the same team with `If-Match: "1"`?
   <details><summary>Answer</summary>The first locks the row, sees version 1, updates (version 2) and commits. The second waits for the lock, sees version 2 and gets `412 Precondition Failed`.</details>
4. Why does the store fetch `limit + 1` rows?
   <details><summary>Answer</summary>To know whether another page exists without a second `count` query. The extra row is dropped and only decides whether `nextCursor` is set.</details>

## Common mistakes
| Symptom or error text | Cause | Fix |
|---|---|---|
| `git status` lists `.env`, `bin/` or a `.exe` file as new files, or a password appears in a commit | `.gitignore` is missing, or it was created after the files were already tracked | Create the `.gitignore` shown above; for files already tracked run `git rm --cached .env` (and `git rm -r --cached bin`), commit, and replace any real secret that was ever committed |
| `If-Match must be a quoted version such as "3".` (HTTP 400) | The quotes of `"1"` were lost on the command line | Use `-H @requests/if-match-1.txt`, or in bash `-H 'If-Match: "1"'` |
| `{"status":"degraded","version":"1.0.0","database":"down"}` (HTTP 503) | Postgres is not reachable: not started, wrong port or wrong `DATABASE_URL` | `docker compose -p tasksteams up -d --wait db`; the server log names the cause |
| `The access token is invalid or expired.` for a header you typed | `X-Dev-User` is not a user of the `users` table (typo, or the volume was recreated with other data) | Use one of the three seed ids |
| The seed or schema seems ignored after you changed a `.sql` file | The init scripts run only on an empty data volume | `docker compose -p tasksteams down -v`, then `up` again |

The database-down answers, as the program prints them:
```text
{"status":"degraded","version":"1.0.0","database":"down"}
HTTP 503
```
```text
time=2026-11-23T10:36:31.806+02:00 level=WARN msg="DEVELOPMENT AUTHENTICATION: the X-Dev-User header is trusted. Never run this build on a shared machine."
time=2026-11-23T10:36:31.806+02:00 level=INFO msg=listening addr=127.0.0.1:18001
time=2026-11-23T10:36:32.320+02:00 level=WARN msg="health: database is down" error="failed to connect to `user=tasks_app database=tasksteams`:\n\t127.0.0.1:5999 (127.0.0.1): dial error: dial tcp 127.0.0.1:5999: connectex: No connection could be made because the target machine actively refused it.\n\t127.0.0.1:5999 (127.0.0.1): dial error: dial tcp 127.0.0.1:5999: connectex: No connection could be made because the target machine actively refused it."
time=2026-11-23T10:36:32.320+02:00 level=ERROR msg=request method=GET path=/health status=503 bytes=57 duration_ms=1.553 trace_id=5dcc768ec7c3bb66a3bad3985df38daf
```

## Best practice
Keep every SQL statement in one package, pass every value as a parameter, and run every write in a transaction that names the acting user. Source: pgx documentation https://pkg.go.dev/github.com/jackc/pgx/v5 and PostgreSQL 17 documentation, "Queries and parameters" https://www.postgresql.org/docs/17/sql-prepare.html and the OWASP SQL Injection Prevention Cheat Sheet https://cheatsheetseries.owasp.org/cheatsheets/SQL_Injection_Prevention_Cheat_Sheet.html

## Next lesson
03. Tasks and stored functions: the task endpoints with filtering, sorting, `complete_task` and `reassign_task`, comments and the audit trail.
