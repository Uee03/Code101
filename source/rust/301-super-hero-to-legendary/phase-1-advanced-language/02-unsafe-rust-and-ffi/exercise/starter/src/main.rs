/// Returns mutable references to two different elements.
/// Returns None when an index is out of range or when both indexes are equal.
pub fn pair_mut<T>(items: &mut [T], i: usize, j: usize) -> Option<(&mut T, &mut T)> {
    // TODO 1: return None unless i and j are different and both are below items.len().
    // TODO 2: then take items.as_mut_ptr(), build both references in one unsafe block
    // and write a SAFETY comment that names the two facts which make it sound.
    todo!("implement pair_mut for {} items, indexes {i} and {j}", items.len())
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
