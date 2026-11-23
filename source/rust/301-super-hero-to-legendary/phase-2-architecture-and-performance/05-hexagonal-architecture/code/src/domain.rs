use std::fmt;

pub const MAX_TITLE_CHARS: usize = 40;

#[derive(Debug, Clone, PartialEq, Eq)]
pub struct Task {
    pub id: u32,
    pub title: String,
    pub created_at: u64,
    pub done: bool,
}

#[derive(Debug, Clone, PartialEq, Eq)]
pub enum TaskError {
    EmptyTitle,
    TitleTooLong { max: usize },
    NotFound(u32),
    Storage(String),
}

impl fmt::Display for TaskError {
    fn fmt(&self, f: &mut fmt::Formatter<'_>) -> fmt::Result {
        match self {
            TaskError::EmptyTitle => write!(f, "title is empty"),
            TaskError::TitleTooLong { max } => {
                write!(f, "title is longer than {max} characters")
            }
            TaskError::NotFound(id) => write!(f, "task {id} not found"),
            TaskError::Storage(reason) => write!(f, "storage failed: {reason}"),
        }
    }
}

impl std::error::Error for TaskError {}

/// Business rule: a title is trimmed, not empty and at most 40 characters long.
pub fn validate_title(raw: &str) -> Result<String, TaskError> {
    let title = raw.trim();
    if title.is_empty() {
        return Err(TaskError::EmptyTitle);
    }
    if title.chars().count() > MAX_TITLE_CHARS {
        return Err(TaskError::TitleTooLong {
            max: MAX_TITLE_CHARS,
        });
    }
    Ok(title.to_string())
}

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn titles_are_trimmed() {
        assert_eq!(validate_title("  hello  "), Ok("hello".to_string()));
    }

    #[test]
    fn blank_titles_are_rejected() {
        assert_eq!(validate_title(" \t "), Err(TaskError::EmptyTitle));
    }

    #[test]
    fn length_counts_characters_not_bytes() {
        let forty = "é".repeat(40);
        assert!(validate_title(&forty).is_ok());
        let forty_one = "é".repeat(41);
        assert_eq!(
            validate_title(&forty_one),
            Err(TaskError::TitleTooLong { max: 40 })
        );
    }
}
