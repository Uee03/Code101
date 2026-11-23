use serde::{Deserialize, Serialize};
use uuid::Uuid;

use crate::{
    error::AppError,
    validation::{Check, Validate},
};

#[derive(Debug, Serialize)]
pub struct Health {
    pub status: &'static str,
    pub version: &'static str,
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

#[derive(Debug, Serialize)]
#[serde(rename_all = "camelCase")]
pub struct MeTeam {
    pub team_id: Uuid,
    pub name: String,
    pub role: String,
}

#[derive(Debug, Deserialize)]
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
