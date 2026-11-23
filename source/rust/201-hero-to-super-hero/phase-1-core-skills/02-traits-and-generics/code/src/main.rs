use summary_traits::{render, Note, Reminder};

fn main() {
    let note = Note { title: "Rust".into() };
    let reminder = Reminder { minutes: 5 };
    println!("{}", render(&note));
    println!("{}", render(&reminder));
}
