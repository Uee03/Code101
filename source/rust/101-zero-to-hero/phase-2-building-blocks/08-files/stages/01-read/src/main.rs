use std::fs;

fn main() {
    let text = fs::read_to_string("supplies.csv").expect("Could not read supplies.csv");
    print!("{text}");
}
