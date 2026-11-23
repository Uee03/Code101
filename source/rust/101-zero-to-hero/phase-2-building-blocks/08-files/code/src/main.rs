use std::fs;

fn main() {
    let text = fs::read_to_string("supplies.csv").expect("Could not read supplies.csv");
    print!("{text}");
    let mut total = 0;
    for line in text.lines().skip(1) {
        let fields: Vec<&str> = line.split(',').collect();
        let quantity = fields[1].parse::<i32>().expect("Use a whole quantity");
        total = total + quantity;
    }
    let report = format!("Total items: {total}\n");
    fs::write("summary.txt", &report).expect("Could not write summary.txt");
    print!("{report}");
}
