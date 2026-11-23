/// Returns mutable references to two different elements.
/// Returns None when an index is out of range or when both indexes are equal.
pub fn pair_mut<T>(items: &mut [T], i: usize, j: usize) -> Option<(&mut T, &mut T)> {
    if i == j || i >= items.len() || j >= items.len() {
        return None;
    }
    let ptr = items.as_mut_ptr();
    // SAFETY: both indexes are below `items.len()`, so both pointers are in bounds, and
    // `i != j`, so the two references point at different elements and never alias.
    unsafe { Some((&mut *ptr.add(i), &mut *ptr.add(j))) }
}

fn main() {
    let mut scores = [10, 20, 30, 40];
    if let Some((a, b)) = pair_mut(&mut scores, 0, 3) {
        std::mem::swap(a, b);
    }
    println!("{scores:?}");
    println!("same index: {}", pair_mut(&mut scores, 2, 2).is_none());
    println!("out of range: {}", pair_mut(&mut scores, 1, 9).is_none());
}
