use std::thread;

/// Largest value of `values`, found by scoped threads that each take one chunk.
/// Returns None for an empty slice.
pub fn parallel_max(values: &[i32], workers: usize) -> Option<i32> {
    let chunk = values.len().div_ceil(workers.max(1)).max(1);
    thread::scope(|scope| {
        let handles: Vec<_> = values
            .chunks(chunk)
            .map(|part| scope.spawn(move || part.iter().copied().max()))
            .collect();
        // TODO: join every handle, then combine the per-chunk maximums into one Option<i32>.
        let _ = handles;
        None
    })
}

fn main() {
    let values = [4, 17, -3, 9, 25, 8, 25, 1];
    println!("max: {:?}", parallel_max(&values, 3));
    println!("empty: {:?}", parallel_max(&[], 3));
}
