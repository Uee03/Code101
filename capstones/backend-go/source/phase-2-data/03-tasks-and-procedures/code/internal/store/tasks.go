package store

import (
	"context"
	"time"

	"github.com/jackc/pgx/v5"
)

// Task is a row of the tasks table.
type Task struct {
	ID          string
	ProjectID   string
	Title       string
	Description string
	Status      string
	Priority    string
	AssigneeID  *string
	DueDate     *time.Time
	CompletedAt *time.Time
	CreatedBy   string
	Version     int
	CreatedAt   time.Time
	UpdatedAt   time.Time
}

// The column order must match the fields of Task, because pgx scans by position.
// It also matches the column order of the tasks table, so "SELECT * FROM complete_task(...)" fits as well.
const taskColumns = `t.id, t.project_id, t.title, t.description, t.status, t.priority, t.assignee_id, t.due_date,
	t.completed_at, t.created_by, t.version, t.created_at, t.updated_at`

func (s *Store) GetTask(ctx context.Context, id string) (Task, error) {
	task, err := collectOne[Task](ctx, s.pool, "SELECT "+taskColumns+" FROM tasks t WHERE t.id = $1", id)
	return task, translateNoRows(err, "Task")
}

// TeamOfTask finds the team that owns a task, for the authorization check.
func (s *Store) TeamOfTask(ctx context.Context, taskID string) (string, error) {
	var teamID string
	err := s.pool.QueryRow(ctx,
		"SELECT p.team_id FROM tasks t JOIN projects p ON p.id = t.project_id WHERE t.id = $1", taskID).Scan(&teamID)
	return teamID, translateNoRows(mapError(err), "Task")
}

// TaskFilter holds the optional filters of a task list.
type TaskFilter struct {
	ProjectID  string
	Statuses   []string
	Priorities []string
	AssigneeID string
	DueBefore  *time.Time // inclusive
	DueAfter   *time.Time // inclusive
	Title      string     // case-insensitive substring
	Sort       string     // -createdAt, createdAt or dueDate
	Page       PageParams
}

func (s *Store) ListTasks(ctx context.Context, f TaskFilter) (Page[Task], error) {
	cursor, err := decodeCursor(f.Page.Cursor, "tasks:"+f.Sort, uuidID)
	if err != nil {
		return Page[Task]{}, err
	}
	var b builder
	b.where("t.project_id = " + b.arg(f.ProjectID))
	if len(f.Statuses) > 0 {
		b.where("t.status = ANY(" + b.arg(f.Statuses) + ")")
	}
	if len(f.Priorities) > 0 {
		b.where("t.priority = ANY(" + b.arg(f.Priorities) + ")")
	}
	if f.AssigneeID != "" {
		b.where("t.assignee_id = " + b.arg(f.AssigneeID))
	}
	if f.DueBefore != nil {
		b.where("t.due_date <= " + b.arg(*f.DueBefore))
	}
	if f.DueAfter != nil {
		b.where("t.due_date >= " + b.arg(*f.DueAfter))
	}
	if f.Title != "" {
		b.where("t.title ILIKE " + b.arg(likeContains(f.Title)))
	}
	var order string
	if f.Sort == "dueDate" {
		order = " ORDER BY t.due_date NULLS LAST, t.id"
		if err := afterDue(&b, cursor); err != nil {
			return Page[Task]{}, err
		}
	} else {
		desc := f.Sort == "-createdAt"
		order = orderBy("t.created_at", "t.id", desc)
		b.afterTime("t.created_at", "t.id", desc, cursor)
	}
	sql := "SELECT " + taskColumns + " FROM tasks t" + b.whereSQL() + order + " LIMIT " + b.arg(f.Page.Limit+1)
	items, err := collect[Task](ctx, s.pool, sql, b.args...)
	if err != nil {
		return Page[Task]{}, err
	}
	return finishPage(items, f.Page.Limit, func(t Task) Cursor {
		c := Cursor{Sort: "tasks:" + f.Sort, Time: t.CreatedAt, ID: t.ID}
		if t.DueDate != nil {
			c.Due = t.DueDate.Format(time.DateOnly)
		}
		return c
	}), nil
}

// afterDue adds the keyset condition for ORDER BY due_date NULLS LAST, id. A cursor with an empty Due
// sits inside the block of tasks without a due date, which comes last.
func afterDue(b *builder, c *Cursor) error {
	if c == nil {
		return nil
	}
	if c.Due == "" {
		b.where("(t.due_date IS NULL AND t.id > " + b.arg(c.ID) + ")")
		return nil
	}
	due, err := time.Parse(time.DateOnly, c.Due)
	if err != nil {
		return ErrBadCursor
	}
	b.where("(t.due_date IS NULL OR (t.due_date, t.id) > (" + b.arg(due) + ", " + b.arg(c.ID) + "))")
	return nil
}

// TaskInput is the data of a new task.
type TaskInput struct {
	Title       string
	Description string
	Priority    string
	AssigneeID  *string
	DueDate     *time.Time
}

var errAssignee = &Error{Kind: KindInvalid, Field: "/assigneeId", Message: "The assignee must be a member of the project's team."}

// assigneeBelongs reports whether the user is a member of the team that owns the project.
func assigneeBelongs(ctx context.Context, q querier, projectID, userID string) error {
	var ok bool
	err := q.QueryRow(ctx, `SELECT EXISTS (SELECT 1 FROM projects p JOIN team_members m ON m.team_id = p.team_id
		WHERE p.id = $1 AND m.user_id = $2)`, projectID, userID).Scan(&ok)
	if err != nil {
		return err
	}
	if !ok {
		return errAssignee
	}
	return nil
}

func (s *Store) CreateTask(ctx context.Context, actorID, projectID string, in TaskInput) (Task, error) {
	var task Task
	err := s.WithUser(ctx, actorID, func(tx pgx.Tx) error {
		if in.AssigneeID != nil {
			if err := assigneeBelongs(ctx, tx, projectID, *in.AssigneeID); err != nil {
				return err
			}
		}
		var err error
		task, err = collectOne[Task](ctx, tx, `INSERT INTO tasks AS t (project_id, title, description, priority, assignee_id, due_date, created_by)
			VALUES ($1, $2, $3, $4, $5, $6, $7) RETURNING `+taskColumns,
			projectID, in.Title, in.Description, in.Priority, in.AssigneeID, in.DueDate, actorID)
		return err
	})
	return task, err
}

// TaskPatch holds a JSON Merge Patch. For assignee and due date a nil pointer is ambiguous, so the Set flags
// tell "leave it" from "clear it".
type TaskPatch struct {
	Title       *string
	Description *string
	Status      *string
	Priority    *string
	SetAssignee bool
	AssigneeID  *string
	SetDueDate  bool
	DueDate     *time.Time
}

// UpdateTask applies a patch to the locked row if its version is still expected (0 skips the check).
func (s *Store) UpdateTask(ctx context.Context, actorID, id string, expected int, patch TaskPatch) (Task, error) {
	var task Task
	err := s.WithUser(ctx, actorID, func(tx pgx.Tx) error {
		current, err := collectOne[Task](ctx, tx, "SELECT "+taskColumns+" FROM tasks t WHERE t.id = $1 FOR UPDATE", id)
		if err != nil {
			return translateNoRows(err, "Task")
		}
		if expected != 0 && current.Version != expected {
			return stale(current.Version)
		}
		next := current
		if patch.Title != nil {
			next.Title = *patch.Title
		}
		if patch.Description != nil {
			next.Description = *patch.Description
		}
		if patch.Status != nil {
			next.Status = *patch.Status
		}
		if patch.Priority != nil {
			next.Priority = *patch.Priority
		}
		if patch.SetAssignee {
			next.AssigneeID = patch.AssigneeID
			if next.AssigneeID != nil {
				if err := assigneeBelongs(ctx, tx, current.ProjectID, *next.AssigneeID); err != nil {
					return err
				}
			}
		}
		if patch.SetDueDate {
			next.DueDate = patch.DueDate
		}
		task, err = collectOne[Task](ctx, tx, `UPDATE tasks AS t SET title = $2, description = $3, status = $4, priority = $5,
			assignee_id = $6, due_date = $7 WHERE t.id = $1 RETURNING `+taskColumns,
			id, next.Title, next.Description, next.Status, next.Priority, next.AssigneeID, next.DueDate)
		return err
	})
	return task, err
}

// DeleteTask removes a task; when expected is not 0 the version must match.
func (s *Store) DeleteTask(ctx context.Context, actorID, id string, expected int) error {
	return s.WithUser(ctx, actorID, func(tx pgx.Tx) error {
		var version int
		if err := tx.QueryRow(ctx, "SELECT version FROM tasks WHERE id = $1 FOR UPDATE", id).Scan(&version); err != nil {
			return translateNoRows(mapError(err), "Task")
		}
		if expected != 0 && version != expected {
			return stale(version)
		}
		_, err := tx.Exec(ctx, "DELETE FROM tasks WHERE id = $1", id)
		return err
	})
}

// expectedArg turns "no precondition" (0) into SQL NULL, which the stored functions read as "skip the check".
func expectedArg(expected int) *int {
	if expected == 0 {
		return nil
	}
	return &expected
}

// CompleteTask calls the complete_task stored function, which locks the row, checks the version and the rules.
func (s *Store) CompleteTask(ctx context.Context, actorID, id string, expected int) (Task, error) {
	var task Task
	err := s.WithUser(ctx, actorID, func(tx pgx.Tx) error {
		var err error
		task, err = collectOne[Task](ctx, tx, "SELECT * FROM complete_task($1, $2, $3)", id, actorID, expectedArg(expected))
		return err
	})
	return task, err
}

// ReassignTask calls the reassign_task stored function. A nil assignee unassigns the task.
func (s *Store) ReassignTask(ctx context.Context, actorID, id string, assigneeID *string, expected int) (Task, error) {
	var task Task
	err := s.WithUser(ctx, actorID, func(tx pgx.Tx) error {
		var err error
		task, err = collectOne[Task](ctx, tx, "SELECT * FROM reassign_task($1, $2, $3, $4)", id, assigneeID, actorID, expectedArg(expected))
		return err
	})
	return task, err
}
