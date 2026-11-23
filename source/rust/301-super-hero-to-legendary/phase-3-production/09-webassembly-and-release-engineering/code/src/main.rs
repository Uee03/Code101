use slug_wasm::slugify_text;

fn main() {
    let title = std::env::args().skip(1).collect::<Vec<_>>().join(" ");
    let title = if title.is_empty() {
        "Hello, Rust 301!".to_string()
    } else {
        title
    };
    println!("{}", slugify_text(&title));
}
