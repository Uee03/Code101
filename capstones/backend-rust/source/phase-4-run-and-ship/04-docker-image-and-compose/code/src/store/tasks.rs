use std::str::FromStr;

use chrono::NaiveDate;
use serde_json::json;
use sqlx::QueryBuilder;
use uuid::Uuid;

use super::{
    Store,
    page::{PageRequest, decode_cursor, like_escape},
    teams::stale_or_missing,
};
use crate::{
    auth::AuthUser,
    error::{AppError, FieldError},
    models::{Page, Task, TaskCreate, TaskPriority, TaskStatus, TaskUpdate},
};

macro_rules! task_cols {
    () => {
        "t.id, t.project_id, t.title, t.description, t.status, t.priority, t.assignee_id, \
         t.due_date, t.completed_at, t.created_by, t.version, t.created_at, t.updated_at"
    };
}

#[derive(Debug, Clone, Copy, Default, PartialEq, Eq)]
pub enum TaskSort {
    #[default]
    CreatedDesc,
    CreatedAsc,
    DueDate,
}

impl FromStr for TaskSort {
    type Err = ();

    fn from_str(text: &str) -> Result<Self, ()> {
        match text {
            "-createdAt" => Ok(Self::CreatedDesc),
            "createdAt" => Ok(Self::CreatedAsc),
            "dueDate" => Ok(Self::DueDate),
            _ => Err(()),
        }
    }
}

#[derive(Debug, Default)]
pub struct TaskFilter {
    pub statuses: Vec<TaskStatus>,
    pub priorities: Vec<TaskPriority>,
    pub assignee_id: Option<Uuid>,
    pub due_before: Option<NaiveDate>,
    pub due_after: Option<NaiveDate>,
    pub q: Option<String>,
    pub sort: TaskSort,
}

impl Store {
    pub async fn list_tasks(
        &self,
        project_id: Uuid,
        filter: &TaskFilter,
        page: &PageRequest,
    ) -> Result<Page<Task>, AppError> {
        let mut query = QueryBuilder::new(concat!("SELECT ", task_cols!(), " FROM tasks t WHERE t.project_id = "));
        query.push_bind(project_id);
        if !filter.statuses.is_empty() {
            let names: Vec<String> = filter.statuses.iter().map(|s| s.as_str().to_owned()).collect();
            query.push(" AND t.status = ANY(").push_bind(names).push(")");
        }
        if !filter.priorities.is_empty() {
            let names: Vec<String> = filter.priorities.iter().map(|p| p.as_str().to_owned()).collect();
            query.push(" AND t.priority = ANY(").push_bind(names).push(")");
        }
        if let Some(assignee) = filter.assignee_id {
            query.push(" AND t.assignee_id = ").push_bind(assignee);
        }
        if let Some(day) = filter.due_before {
            query.push(" AND t.due_date <= ").push_bind(day);
        }
        if let Some(day) = filter.due_after {
            query.push(" AND t.due_date >= ").push_bind(day);
        }
        if let Some(q) = &filter.q {
            query.push(" AND t.title ILIKE ").push_bind(format!("%{}%", like_escape(q)));
        }
        let by_due_date = filter.sort == TaskSort::DueDate;
        match filter.sort {
            TaskSort::CreatedDesc => page.keyset::<Uuid>(&mut query, "t.created_at", "t.id", true)?,
            TaskSort::CreatedAsc => page.keyset::<Uuid>(&mut query, "t.created_at", "t.id", false)?,
            TaskSort::DueDate => {
                // Tasks without a due date come last, so "after the cursor" has a special case for NULL.
                if let Some(cursor) = &page.cursor {
                    let (due, last_id): (Option<NaiveDate>, Uuid) = decode_cursor(cursor)?;
                    match due {
                        Some(due) => {
                            query.push(" AND (t.due_date > ").push_bind(due);
                            query.push(" OR (t.due_date = ").push_bind(due);
                            query.push(" AND t.id > ").push_bind(last_id);
                            query.push(") OR t.due_date IS NULL)");
                        }
                        None => {
                            query.push(" AND t.due_date IS NULL AND t.id > ").push_bind(last_id);
                        }
                    }
                }
                page.order_and_limit(&mut query, "t.due_date ASC NULLS LAST, t.id ASC");
            }
        }
        let next_key = |task: &Task| {
            if by_due_date { json!([task.due_date, task.id]) } else { json!([task.created_at, task.id]) }
        };
        page.fetch(query, &self.pool, next_key).await
    }

    pub async fn task(&self, task_id: Uuid) -> Result<Task, AppError> {
        let task = sqlx::query_as::<_, Task>(concat!("SELECT ", task_cols!(), " FROM tasks t WHERE t.id = $1"))
            .bind(task_id)
            .fetch_optional(&self.pool)
            .await?;
        task.ok_or_else(|| AppError::NotFound("The task does not exist.".to_owned()))
    }

    pub async fn create_task(&self, user: &AuthUser, project_id: Uuid, body: &TaskCreate) -> Result<Task, AppError> {
        if let Some(assignee) = body.assignee_id {
            self.ensure_assignable(project_id, assignee).await?;
        }
        let mut tx = self.begin_as(user.id).await?;
        let task = sqlx::query_as::<_, Task>(concat!(
            "INSERT INTO tasks AS t (project_id, title, description, priority, assignee_id, due_date, created_by) ",
            "VALUES ($1, $2, $3, COALESCE($4, 'medium'), $5, $6, $7) RETURNING ",
            task_cols!()
        ))
        .bind(project_id)
        .bind(&body.title)
        .bind(&body.description)
        .bind(body.priority.map(|p| p.as_str()))
        .bind(body.assignee_id)
        .bind(body.due_date)
        .bind(user.id)
        .fetch_one(&mut *tx)
        .await?;
        tx.commit().await?;
        Ok(task)
    }

    /// JSON Merge Patch: `COALESCE` keeps absent fields; the CASE flags tell "absent" from an explicit `null`.
    pub async fn update_task(
        &self,
        user: &AuthUser,
        task: &Task,
        expected_version: i32,
        body: &TaskUpdate,
    ) -> Result<Task, AppError> {
        let (set_assignee, assignee) = match body.assignee_id {
            Some(value) => (true, value),
            None => (false, None),
        };
        let (set_due_date, due_date) = match body.due_date {
            Some(value) => (true, value),
            None => (false, None),
        };
        if let Some(assignee) = assignee {
            self.ensure_assignable(task.project_id, assignee).await?;
        }
        let mut tx = self.begin_as(user.id).await?;
        let updated = sqlx::query_as::<_, Task>(concat!(
            "UPDATE tasks t SET title = COALESCE($3, t.title), description = COALESCE($4, t.description), ",
            "status = COALESCE($5, t.status), priority = COALESCE($6, t.priority), ",
            "assignee_id = CASE WHEN $7 THEN $8 ELSE t.assignee_id END, ",
            "due_date = CASE WHEN $9 THEN $10 ELSE t.due_date END ",
            "WHERE t.id = $1 AND t.version = $2 RETURNING ",
            task_cols!()
        ))
        .bind(task.id)
        .bind(expected_version)
        .bind(&body.title)
        .bind(&body.description)
        .bind(body.status.map(|s| s.as_str()))
        .bind(body.priority.map(|p| p.as_str()))
        .bind(set_assignee)
        .bind(assignee)
        .bind(set_due_date)
        .bind(due_date)
        .fetch_optional(&mut *tx)
        .await?;
        let Some(updated) = updated else {
            let current: Option<i32> = sqlx::query_scalar("SELECT version FROM tasks WHERE id = $1")
                .bind(task.id)
                .fetch_optional(&mut *tx)
                .await?;
            return Err(stale_or_missing("task", current));
        };
        tx.commit().await?;
        Ok(updated)
    }

    pub async fn delete_task(&self, user: &AuthUser, task_id: Uuid, expected: Option<i32>) -> Result<(), AppError> {
        let mut tx = self.begin_as(user.id).await?;
        let current: Option<i32> = sqlx::query_scalar("SELECT version FROM tasks WHERE id = $1 FOR UPDATE")
            .bind(task_id)
            .fetch_optional(&mut *tx)
            .await?;
        match (current, expected) {
            (None, _) => return Err(stale_or_missing("task", None)),
            (Some(version), Some(expected)) if version != expected => {
                return Err(stale_or_missing("task", Some(version)));
            }
            _ => {}
        }
        sqlx::query("DELETE FROM tasks WHERE id = $1").bind(task_id).execute(&mut *tx).await?;
        tx.commit().await?;
        Ok(())
    }

    /// The stored function locks the row, checks the version and the rules, and stamps `completed_at`.
    pub async fn complete_task(&self, user: &AuthUser, task_id: Uuid, expected_version: i32) -> Result<Task, AppError> {
        let task = sqlx::query_as::<_, Task>(concat!("SELECT ", task_cols!(), " FROM complete_task($1, $2, $3) t"))
            .bind(task_id)
            .bind(user.id)
            .bind(expected_version)
            .fetch_one(&self.pool)
            .await?;
        Ok(task)
    }

    pub async fn reassign_task(
        &self,
        user: &AuthUser,
        task_id: Uuid,
        assignee: Option<Uuid>,
        expected_version: i32,
    ) -> Result<Task, AppError> {
        let task = sqlx::query_as::<_, Task>(concat!("SELECT ", task_cols!(), " FROM reassign_task($1, $2, $3, $4) t"))
            .bind(task_id)
            .bind(assignee)
            .bind(user.id)
            .bind(expected_version)
            .fetch_one(&self.pool)
            .await?;
        Ok(task)
    }

    async fn ensure_assignable(&self, project_id: Uuid, assignee: Uuid) -> Result<(), AppError> {
        let member: bool = sqlx::query_scalar(
            "SELECT EXISTS (SELECT 1 FROM projects p JOIN team_members m ON m.team_id = p.team_id \
             WHERE p.id = $1 AND m.user_id = $2)",
        )
        .bind(project_id)
        .bind(assignee)
        .fetch_one(&self.pool)
        .await?;
        if member {
            Ok(())
        } else {
            Err(AppError::Validation(vec![FieldError::new("/assigneeId", "must be a member of the project's team")]))
        }
    }
}
