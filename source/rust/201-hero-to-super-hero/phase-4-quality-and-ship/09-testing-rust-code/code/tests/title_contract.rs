use tested_titles::{normalize_title, TitleError};

#[test]
fn external_caller_gets_trimmed_owned_text() {
    assert_eq!(normalize_title(" Rust "), Ok("Rust".to_string()));
}

#[test]
fn external_caller_can_match_an_error() {
    assert_eq!(normalize_title(""), Err(TitleError::Empty));
}
