/// Masks a secret for logs: tokens of 9 or more characters keep only their last 4 characters,
/// shorter tokens are masked completely. The result always has the same number of characters.
pub fn redact(token: &str) -> String {
    // TODO: count the characters (not the bytes), return all stars for fewer than 9,
    // otherwise stars for all but the last 4 characters, then those last 4 characters.
    token.to_string()
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
