fn main() {
    let boxes: i32 = 4;
    let price: f64 = 2.5;
    let in_stock: bool = true;
    let aisle: char = 'B';
    let label: &str = "Tea";
    let description: String = String::from("Green tea");
    let mut sold: i32 = 1;
    sold = sold + 1;
    let servings = 2;
    let servings = servings + 1;
    println!("Item: {label}; description: {description}");
    println!("Boxes: {boxes}; price: {price:.2}");
    println!("In stock: {in_stock}; aisle: {aisle}");
    println!("Sold: {sold}; servings: {servings}");
}
