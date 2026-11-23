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
	Field   string // optional JSON Pointer of the request field that caused a KindInvalid error
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
