pub fn longer<'a>(left: &'a str, right: &'a str) -> &'a str {
    if left.len() > right.len() { left } else { right }
}

pub fn first_line(text: &str) -> &str {
    text.lines().next().unwrap_or("")
}

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn chooses_by_byte_length() {
        assert_eq!(longer("rust", "lifetimes"), "lifetimes");
        assert_eq!(longer("lifetimes", "rust"), "lifetimes");
        assert_eq!(longer("", ""), "");
    }

    #[test]
    fn handles_empty_and_multiple_lines() {
        assert_eq!(first_line(""), "");
        assert_eq!(first_line("borrowed\nowned"), "borrowed");
    }
}
