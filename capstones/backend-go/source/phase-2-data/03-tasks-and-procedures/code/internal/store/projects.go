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
