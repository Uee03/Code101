fn area(width: f64, height: f64) -> f64 {
    width * height
}

fn main() {
    let size = area(3.0, 4.0);
    println!("Area: {size:.2}");
}
