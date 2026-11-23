pub fn shorter<'a>(left: &'a str, right: &'a str) -> &'a str {
    // TODO: return the shorter input; choose left on equal byte lengths.
    let _ = right;
    left
}

pub fn first_line(text: &str) -> &str {
    text.lines().next().unwrap_or("")
}

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn chooses_by_byte_length() {
        assert_eq!(shorter("rust", "lifetimes"), "rust");
        assert_eq!(shorter("lifetimes", "rust"), "rust");
        assert_eq!(shorter("", ""), "");
    }

    #[test]
    fn handles_empty_and_multiple_lines() {
        assert_eq!(first_line(""), "");
        assert_eq!(first_line("borrowed\nowned"), "borrowed");
    }
}
