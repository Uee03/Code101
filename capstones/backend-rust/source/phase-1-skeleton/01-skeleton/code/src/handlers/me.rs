use axum::Json;
use uuid::uuid;

use crate::models::Me;

/// A stub: always alice. Phase 3 replaces it with the caller found in the access token.
pub async fn get_me() -> Json<Me> {
    Json(Me {
        id: uuid!("a11ce000-0000-4000-8000-000000000001"),
        username: "alice".to_owned(),
        email: "alice@tasksteams.test".to_owned(),
        display_name: "Alice Admin".to_owned(),
        roles: vec!["admin".to_owned()],
        scopes: ["tasks:read", "tasks:write", "tasks:admin"].map(str::to_owned).to_vec(),
        teams: Vec::new(),
    })
}
