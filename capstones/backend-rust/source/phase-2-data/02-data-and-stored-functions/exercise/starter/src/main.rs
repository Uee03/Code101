/// `items` is sorted by id. Return the names of up to `limit` items with an id greater than `after`,
/// and the cursor (the id of the last item returned) when more items are left. This is keyset paging.
fn page<'a>(items: &[(u32, &'a str)], after: Option<u32>, limit: usize) -> (Vec<&'a str>, Option<u32>) {
    todo!("filter by `after`, take `limit`, and decide the next cursor")
}

fn main() {
    let items = [(10, "ada"), (20, "bob"), (30, "cy"), (40, "dee"), (50, "eve"), (60, "fay"), (70, "gus")];
    let mut cursor = None;
    loop {
        let (names, next) = page(&items, cursor, 3);
        println!("{names:?} next={next:?}");
        if next.is_none() {
            break;
        }
        cursor = next;
    }
}
