fn stamp(book: &mut String) {
    book.push_str(" [library]");
}

fn show(book: &str) {
    println!("Book: {book}");
}

fn main() {
    let mut book = String::from("Garden guide");
    let backup = book.clone();
    // TODO: call stamp, then show, without moving book.
    // Choose the correct kind of reference for each call.
    println!("Backup: {backup}");
}
