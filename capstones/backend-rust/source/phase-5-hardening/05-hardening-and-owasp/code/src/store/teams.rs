use sqlx::QueryBuilder;
use uuid::Uuid;

use super::{
    Store,
    page::{PageRequest, like_escape},
};
use crate::{
    auth::AuthUser,
    error::AppError,
    models::{Member, Page, Team, TeamCreate, TeamRole, TeamUpdate},
};

macro_rules! team_cols {
    () => {
        "t.id, t.name, t.description, (SELECT count(*) FROM team_members m WHERE m.team_id = t.id) AS member_count, \
         t.created_by, t.version, t.created_at, t.updated_at"
    };
}

macro_rules! member_cols {
    () => {
        "m.user_id, u.username, u.display_name, m.role, m.joined_at"
    };
}

/// What the caller may do inside one team. A non-member never gets an `Access`: they get a 404.
#[derive(Debug, Clone, Copy, PartialEq, Eq)]
pub enum Access {
    Admin,
    Lead,
    Member,
}

impl Access {
    pub fn require_lead(self) -> Result<(), AppError> {
        match self {
            Self::Admin | Self::Lead => Ok(()),
            Self::Member => Err(AppError::Forbidden("A team lead or an admin is required.".to_owned())),
        }
    }
}

impl Store {
    pub async fn team_access(&self, user: &AuthUser, team_id: Uuid) -> Result<Access, AppError> {
        let not_found = || AppError::NotFound("The team does not exist.".to_owned());
        if user.is_admin() {
            let exists: bool = sqlx::query_scalar("SELECT EXISTS (SELECT 1 FROM teams WHERE id = $1)")
                .bind(team_id)
                .fetch_one(&self.pool)
                .await?;
            return if exists { Ok(Access::Admin) } else { Err(not_found()) };
        }
        let role: Option<String> =
            sqlx::query_scalar("SELECT role FROM team_members WHERE team_id = $1 AND user_id = $2")
                .bind(team_id)
                .bind(user.id)
                .fetch_optional(&self.pool)
                .await?;
        match role.as_deref() {
            Some("lead") => Ok(Access::Lead),
            Some(_) => Ok(Access::Member),
            None => Err(not_found()),
        }
    }

    pub async fn team_of_project(&self, project_id: Uuid) -> Result<Uuid, AppError> {
        let team: Option<Uuid> = sqlx::query_scalar("SELECT team_id FROM projects WHERE id = $1")
            .bind(project_id)
            .fetch_optional(&self.pool)
            .await?;
        team.ok_or_else(|| AppError::NotFound("The project does not exist.".to_owned()))
    }

    pub async fn list_teams(
        &self,
        user: &AuthUser,
        q: Option<&str>,
        descending: bool,
        page: &PageRequest,
    ) -> Result<Page<Team>, AppError> {
        let mut query = QueryBuilder::new(concat!("SELECT ", team_cols!(), " FROM teams t WHERE TRUE"));
        if !user.is_admin() {
            query.push(" AND EXISTS (SELECT 1 FROM team_members x WHERE x.team_id = t.id AND x.user_id = ");
            query.push_bind(user.id).push(")");
        }
        if let Some(q) = q {
            query.push(" AND t.name ILIKE ").push_bind(format!("{}%", like_escape(q)));
        }
        page.keyset::<Uuid>(&mut query, "t.created_at", "t.id", descending)?;
        page.fetch(query, &self.pool, |team: &Team| (team.created_at, team.id)).await
    }

    pub async fn team(&self, team_id: Uuid) -> Result<Team, AppError> {
        let team = sqlx::query_as::<_, Team>(concat!("SELECT ", team_cols!(), " FROM teams t WHERE t.id = $1"))
            .bind(team_id)
            .fetch_optional(&self.pool)
            .await?;
        team.ok_or_else(|| AppError::NotFound("The team does not exist.".to_owned()))
    }

    /// Calls the stored function: team and first lead are created in one transaction.
    pub async fn create_team(&self, user: &AuthUser, body: &TeamCreate) -> Result<Team, AppError> {
        let lead = body.lead_user_id.unwrap_or(user.id);
        let id: Uuid = sqlx::query_scalar("SELECT id FROM create_team($1, $2, $3, $4)")
            .bind(&body.name)
            .bind(&body.description)
            .bind(lead)
            .bind(user.id)
            .fetch_one(&self.pool)
            .await?;
        self.team(id).await
    }

    pub async fn update_team(
        &self,
        user: &AuthUser,
        team_id: Uuid,
        expected_version: i32,
        body: &TeamUpdate,
    ) -> Result<Team, AppError> {
        let mut tx = self.begin_as(user.id).await?;
        let updated: Option<Uuid> = sqlx::query_scalar(
            "UPDATE teams SET name = COALESCE($3, name), description = COALESCE($4, description) \
             WHERE id = $1 AND version = $2 RETURNING id",
        )
        .bind(team_id)
        .bind(expected_version)
        .bind(&body.name)
        .bind(&body.description)
        .fetch_optional(&mut *tx)
        .await?;
        if updated.is_none() {
            let current: Option<i32> = sqlx::query_scalar("SELECT version FROM teams WHERE id = $1")
                .bind(team_id)
                .fetch_optional(&mut *tx)
                .await?;
            return Err(stale_or_missing("team", current));
        }
        tx.commit().await?;
        self.team(team_id).await
    }

    pub async fn delete_team(&self, user: &AuthUser, team_id: Uuid) -> Result<(), AppError> {
        let mut tx = self.begin_as(user.id).await?;
        let result = sqlx::query("DELETE FROM teams WHERE id = $1").bind(team_id).execute(&mut *tx).await?;
        if result.rows_affected() == 0 {
            return Err(AppError::NotFound("The team does not exist.".to_owned()));
        }
        tx.commit().await?;
        Ok(())
    }

    pub async fn list_members(&self, team_id: Uuid, page: &PageRequest) -> Result<Page<Member>, AppError> {
        let mut query = QueryBuilder::new(concat!(
            "SELECT ",
            member_cols!(),
            " FROM team_members m JOIN users u ON u.id = m.user_id WHERE m.team_id = "
        ));
        query.push_bind(team_id);
        page.keyset::<Uuid>(&mut query, "m.joined_at", "m.user_id", false)?;
        page.fetch(query, &self.pool, |member: &Member| (member.joined_at, member.user_id)).await
    }

    /// Adds a member or changes the role. Returns the member and whether it was newly added.
    pub async fn put_member(
        &self,
        user: &AuthUser,
        team_id: Uuid,
        member_id: Uuid,
        role: TeamRole,
    ) -> Result<(Member, bool), AppError> {
        let mut tx = self.begin_as(user.id).await?;
        let members = lock_members(&mut tx, team_id).await?;
        let existing = members.iter().find(|(id, _)| *id == member_id);
        let leads = members.iter().filter(|(_, role)| role == "lead").count();
        if matches!(existing, Some((_, current)) if current == "lead") && role != TeamRole::Lead && leads == 1 {
            return Err(last_lead());
        }
        let user_exists: bool = sqlx::query_scalar("SELECT EXISTS (SELECT 1 FROM users WHERE id = $1)")
            .bind(member_id)
            .fetch_one(&mut *tx)
            .await?;
        if !user_exists {
            return Err(AppError::NotFound("The user does not exist.".to_owned()));
        }
        sqlx::query(
            "INSERT INTO team_members (team_id, user_id, role) VALUES ($1, $2, $3) \
             ON CONFLICT (team_id, user_id) DO UPDATE SET role = EXCLUDED.role",
        )
        .bind(team_id)
        .bind(member_id)
        .bind(role.as_str())
        .execute(&mut *tx)
        .await?;
        tx.commit().await?;
        let member = sqlx::query_as::<_, Member>(concat!(
            "SELECT ",
            member_cols!(),
            " FROM team_members m JOIN users u ON u.id = m.user_id WHERE m.team_id = $1 AND m.user_id = $2"
        ))
        .bind(team_id)
        .bind(member_id)
        .fetch_one(&self.pool)
        .await?;
        Ok((member, existing.is_none()))
    }

    pub async fn remove_member(&self, user: &AuthUser, team_id: Uuid, member_id: Uuid) -> Result<(), AppError> {
        let mut tx = self.begin_as(user.id).await?;
        let members = lock_members(&mut tx, team_id).await?;
        let Some((_, role)) = members.iter().find(|(id, _)| *id == member_id) else {
            return Err(AppError::NotFound("The user is not a member of this team.".to_owned()));
        };
        if role == "lead" && members.iter().filter(|(_, role)| role == "lead").count() == 1 {
            return Err(last_lead());
        }
        sqlx::query("DELETE FROM team_members WHERE team_id = $1 AND user_id = $2")
            .bind(team_id)
            .bind(member_id)
            .execute(&mut *tx)
            .await?;
        tx.commit().await?;
        Ok(())
    }
}

/// Locks the member rows of a team, so two requests cannot both remove the last two leads.
async fn lock_members(tx: &mut super::Tx, team_id: Uuid) -> Result<Vec<(Uuid, String)>, AppError> {
    let members = sqlx::query_as("SELECT user_id, role FROM team_members WHERE team_id = $1 FOR UPDATE")
        .bind(team_id)
        .fetch_all(&mut **tx)
        .await?;
    Ok(members)
}

fn last_lead() -> AppError {
    AppError::Conflict { detail: "A team needs at least one lead.".to_owned(), code: Some("last_lead") }
}

/// After an UPDATE matched no row: the row is gone (404) or its version moved on (412).
pub fn stale_or_missing(what: &str, current: Option<i32>) -> AppError {
    match current {
        Some(version) => {
            AppError::PreconditionFailed(format!("The {what} changed since you read it (current version {version})."))
        }
        None => AppError::NotFound(format!("The {what} does not exist.")),
    }
}
