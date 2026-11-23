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
