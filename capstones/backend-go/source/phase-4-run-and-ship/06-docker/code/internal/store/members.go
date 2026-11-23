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
