struct Expense { cents: i64 }

fn main() {
    let tea = Expense { cents: 2.50 };
    println!("{}", tea.cents);
}
