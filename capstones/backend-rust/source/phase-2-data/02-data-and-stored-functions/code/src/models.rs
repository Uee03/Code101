use chrono::{DateTime, NaiveDate, Utc};
use serde::{Deserialize, Deserializer, Serialize};
use sqlx::FromRow;
use uuid::Uuid;

use crate::{
    error::AppError,
    validation::{Check, Validate},
};

/// Declares a text enum: serde names, `as_str` for SQL binds and `FromStr` for query parameters.
macro_rules! string_enum {
    ($name:ident { $($variant:ident => $text:literal),+ $(,)? }) => {
        #[derive(Debug, Clone, Copy, PartialEq, Eq, Serialize, Deserialize)]
        pub enum $name {
            $( #[serde(rename = $text)] $variant ),+
        }

        impl $name {
            pub fn as_str(self) -> &'static str {
                match self { $( Self::$variant => $text ),+ }
            }
        }

        impl std::str::FromStr for $name {
            type Err = ();

            fn from_str(text: &str) -> Result<Self, ()> {
                match text { $( $text => Ok(Self::$variant), )+ _ => Err(()) }
            }
        }
    };
}

string_enum!(TeamRole { Lead => "lead", Member => "member" });
string_enum!(TaskStatus { Todo => "todo", InProgress => "in_progress", Blocked => "blocked", Done => "done", Cancelled => "cancelled" });
string_enum!(TaskPriority { Low => "low", Medium => "medium", High => "high", Urgent => "urgent" });
string_enum!(EntityType { Team => "team", Member => "member", Project => "project", Task => "task", Comment => "comment" });

// Responses -----------------------------------------------------------------

#[derive(Debug, Serialize)]
pub struct Health {
    pub status: &'static str,
    pub version: &'static str,
    #[serde(skip_serializing_if = "Option::is_none")]
    pub database: Option<&'static str>,
}

#[derive(Debug, Serialize)]
#[serde(rename_all = "camelCase")]
pub struct PageInfo {
    pub limit: i64,
    pub next_cursor: Option<String>,
}

#[derive(Debug, Serialize)]
pub struct Page<T> {
    pub items: Vec<T>,
    pub page: PageInfo,
}

#[derive(Debug, Serialize)]
#[serde(rename_all = "camelCase")]
pub struct Me {
    pub id: Uuid,
    pub username: String,
    pub email: String,
    pub display_name: String,
    pub roles: Vec<String>,
    pub scopes: Vec<String>,
    pub teams: Vec<MeTeam>,
}

#[derive(Debug, Serialize, FromRow)]
#[serde(rename_all = "camelCase")]
pub struct MeTeam {
    pub team_id: Uuid,
    pub name: String,
    pub role: String,
}

#[derive(Debug, Serialize, FromRow)]
#[serde(rename_all = "camelCase")]
pub struct UserSummary {
    pub id: Uuid,
    pub username: String,
    pub display_name: String,
}

#[derive(Debug, Serialize, FromRow)]
#[serde(rename_all = "camelCase")]
pub struct Team {
    pub id: Uuid,
    pub name: String,
    pub description: String,
    pub member_count: i64,
    pub created_by: Uuid,
    pub version: i32,
    pub created_at: DateTime<Utc>,
    pub updated_at: DateTime<Utc>,
}

#[derive(Debug, Serialize, FromRow)]
#[serde(rename_all = "camelCase")]
pub struct Member {
    pub user_id: Uuid,
    pub username: String,
    pub display_name: String,
    pub role: String,
    pub joined_at: DateTime<Utc>,
}

#[derive(Debug, Serialize, FromRow)]
#[serde(rename_all = "camelCase")]
pub struct Project {
    pub id: Uuid,
    pub team_id: Uuid,
    pub key: String,
    pub name: String,
    pub description: String,
    pub archived: bool,
    pub version: i32,
    pub created_at: DateTime<Utc>,
    pub updated_at: DateTime<Utc>,
}

#[derive(Debug, Serialize, FromRow)]
#[serde(rename_all = "camelCase")]
pub struct Task {
    pub id: Uuid,
    pub project_id: Uuid,
    pub title: String,
    pub description: String,
    pub status: String,
    pub priority: String,
    pub assignee_id: Option<Uuid>,
    pub due_date: Option<NaiveDate>,
    pub completed_at: Option<DateTime<Utc>>,
    pub created_by: Uuid,
    pub version: i32,
    pub created_at: DateTime<Utc>,
    pub updated_at: DateTime<Utc>,
}

#[derive(Debug, Serialize)]
#[serde(rename_all = "camelCase")]
pub struct Comment {
    pub id: Uuid,
    pub task_id: Uuid,
    pub author: UserSummary,
    pub body: String,
    pub created_at: DateTime<Utc>,
}

/// One row of the comments query; `Comment` nests the author the way the contract wants it.
#[derive(Debug, FromRow)]
pub struct CommentRow {
    pub id: Uuid,
    pub task_id: Uuid,
    pub author_id: Uuid,
    pub author_username: String,
    pub author_display_name: String,
    pub body: String,
    pub created_at: DateTime<Utc>,
}

impl From<CommentRow> for Comment {
    fn from(row: CommentRow) -> Self {
        Self {
            id: row.id,
            task_id: row.task_id,
            author: UserSummary {
                id: row.author_id,
                username: row.author_username,
                display_name: row.author_display_name,
            },
            body: row.body,
            created_at: row.created_at,
        }
    }
}

#[derive(Debug, Serialize, FromRow)]
#[serde(rename_all = "camelCase")]
pub struct AuditEntry {
    pub id: i64,
    pub occurred_at: DateTime<Utc>,
    pub actor_id: Option<Uuid>,
    pub action: String,
    pub entity_type: String,
    pub entity_id: Uuid,
    pub details: serde_json::Value,
}

// Requests ------------------------------------------------------------------

/// JSON Merge Patch: a missing member stays `None`, an explicit `null` becomes `Some(None)`.
fn patch_field<'de, D, T>(deserializer: D) -> Result<Option<Option<T>>, D::Error>
where
    D: Deserializer<'de>,
    T: Deserialize<'de>,
{
    Option::<T>::deserialize(deserializer).map(Some)
}

#[derive(Debug, Serialize, Deserialize)]
#[serde(rename_all = "camelCase", deny_unknown_fields)]
pub struct TeamCreate {
    pub name: String,
    #[serde(default)]
    pub description: String,
    pub lead_user_id: Option<Uuid>,
}

impl Validate for TeamCreate {
    fn validate(&self) -> Result<(), AppError> {
        let mut check = Check::default();
        check.text("/name", &self.name, 1, 80);
        check.max_chars("/description", &self.description, 500);
        check.finish()
    }
}

#[derive(Debug, Deserialize)]
#[serde(rename_all = "camelCase", deny_unknown_fields)]
pub struct TeamUpdate {
    pub name: Option<String>,
    pub description: Option<String>,
}

impl Validate for TeamUpdate {
    fn validate(&self) -> Result<(), AppError> {
        let mut check = Check::default();
        if self.name.is_none() && self.description.is_none() {
            check.fail("", "send at least one field");
        }
        if let Some(name) = &self.name {
            check.text("/name", name, 1, 80);
        }
        if let Some(description) = &self.description {
            check.max_chars("/description", description, 500);
        }
        check.finish()
    }
}

#[derive(Debug, Deserialize)]
#[serde(deny_unknown_fields)]
pub struct MemberPut {
    pub role: TeamRole,
}

impl Validate for MemberPut {
    fn validate(&self) -> Result<(), AppError> {
        Ok(())
    }
}

fn check_project_key(check: &mut Check, key: &str) {
    let mut chars = key.chars();
    let valid = (2..=10).contains(&key.len())
        && chars.next().is_some_and(|c| c.is_ascii_uppercase())
        && chars.all(|c| c.is_ascii_uppercase() || c.is_ascii_digit());
    if !valid {
        check.fail("/key", "must match ^[A-Z][A-Z0-9]{1,9}$");
    }
}

#[derive(Debug, Serialize, Deserialize)]
#[serde(rename_all = "camelCase", deny_unknown_fields)]
pub struct ProjectCreate {
    pub key: String,
    pub name: String,
    #[serde(default)]
    pub description: String,
}

impl Validate for ProjectCreate {
    fn validate(&self) -> Result<(), AppError> {
        let mut check = Check::default();
        check_project_key(&mut check, &self.key);
        check.text("/name", &self.name, 1, 120);
        check.max_chars("/description", &self.description, 2000);
        check.finish()
    }
}

#[derive(Debug, Deserialize)]
#[serde(rename_all = "camelCase", deny_unknown_fields)]
pub struct ProjectUpdate {
    pub name: Option<String>,
    pub description: Option<String>,
    pub archived: Option<bool>,
}

impl Validate for ProjectUpdate {
    fn validate(&self) -> Result<(), AppError> {
        let mut check = Check::default();
        if self.name.is_none() && self.description.is_none() && self.archived.is_none() {
            check.fail("", "send at least one field");
        }
        if let Some(name) = &self.name {
            check.text("/name", name, 1, 120);
        }
        if let Some(description) = &self.description {
            check.max_chars("/description", description, 2000);
        }
        check.finish()
    }
}

#[derive(Debug, Serialize, Deserialize)]
#[serde(rename_all = "camelCase", deny_unknown_fields)]
pub struct TaskCreate {
    pub title: String,
    #[serde(default)]
    pub description: String,
    pub priority: Option<TaskPriority>,
    pub assignee_id: Option<Uuid>,
    pub due_date: Option<NaiveDate>,
}

impl Validate for TaskCreate {
    fn validate(&self) -> Result<(), AppError> {
        let mut check = Check::default();
        check.text("/title", &self.title, 1, 200);
        check.max_chars("/description", &self.description, 10000);
        check.finish()
    }
}

#[derive(Debug, Deserialize)]
#[serde(rename_all = "camelCase", deny_unknown_fields)]
pub struct TaskUpdate {
    pub title: Option<String>,
    pub description: Option<String>,
    pub status: Option<TaskStatus>,
    pub priority: Option<TaskPriority>,
    #[serde(default, deserialize_with = "patch_field")]
    pub assignee_id: Option<Option<Uuid>>,
    #[serde(default, deserialize_with = "patch_field")]
    pub due_date: Option<Option<NaiveDate>>,
}

impl Validate for TaskUpdate {
    fn validate(&self) -> Result<(), AppError> {
        let mut check = Check::default();
        let empty = self.title.is_none()
            && self.description.is_none()
            && self.status.is_none()
            && self.priority.is_none()
            && self.assignee_id.is_none()
            && self.due_date.is_none();
        if empty {
            check.fail("", "send at least one field");
        }
        if let Some(title) = &self.title {
            check.text("/title", title, 1, 200);
        }
        if let Some(description) = &self.description {
            check.max_chars("/description", description, 10000);
        }
        check.finish()
    }
}

/// `assigneeId` is required but may be `null` (unassign): no `default`, so a missing member is an error.
#[derive(Debug, Deserialize)]
#[serde(rename_all = "camelCase", deny_unknown_fields)]
pub struct ReassignRequest {
    #[serde(deserialize_with = "Option::deserialize")]
    pub assignee_id: Option<Uuid>,
}

impl Validate for ReassignRequest {
    fn validate(&self) -> Result<(), AppError> {
        Ok(())
    }
}

#[derive(Debug, Serialize, Deserialize)]
#[serde(deny_unknown_fields)]
pub struct CommentCreate {
    pub body: String,
}

impl Validate for CommentCreate {
    fn validate(&self) -> Result<(), AppError> {
        let mut check = Check::default();
        check.text("/body", &self.body, 1, 2000);
        check.finish()
    }
}
