enum Category {
    Food,
    Travel,
    Books,
}

struct Expense {
    name: String,
    cents: i32,
    category: Category,
}

impl Expense {
    fn new(name: &str, cents: i32, category: Category) -> Self {
        Self { name: name.to_string(), cents, category }
    }

    fn show(&self) {
        let label = match &self.category {
            Category::Food => "food",
            Category::Travel => "travel",
        };
        println!("{}: {} cents ({label})", self.name, self.cents);
    }
}

fn main() {
    let tea = Expense::new("Tea", 250, Category::Food);
    let bus = Expense::new("Bus", 400, Category::Travel);
    tea.show();
    bus.show();
    // TODO: support a Guide book purchase costing 900 cents.
}
