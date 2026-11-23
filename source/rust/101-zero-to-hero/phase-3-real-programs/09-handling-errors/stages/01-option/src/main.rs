fn main() {
    let labels = vec!["Tea"];
    match labels.get(1) {
        Some(label) => println!("Second item: {label}"),
        None => println!("No second item"),
    }
}
