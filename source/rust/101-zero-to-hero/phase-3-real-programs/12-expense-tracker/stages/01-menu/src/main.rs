use std::io;

struct Expense {
    description: String,
    cents: i64,
}

enum Command {
    Add,
    List,
    Total,
    Quit,
    Unknown,
}

fn command(text: &str) -> Command {
    match text {
        "1" => Command::Add,
        "2" => Command::List,
        "3" => Command::Total,
        "4" => Command::Quit,
        _ => Command::Unknown,
    }
}

fn total(expenses: &[Expense]) -> i64 {
    let mut sum = 0;
    for expense in expenses {
        sum = sum + expense.cents;
    }
    sum
}

fn read_text(prompt: &str) -> io::Result<String> {
    println!("{prompt}");
    let mut text = String::new();
    if io::stdin().read_line(&mut text)? == 0 {
        return Err(io::Error::new(io::ErrorKind::UnexpectedEof, "Input ended"));
    }
    Ok(text.trim().to_string())
}

fn main() -> io::Result<()> {
    let mut expenses = Vec::new();
    loop {
        let choice = read_text("1 Add | 2 List | 3 Total | 4 Quit")?;
        match command(&choice) {
            Command::Add => {
                let description = read_text("Description (no commas):")?;
                if description.is_empty() || description.contains(',') {
                    println!("Use a nonempty description without commas.");
                    continue;
                }
                let amount = read_text("Cents (0-1000000000):")?;
                let cents = match amount.parse::<i64>() {
                    Ok(value) => value,
                    Err(_) => {
                        println!("Use whole cents.");
                        continue;
                    }
                };
                if cents < 0 || cents > 1_000_000_000 {
                    println!("Cents must be from 0 to 1000000000.");
                    continue;
                }
                expenses.push(Expense { description, cents });
                println!("Added (not saved yet).");
            }
            Command::List => {
                for expense in &expenses {
                    println!("{}: {} cents", expense.description, expense.cents);
                }
            }
            Command::Total => println!("Total: {} cents", total(&expenses)),
            Command::Quit => break,
            Command::Unknown => println!("Choose 1, 2, 3 or 4."),
        }
    }
    Ok(())
}
