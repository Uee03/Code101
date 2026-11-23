pub fn shorter<'a>(left: &'a str, right: &'a str) -> &'a str {
    if left.len() <= right.len() { left } else { right }
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
