use std::io;

fn main() {
    let mut bill_text = String::new();
    println!("Bill amount (for example 80):");
    io::stdin().read_line(&mut bill_text).expect("Could not read bill");
    let bill = bill_text.trim().parse::<f64>().expect("Use a number");
    let mut tip_text = String::new();
    println!("Tip percent (for example 15):");
    io::stdin().read_line(&mut tip_text).expect("Could not read tip");
    let percent = tip_text.trim().parse::<f64>().expect("Use a number");
    let tip = bill * percent / 100.0;
    let total = bill + tip;
    println!("Tip: {tip:.2}");
    println!("Total: {total:.2}");
    println!("Change from 100: {:.2}", 100.0 - total);
    println!("7 % 3 = {}", 7 % 3);
}
