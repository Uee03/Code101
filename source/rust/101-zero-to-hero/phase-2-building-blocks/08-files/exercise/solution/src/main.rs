use std::fs;

fn main() {
    let text = fs::read_to_string("supplies.csv").expect("Could not read supplies.csv");
    let mut rows = 0;
    for line in text.lines().skip(1) {
        println!("Row: {line}");
        rows = rows + 1;
    }
    let report = format!("Product rows: {rows}\n");
    fs::write("rows.txt", &report).expect("Could not write rows.txt");
    print!("{report}");
}
