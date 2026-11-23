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
