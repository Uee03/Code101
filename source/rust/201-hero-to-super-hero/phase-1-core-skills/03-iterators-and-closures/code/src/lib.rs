pub fn total_above(values: &[i32], minimum: i32) -> i32 {
    values.iter()
        .copied()
        .filter(|value| *value >= minimum)
        .map(|value| value * 2)
        .sum()
}

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn includes_the_boundary() {
        assert_eq!(total_above(&[3, 8, 12], 8), 40);
        assert_eq!(total_above(&[8], 8), 16);
    }

    #[test]
    fn empty_input_is_zero() {
        assert_eq!(total_above(&[], 8), 0);
    }
}
