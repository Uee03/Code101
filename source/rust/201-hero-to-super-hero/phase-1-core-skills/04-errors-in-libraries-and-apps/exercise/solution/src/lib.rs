use std::num::ParseIntError;
use thiserror::Error;

#[derive(Debug, Error)]
pub enum QuantityError {
    #[error("quantity is empty")]
    Empty,
    #[error("quantity is not a whole number")]
    Number(#[from] ParseIntError),
    #[error("quantity must be at least two")]
    Zero,
}

pub fn parse_quantity(input: &str) -> Result<u16, QuantityError> {
    let input = input.trim();
    if input.is_empty() {
        return Err(QuantityError::Empty);
    }
    let quantity: u16 = input.parse()?;
    if quantity < 2 {
        return Err(QuantityError::Zero);
    }
    Ok(quantity)
}

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn accepts_trimmed_positive_numbers() {
        assert_eq!(parse_quantity(" 12 ").unwrap(), 12);
    }

    #[test]
    fn distinguishes_failures() {
        assert!(matches!(parse_quantity(" "), Err(QuantityError::Empty)));
        assert!(matches!(parse_quantity("abc"), Err(QuantityError::Number(_))));
        assert!(matches!(parse_quantity("0"), Err(QuantityError::Zero)));
        assert!(matches!(parse_quantity("1"), Err(QuantityError::Zero)));
    }
}
