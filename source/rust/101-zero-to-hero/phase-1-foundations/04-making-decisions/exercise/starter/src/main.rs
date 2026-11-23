use std::io;

fn main() {
    let mut text = String::new();
    println!("Score (0-100):");
    io::stdin().read_line(&mut text).expect("Could not read score");
    let score = text.trim().parse::<i32>().expect("Use a whole number");
    // TODO: replace this print with invalid, fail, pass and merit branches.
    println!("Score: {score}");
}
