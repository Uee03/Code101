fn stamp(book: &mut String) {
    book.push_str(" [library]");
}

fn show(book: &str) {
    println!("Book: {book}");
}

fn main() {
    let mut book = String::from("Garden guide");
    let backup = book.clone();
    stamp(&mut book);
    show(&book);
    println!("Backup: {backup}");
}
