use std::alloc::{GlobalAlloc, Layout, System};
use std::sync::atomic::{AtomicUsize, Ordering};

use perf_lab::{
    join_words_format, join_words_push, squares_push, squares_with_capacity,
    sum_even_squares_iter, sum_even_squares_loop,
};

/// Counts every call into the allocator, then forwards the call to the system allocator.
struct CountingAllocator;

static ALLOCATOR_CALLS: AtomicUsize = AtomicUsize::new(0);

// SAFETY: every method forwards its arguments unchanged to `System`, which upholds the
// `GlobalAlloc` contract. The counter is an atomic, so it cannot cause a data race.
unsafe impl GlobalAlloc for CountingAllocator {
    unsafe fn alloc(&self, layout: Layout) -> *mut u8 {
        ALLOCATOR_CALLS.fetch_add(1, Ordering::Relaxed);
        // SAFETY: the caller of `alloc` guarantees that `layout` is valid for `System.alloc`.
        unsafe { System.alloc(layout) }
    }

    unsafe fn dealloc(&self, ptr: *mut u8, layout: Layout) {
        // SAFETY: the caller guarantees that `ptr` and `layout` match an earlier allocation.
        unsafe { System.dealloc(ptr, layout) }
    }

    unsafe fn realloc(&self, ptr: *mut u8, layout: Layout, new_size: usize) -> *mut u8 {
        ALLOCATOR_CALLS.fetch_add(1, Ordering::Relaxed);
        // SAFETY: the caller guarantees `ptr`, `layout` and `new_size` satisfy `realloc`'s rules.
        unsafe { System.realloc(ptr, layout, new_size) }
    }
}

#[global_allocator]
static GLOBAL: CountingAllocator = CountingAllocator;

/// Runs `work` and returns its result with the number of allocator calls it made.
fn calls_during<T>(work: impl FnOnce() -> T) -> (T, usize) {
    let before = ALLOCATOR_CALLS.load(Ordering::Relaxed);
    let result = work();
    let after = ALLOCATOR_CALLS.load(Ordering::Relaxed);
    (result, after - before)
}

fn main() {
    let values: Vec<u64> = (0..1000).collect();
    println!(
        "loop and iter agree: {}",
        sum_even_squares_loop(&values) == sum_even_squares_iter(&values)
    );

    let (_, push_calls) = calls_during(|| squares_push(1000));
    let (_, reserved_calls) = calls_during(|| squares_with_capacity(1000));
    println!("push made more than one allocator call: {}", push_calls > 1);
    println!(
        "with_capacity made exactly one allocator call: {}",
        reserved_calls == 1
    );

    let words = ["alpha", "beta", "gamma"];
    println!(
        "format! and push_str agree: {}",
        join_words_format(&words) == join_words_push(&words)
    );
}
