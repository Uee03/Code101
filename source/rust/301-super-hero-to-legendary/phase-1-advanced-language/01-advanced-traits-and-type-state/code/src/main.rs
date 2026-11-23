use invoice_states::Invoice;

fn main() {
    let draft = Invoice::new(1)
        .add_line("rust training", 120_000)
        .add_line("code review", 4_550);
    println!("{draft}");

    let submitted = match draft.submit() {
        Ok(submitted) => submitted,
        Err(draft) => {
            println!("rejected: {draft}");
            return;
        }
    };
    println!("{submitted}");

    let approved = submitted.approve("ana");
    println!("{approved} by {}", approved.approver());

    match Invoice::new(2).submit() {
        Ok(submitted) => println!("unexpected: {submitted}"),
        Err(draft) => println!("rejected: {draft}"),
    }
}
