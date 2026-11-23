use std::collections::HashMap;

fn main() {
    let prices = vec![3, 5, 2];
    let mut total = 0;
    for price in &prices {
        total = total + price;
    }
    println!("Number of prices: {}", prices.len());
    let mut counts = HashMap::new();
    counts.insert("Tea", 2);
    counts.insert("Rice", 3);
    println!("Total: {total}");
    println!("Tea: {}", counts["Tea"]);
    println!("Rice: {}", counts["Rice"]);
}
