use std::collections::HashMap;

fn main() {
    let mut items = vec!["Tea", "Rice"];
    items.push("Apples");
    println!("First: {}", items[0]);
    println!("Items: {}", items.len());
    for item in &items {
        println!("Buy: {item}");
    }
    let mut quantities = HashMap::new();
    quantities.insert("Tea", 2);
    quantities.insert("Rice", 3);
    quantities.insert("Tea", 4);
    println!("Tea quantity: {}", quantities["Tea"]);
    println!("Rice quantity: {}", quantities["Rice"]);
}
