use std::collections::HashMap;

fn main() {
    let prices = vec![3, 5, 2];
    let mut total = 0;
    // TODO: total all prices while keeping prices available below.
    println!("Number of prices: {}", prices.len());
    let mut counts = HashMap::new();
    counts.insert("Tea", 2);
    // TODO: record that 3 bags of Rice are in stock, then display them.
    println!("Total: {total}");
    println!("Tea: {}", counts["Tea"]);
}
