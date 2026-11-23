use lifetime_views::{first_line, shorter};

fn main() {
    let left = String::from("rust");
    let right = String::from("lifetimes");
    let picked = shorter(&left, &right);
    println!("picked: {picked}");
    let note = String::from("borrowed\nowned");
    println!("line: {}", first_line(&note));
}
