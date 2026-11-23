use tested_titles::normalize_title;

fn main() {
    let title = normalize_title(" Rust notes ").expect("valid built-in title");
    println!("title: {title}");
    println!("blank rejected: {}", normalize_title(" ").is_err());
}
