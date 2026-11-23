use std::io;

fn main() {
    let mut text = String::new();
    println!("Score (0-100):");
    io::stdin().read_line(&mut text).expect("Could not read score");
    let score = text.trim().parse::<i32>().expect("Use a whole number");
    if score < 0 || score > 100 {
        println!("Invalid score");
    } else if score < 50 {
        println!("Fail");
    } else if score < 75 {
        println!("Pass");
    } else {
        println!("Merit");
    }
}
