package store

import (
	"context"
	"time"

	"github.com/jackc/pgx/v5"
)

// Comment is a comment with the public profile of its author.
type Comment struct {
	ID                string
	TaskID            string
	AuthorID          string
	AuthorUsername    string
	AuthorDisplayName string
	Body              string
	CreatedAt         time.Time
}

const commentColumns = "c.id, c.task_id, c.author_id, u.username, u.display_name, c.body, c.created_at"

// ListComments returns the comments of a task, oldest first.
func (s *Store) ListComments(ctx context.Context, taskID string, page PageParams) (Page[Comment], error) {
	cursor, err := decodeCursor(page.Cursor, "comments", uuidID)
	if err != nil {
		return Page[Comment]{}, err
	}
	var b builder
	b.where("c.task_id = " + b.arg(taskID))
	b.afterTime("c.created_at", "c.id", false, cursor)
	sql := "SELECT " + commentColumns + " FROM comments c JOIN users u ON u.id = c.author_id" + b.whereSQL() +
		orderBy("c.created_at", "c.id", false) + " LIMIT " + b.arg(page.Limit+1)
	items, err := collect[Comment](ctx, s.pool, sql, b.args...)
	if err != nil {
		return Page[Comment]{}, err
	}
	return finishPage(items, page.Limit, func(c Comment) Cursor {
		return Cursor{Sort: "comments", Time: c.CreatedAt, ID: c.ID}
	}), nil
}

func (s *Store) CreateComment(ctx context.Context, actorID, taskID, body string) (Comment, error) {
	var comment Comment
	err := s.WithUser(ctx, actorID, func(tx pgx.Tx) error {
		var id string
		if err := tx.QueryRow(ctx, "INSERT INTO comments (task_id, author_id, body) VALUES ($1, $2, $3) RETURNING id",
			taskID, actorID, body).Scan(&id); err != nil {
			return err
		}
		var err error
		comment, err = collectOne[Comment](ctx, tx, "SELECT "+commentColumns+" FROM comments c JOIN users u ON u.id = c.author_id WHERE c.id = $1", id)
		return err
	})
	return comment, err
}

// CommentOwner returns the team that owns a comment and the id of its author, for the authorization check.
func (s *Store) CommentOwner(ctx context.Context, commentID string) (teamID, authorID string, err error) {
	err = s.pool.QueryRow(ctx, `SELECT p.team_id, c.author_id FROM comments c
		JOIN tasks t ON t.id = c.task_id JOIN projects p ON p.id = t.project_id WHERE c.id = $1`, commentID).Scan(&teamID, &authorID)
	return teamID, authorID, translateNoRows(mapError(err), "Comment")
}

func (s *Store) DeleteComment(ctx context.Context, actorID, id string) error {
	return s.WithUser(ctx, actorID, func(tx pgx.Tx) error {
		tag, err := tx.Exec(ctx, "DELETE FROM comments WHERE id = $1", id)
		if err != nil {
			return err
		}
		if tag.RowsAffected() == 0 {
			return notFound("Comment")
		}
		return nil
	})
}
