use sqlx::QueryBuilder;
use uuid::Uuid;

use super::{Store, page::PageRequest};
use crate::{
    auth::AuthUser,
    error::AppError,
    models::{Comment, CommentRow, Page},
};

macro_rules! comment_cols {
    () => {
        "c.id, c.task_id, c.author_id, u.username AS author_username, \
         u.display_name AS author_display_name, c.body, c.created_at"
    };
}

impl Store {
    pub async fn list_comments(&self, task_id: Uuid, page: &PageRequest) -> Result<Page<Comment>, AppError> {
        let mut query = QueryBuilder::new(concat!(
            "SELECT ",
            comment_cols!(),
            " FROM comments c JOIN users u ON u.id = c.author_id WHERE c.task_id = "
        ));
        query.push_bind(task_id);
        page.keyset::<Uuid>(&mut query, "c.created_at", "c.id", false)?;
        let rows = page.fetch(query, &self.pool, |row: &CommentRow| (row.created_at, row.id)).await?;
        Ok(Page { items: rows.items.into_iter().map(Comment::from).collect(), page: rows.page })
    }

    pub async fn create_comment(&self, user: &AuthUser, task_id: Uuid, body: &str) -> Result<Comment, AppError> {
        let mut tx = self.begin_as(user.id).await?;
        let id: Uuid =
            sqlx::query_scalar("INSERT INTO comments (task_id, author_id, body) VALUES ($1, $2, $3) RETURNING id")
                .bind(task_id)
                .bind(user.id)
                .bind(body)
                .fetch_one(&mut *tx)
                .await?;
        tx.commit().await?;
        let row = sqlx::query_as::<_, CommentRow>(concat!(
            "SELECT ",
            comment_cols!(),
            " FROM comments c JOIN users u ON u.id = c.author_id WHERE c.id = $1"
        ))
        .bind(id)
        .fetch_one(&self.pool)
        .await?;
        Ok(row.into())
    }

    /// The team of the comment's task and the comment's author, for the delete permission check.
    pub async fn comment_context(&self, comment_id: Uuid) -> Result<(Uuid, Uuid), AppError> {
        let context: Option<(Uuid, Uuid)> = sqlx::query_as(
            "SELECT p.team_id, c.author_id FROM comments c JOIN tasks t ON t.id = c.task_id \
             JOIN projects p ON p.id = t.project_id WHERE c.id = $1",
        )
        .bind(comment_id)
        .fetch_optional(&self.pool)
        .await?;
        context.ok_or_else(|| AppError::NotFound("The comment does not exist.".to_owned()))
    }

    pub async fn delete_comment(&self, user: &AuthUser, comment_id: Uuid) -> Result<(), AppError> {
        let mut tx = self.begin_as(user.id).await?;
        let result = sqlx::query("DELETE FROM comments WHERE id = $1").bind(comment_id).execute(&mut *tx).await?;
        if result.rows_affected() == 0 {
            return Err(AppError::NotFound("The comment does not exist.".to_owned()));
        }
        tx.commit().await?;
        Ok(())
    }
}
