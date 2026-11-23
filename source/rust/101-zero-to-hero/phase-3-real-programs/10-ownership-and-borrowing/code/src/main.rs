fn read_book(book: &str) {
    println!("Reading: {book}");
}

fn add_note(book: &mut String) {
    book.push_str(" [read]");
}

fn main() {
    let book = String::from("Rust stories");
    let mut reader = book;
    let backup = reader.clone();
    read_book(&reader);
    add_note(&mut reader);
    println!("Reader: {reader}");
    println!("Backup: {backup}");
}
