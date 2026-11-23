use iterator_totals::total_above;

fn main() {
    let values = vec![3, 8, 12];
    println!("tripled total: {}", total_above(&values, 8));
    println!("input count: {}", values.len());
}
