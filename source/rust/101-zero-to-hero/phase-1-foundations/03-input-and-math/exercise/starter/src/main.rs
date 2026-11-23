use std::io;

fn main() {
    let mut total_text = String::new();
    println!("Total bill:");
    io::stdin().read_line(&mut total_text).expect("Could not read total");
    let total = total_text.trim().parse::<f64>().expect("Use a number");
    let mut people_text = String::new();
    println!("People (greater than zero):");
    io::stdin().read_line(&mut people_text).expect("Could not read people");
    let people = people_text.trim().parse::<f64>().expect("Use a number");
    // TODO: calculate each person's equal share.
    let each = total + people;
    println!("Each: {each:.2}");
}
