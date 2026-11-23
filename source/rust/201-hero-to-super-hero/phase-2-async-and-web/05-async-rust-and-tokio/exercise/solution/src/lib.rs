use std::time::Duration;

pub async fn label(name: &str) -> String {
    tokio::time::sleep(Duration::from_millis(5)).await;
    format!("{} ready", name.to_uppercase())
}

pub async fn pair() -> (String, String) {
    tokio::join!(label("alpha"), label("beta"))
}

pub async fn deadline_expires() -> bool {
    tokio::time::timeout(
        Duration::from_millis(5),
        std::future::pending::<()>(),
    ).await.is_err()
}

#[cfg(test)]
mod tests {
    use super::*;

    #[tokio::test]
    async fn pair_preserves_result_positions() {
        assert_eq!(pair().await, ("ALPHA ready".into(), "BETA ready".into()));
    }

    #[tokio::test]
    async fn pending_work_has_a_deadline() {
        assert!(deadline_expires().await);
    }
}
