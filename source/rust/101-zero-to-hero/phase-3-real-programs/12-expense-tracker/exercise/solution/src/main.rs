use std::fs;
use std::io;

struct Expense {
    description: String,
    cents: i64,
}

impl Expense {
    fn csv_row(&self) -> String {
        format!("{},{}\n", self.description, self.cents)
    }
}

enum Command {
    Add,
    List,
    Total,
    Count,
    Quit,
    Unknown,
}

fn command(text: &str) -> Command {
    match text {
        "1" => Command::Add,
        "2" => Command::List,
        "3" => Command::Total,
        "4" => Command::Quit,
        "5" => Command::Count,
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

fn load() -> io::Result<Vec<Expense>> {
    let text = match fs::read_to_string("expenses.csv") {
        Ok(text) => text,
        Err(error) => {
            if error.kind() == io::ErrorKind::NotFound {
                return Ok(Vec::new());
            }
            return Err(error);
        }
    };
    let mut expenses = Vec::new();
    let mut lines = text.lines();
    if lines.next() != Some("description,cents") {
        return Err(io::Error::new(io::ErrorKind::InvalidData, "Wrong CSV header"));
    }
    for line in lines {
        let fields: Vec<&str> = line.split(',').collect();
        if fields.len() != 2 || fields[0].trim().is_empty() {
            return Err(io::Error::new(io::ErrorKind::InvalidData, "Bad CSV row"));
        }
        let cents = match fields[1].parse::<i64>() {
            Ok(value) => value,
            Err(_) => return Err(io::Error::new(io::ErrorKind::InvalidData, "Bad cents")),
        };
        if cents < 0 || cents > 1_000_000_000 {
            return Err(io::Error::new(io::ErrorKind::InvalidData, "Cents out of range"));
        }
        expenses.push(Expense { description: fields[0].to_string(), cents });
    }
    Ok(expenses)
}

fn save(expenses: &[Expense]) -> io::Result<()> {
    let mut text = String::from("description,cents\n");
    for expense in expenses {
        text.push_str(&expense.csv_row());
    }
    fs::write("expenses.csv", text)
}

fn read_text(prompt: &str) -> io::Result<String> {
    println!("{prompt}");
    let mut text = String::new();
    if io::stdin().read_line(&mut text)? == 0 {
        return Err(io::Error::new(io::ErrorKind::UnexpectedEof, "Input ended"));
    }
    Ok(text.trim().to_string())
}

fn self_check() {
    let sample = vec![
        Expense { description: String::from("Tea"), cents: 250 },
        Expense { description: String::from("Bus"), cents: 400 },
    ];
    assert!(total(&sample) == 650);
    assert!(sample[0].csv_row() == "Tea,250\n");
    println!("Self-check: OK");
}

fn main() -> io::Result<()> {
    self_check();
    let mut expenses = load()?;
    loop {
        let choice = read_text("1 Add | 2 List | 3 Total | 4 Quit | 5 Count")?;
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
                save(&expenses)?;
                println!("Saved.");
            }
            Command::List => {
                for expense in &expenses {
                    println!("{}: {} cents", expense.description, expense.cents);
                }
            }
            Command::Total => println!("Total: {} cents", total(&expenses)),
            Command::Count => println!("Entries: {}", expenses.len()),
            Command::Quit => break,
            Command::Unknown => println!("Choose 1, 2, 3, 4 or 5."),
        }
    }
    Ok(())
}
