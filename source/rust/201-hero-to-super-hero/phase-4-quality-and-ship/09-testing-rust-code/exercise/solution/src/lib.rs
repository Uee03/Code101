#[derive(Debug, PartialEq, Eq)]
pub enum TitleError {
    Empty,
    TooLong,
}

fn too_long(title: &str) -> bool {
    title.chars().count() > 80
}

/// Trim a title and reject empty or oversized input.
///
/// ```
/// use tested_titles::{normalize_title, TitleError};
/// assert_eq!(normalize_title(" Rust "), Ok("Rust".to_string()));
/// assert_eq!(normalize_title(" "), Err(TitleError::Empty));
/// ```
pub fn normalize_title(input: &str) -> Result<String, TitleError> {
    let title = input.trim();
    if title.is_empty() {
        return Err(TitleError::Empty);
    }
    if too_long(title) {
        return Err(TitleError::TooLong);
    }
    Ok(title.to_owned())
}

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn private_length_policy_has_a_boundary() {
        assert!(!too_long(&"x".repeat(80)));
        assert!(too_long(&"x".repeat(81)));
    }

    #[test]
    fn rejects_empty_after_trimming() {
        assert_eq!(normalize_title("\t "), Err(TitleError::Empty));
    }
}
