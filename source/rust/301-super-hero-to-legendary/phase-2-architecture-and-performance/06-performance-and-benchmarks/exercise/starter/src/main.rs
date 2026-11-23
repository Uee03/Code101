/// Joins fields with commas, so ["a", "b"] becomes "a,b".
/// This starter allocates a String per field plus a Vec for the list.
pub fn csv_line(fields: &[&str]) -> String {
    // TODO: build the result in ONE String created with the exact capacity needed,
    // using push_str and push. Do not allocate anything else.
    fields
        .iter()
        .map(|field| field.to_string())
        .collect::<Vec<String>>()
        .join(",")
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
