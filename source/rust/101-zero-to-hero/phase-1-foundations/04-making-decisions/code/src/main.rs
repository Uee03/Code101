use std::io;

fn main() {
    let mut text = String::new();
    println!("Age:");
    io::stdin().read_line(&mut text).expect("Could not read age");
    let age = text.trim().parse::<i32>().expect("Use a whole number");
    if age < 0 {
        println!("Invalid age");
    } else if age < 18 {
        println!("Ticket: child, 5.00");
    } else {
        println!("Ticket: adult, 10.00");
    }
    let has_ticket = true;
    println!("Adult with ticket: {}", age >= 18 && has_ticket);
    println!("Child or has ticket: {}", age < 18 || has_ticket);
    println!("No ticket: {}", !has_ticket);
    let day = "Sat";
    match day {
        "Sat" | "Sun" => println!("Weekend desk"),
        _ => println!("Weekday desk"),
    }
}
