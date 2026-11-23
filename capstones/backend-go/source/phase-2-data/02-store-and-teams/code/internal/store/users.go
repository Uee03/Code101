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
