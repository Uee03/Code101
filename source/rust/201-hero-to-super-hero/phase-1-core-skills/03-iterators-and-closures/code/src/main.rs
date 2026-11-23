use iterator_totals::total_above;

fn main() {
    let values = vec![3, 8, 12];
    println!("doubled total: {}", total_above(&values, 8));
    println!("input count: {}", values.len());
}
