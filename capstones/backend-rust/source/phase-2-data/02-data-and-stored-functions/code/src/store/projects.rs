use sqlx::QueryBuilder;
use uuid::Uuid;

use super::{Store, page::PageRequest, teams::stale_or_missing};
use crate::{
    auth::AuthUser,
    error::AppError,
    models::{Page, Project, ProjectCreate, ProjectUpdate},
};

macro_rules! project_cols {
    () => {
        "p.id, p.team_id, p.key, p.name, p.description, p.archived, p.version, p.created_at, p.updated_at"
    };
}

impl Store {
    pub async fn list_projects(
        &self,
        team_id: Uuid,
        archived: bool,
        descending: bool,
        page: &PageRequest,
    ) -> Result<Page<Project>, AppError> {
        let mut query = QueryBuilder::new(concat!("SELECT ", project_cols!(), " FROM projects p WHERE p.team_id = "));
        query.push_bind(team_id);
        if !archived {
            query.push(" AND NOT p.archived");
        }
        page.keyset::<Uuid>(&mut query, "p.created_at", "p.id", descending)?;
        page.fetch(query, &self.pool, |project: &Project| (project.created_at, project.id)).await
    }

    pub async fn project(&self, project_id: Uuid) -> Result<Project, AppError> {
        let project =
            sqlx::query_as::<_, Project>(concat!("SELECT ", project_cols!(), " FROM projects p WHERE p.id = $1"))
                .bind(project_id)
                .fetch_optional(&self.pool)
                .await?;
        project.ok_or_else(|| AppError::NotFound("The project does not exist.".to_owned()))
    }

    pub async fn create_project(
        &self,
        user: &AuthUser,
        team_id: Uuid,
        body: &ProjectCreate,
    ) -> Result<Project, AppError> {
        let mut tx = self.begin_as(user.id).await?;
        let project = sqlx::query_as::<_, Project>(concat!(
            "INSERT INTO projects AS p (team_id, key, name, description, created_by) VALUES ($1, $2, $3, $4, $5) ",
            "RETURNING ",
            project_cols!()
        ))
        .bind(team_id)
        .bind(&body.key)
        .bind(&body.name)
        .bind(&body.description)
        .bind(user.id)
        .fetch_one(&mut *tx)
        .await?;
        tx.commit().await?;
        Ok(project)
    }

    pub async fn update_project(
        &self,
        user: &AuthUser,
        project_id: Uuid,
        expected_version: i32,
        body: &ProjectUpdate,
    ) -> Result<Project, AppError> {
        let mut tx = self.begin_as(user.id).await?;
        let updated = sqlx::query_as::<_, Project>(concat!(
            "UPDATE projects p SET name = COALESCE($3, p.name), description = COALESCE($4, p.description), ",
            "archived = COALESCE($5, p.archived) WHERE p.id = $1 AND p.version = $2 RETURNING ",
            project_cols!()
        ))
        .bind(project_id)
        .bind(expected_version)
        .bind(&body.name)
        .bind(&body.description)
        .bind(body.archived)
        .fetch_optional(&mut *tx)
        .await?;
        let Some(project) = updated else {
            let current: Option<i32> = sqlx::query_scalar("SELECT version FROM projects WHERE id = $1")
                .bind(project_id)
                .fetch_optional(&mut *tx)
                .await?;
            return Err(stale_or_missing("project", current));
        };
        tx.commit().await?;
        Ok(project)
    }

    pub async fn delete_project(&self, user: &AuthUser, project_id: Uuid) -> Result<(), AppError> {
        let mut tx = self.begin_as(user.id).await?;
        let result = sqlx::query("DELETE FROM projects WHERE id = $1").bind(project_id).execute(&mut *tx).await?;
        if result.rows_affected() == 0 {
            return Err(AppError::NotFound("The project does not exist.".to_owned()));
        }
        tx.commit().await?;
        Ok(())
    }
}
