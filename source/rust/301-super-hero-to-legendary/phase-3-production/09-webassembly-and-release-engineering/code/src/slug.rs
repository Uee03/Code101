/// Longest slug produced, in characters. Longer titles are cut.
pub const MAX_SLUG_LEN: usize = 60;

/// Lowercase ASCII letters and digits, with every run of anything else turned into one dash.
/// Non-ASCII characters count as separators: a deliberate, documented policy.
pub fn slugify_text(input: &str) -> String {
    let mut out = String::with_capacity(input.len().min(MAX_SLUG_LEN));
    let mut pending_dash = false;
    for ch in input.chars() {
        if ch.is_ascii_alphanumeric() {
            let separator = pending_dash && !out.is_empty();
            let needed = if separator { 2 } else { 1 };
            if out.len() + needed > MAX_SLUG_LEN {
                break;
            }
            if separator {
                out.push('-');
            }
            pending_dash = false;
            out.push(ch.to_ascii_lowercase());
        } else {
            pending_dash = true;
        }
    }
    out
}

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn punctuation_and_spaces_become_single_dashes() {
        assert_eq!(slugify_text("Hello, Rust 301!"), "hello-rust-301");
    }

    #[test]
    fn only_separators_give_an_empty_slug() {
        assert_eq!(slugify_text("  --  "), "");
        assert_eq!(slugify_text(""), "");
    }

    #[test]
    fn non_ascii_letters_act_as_separators() {
        assert_eq!(slugify_text("Crème brûlée"), "cr-me-br-l-e");
    }

    #[test]
    fn long_input_is_cut_at_the_limit() {
        assert_eq!(slugify_text(&"a".repeat(100)).len(), MAX_SLUG_LEN);
    }

    #[test]
    fn a_cut_never_leaves_a_trailing_dash() {
        let slug = slugify_text(&format!("{} b", "a".repeat(MAX_SLUG_LEN - 1)));
        assert_eq!(slug.len(), MAX_SLUG_LEN - 1);
        assert!(!slug.ends_with('-'));
    }
}
