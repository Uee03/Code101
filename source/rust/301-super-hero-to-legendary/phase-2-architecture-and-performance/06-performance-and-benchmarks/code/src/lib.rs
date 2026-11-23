/// Sum of the squares of the even numbers, written as an explicit loop.
pub fn sum_even_squares_loop(values: &[u64]) -> u64 {
    let mut total = 0;
    for &value in values {
        if value % 2 == 0 {
            total += value * value;
        }
    }
    total
}

/// The same result written as an iterator chain.
pub fn sum_even_squares_iter(values: &[u64]) -> u64 {
    values
        .iter()
        .filter(|value| **value % 2 == 0)
        .map(|value| value * value)
        .sum()
}

/// Squares of 0..n, letting the vector grow as items are pushed.
pub fn squares_push(n: u32) -> Vec<u32> {
    let mut out = Vec::new();
    for i in 0..n {
        out.push(i * i);
    }
    out
}

/// Squares of 0..n, reserving the capacity first. `n` must be at most 65_535.
pub fn squares_with_capacity(n: u32) -> Vec<u32> {
    let mut out = Vec::with_capacity(n as usize);
    for i in 0..n {
        out.push(i * i);
    }
    out
}

/// Words followed by a comma each, rebuilding the whole string on every word.
pub fn join_words_format(words: &[&str]) -> String {
    let mut out = String::new();
    for word in words {
        out = format!("{out}{word},");
    }
    out
}

/// The same text built in one buffer that is sized up front.
pub fn join_words_push(words: &[&str]) -> String {
    let needed: usize = words.iter().map(|word| word.len() + 1).sum();
    let mut out = String::with_capacity(needed);
    for word in words {
        out.push_str(word);
        out.push(',');
    }
    out
}

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn loop_and_iterator_agree() {
        let values: Vec<u64> = (0..100).collect();
        assert_eq!(sum_even_squares_loop(&values), sum_even_squares_iter(&values));
        assert_eq!(sum_even_squares_loop(&[1, 2, 3, 4]), 20);
    }

    #[test]
    fn both_vector_builders_give_the_same_squares() {
        assert_eq!(squares_push(5), vec![0, 1, 4, 9, 16]);
        assert_eq!(squares_with_capacity(5), vec![0, 1, 4, 9, 16]);
    }

    #[test]
    fn both_joiners_give_the_same_text() {
        let words = ["a", "b", "c"];
        assert_eq!(join_words_format(&words), "a,b,c,");
        assert_eq!(join_words_push(&words), "a,b,c,");
        assert_eq!(join_words_push(&[]), "");
    }
}
