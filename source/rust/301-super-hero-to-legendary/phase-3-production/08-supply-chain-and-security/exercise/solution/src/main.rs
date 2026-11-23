/// Masks a secret for logs: tokens of 9 or more characters keep only their last 4 characters,
/// shorter tokens are masked completely. The result always has the same number of characters.
pub fn redact(token: &str) -> String {
    let count = token.chars().count();
    if count < 9 {
        return "*".repeat(count);
    }
    let tail: String = token.chars().skip(count - 4).collect();
    format!("{}{}", "*".repeat(count - 4), tail)
}

fn main() {
    println!("{}", redact("demo-token-0001"));
    println!("{}", redact("short"));
}

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn long_tokens_keep_the_last_four() {
        assert_eq!(redact("abcdefghi"), "*****fghi");
    }

    #[test]
    fn short_tokens_are_fully_masked() {
        assert_eq!(redact("12345678"), "********");
        assert_eq!(redact(""), "");
    }

    #[test]
    fn counts_characters_not_bytes() {
        assert_eq!(redact("ééééééééé"), "*****éééé");
    }
}
