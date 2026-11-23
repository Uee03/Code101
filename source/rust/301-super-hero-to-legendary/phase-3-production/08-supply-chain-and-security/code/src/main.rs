use std::process::ExitCode;

use subtle::ConstantTimeEq;

/// Compares two secrets without stopping at the first different byte.
/// Different lengths are rejected at once: the length of a token is not treated as secret.
fn tokens_match(expected: &str, given: &str) -> bool {
    expected.as_bytes().ct_eq(given.as_bytes()).into()
}

fn main() -> ExitCode {
    // Demo values only. Real secrets come from the environment or a secret store, never from
    // source code, and are never printed or logged.
    let expected = "demo-token-0001";
    let attempts = ["demo-token-0001", "demo-token-0002", "short"];

    let mut accepted = 0;
    for (index, given) in attempts.iter().enumerate() {
        let ok = tokens_match(expected, given);
        println!("attempt {}: {}", index + 1, if ok { "accepted" } else { "rejected" });
        if ok {
            accepted += 1;
        }
    }

    if accepted == 1 {
        ExitCode::SUCCESS
    } else {
        ExitCode::FAILURE
    }
}

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn equal_tokens_match() {
        assert!(tokens_match("abc", "abc"));
    }

    #[test]
    fn different_tokens_do_not_match() {
        assert!(!tokens_match("abc", "abd"));
        assert!(!tokens_match("abc", "ab"));
        assert!(!tokens_match("abc", ""));
    }
}
