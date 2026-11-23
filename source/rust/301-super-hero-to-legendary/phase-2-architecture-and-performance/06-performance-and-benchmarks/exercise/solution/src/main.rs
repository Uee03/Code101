/// Joins fields with commas, so ["a", "b"] becomes "a,b".
/// One String with the exact capacity: a single allocation.
pub fn csv_line(fields: &[&str]) -> String {
    let separators = fields.len().saturating_sub(1);
    let needed: usize = fields.iter().map(|field| field.len()).sum::<usize>() + separators;
    let mut line = String::with_capacity(needed);
    for (index, field) in fields.iter().enumerate() {
        if index > 0 {
            line.push(',');
        }
        line.push_str(field);
    }
    line
}

fn main() {
    println!("{}", csv_line(&["id", "name", "role"]));
    println!("[{}]", csv_line(&[]));
    println!("{}", csv_line(&["only"]));
}

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn joins_with_commas() {
        assert_eq!(csv_line(&["a", "b", "c"]), "a,b,c");
    }

    #[test]
    fn handles_empty_and_single_lists() {
        assert_eq!(csv_line(&[]), "");
        assert_eq!(csv_line(&["x"]), "x");
    }
}
