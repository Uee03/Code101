use std::sync::atomic::{AtomicUsize, Ordering};
use std::sync::mpsc;
use std::sync::{Arc, Mutex};
use std::thread;

/// Compiles only when `T` is `Send`: its values may move to another thread.
///
/// ```compile_fail
/// use std::rc::Rc;
/// fearless::assert_send::<Rc<u32>>();
/// ```
pub fn assert_send<T: Send>() {}

/// Compiles only when `T` is `Sync`: `&T` may be shared between threads.
pub fn assert_sync<T: Sync>() {}

/// Sum of squares, split into chunks that scoped threads work on in parallel.
pub fn parallel_sum_of_squares(values: &[u64], workers: usize) -> u64 {
    let chunk = values.len().div_ceil(workers.max(1)).max(1);
    thread::scope(|scope| {
        let handles: Vec<_> = values
            .chunks(chunk)
            .map(|part| scope.spawn(move || part.iter().map(|v| v * v).sum::<u64>()))
            .collect();
        handles
            .into_iter()
            .map(|handle| handle.join().expect("worker panicked"))
            .sum()
    })
}

/// One thread per value; results come back over a channel in arrival order, so we sort.
pub fn squares_via_channel(values: Vec<u64>) -> Vec<u64> {
    let (tx, rx) = mpsc::channel();
    let mut handles = Vec::new();
    for value in values {
        let tx = tx.clone();
        handles.push(thread::spawn(move || {
            tx.send(value * value).expect("receiver is alive");
        }));
    }
    // The receiver iterator ends only when every sender is gone, including this one.
    drop(tx);
    let mut squares: Vec<u64> = rx.iter().collect();
    for handle in handles {
        handle.join().expect("worker panicked");
    }
    squares.sort_unstable();
    squares
}

/// A shared counter behind `Arc<Mutex<_>>`: every increment takes the lock.
pub fn count_with_mutex(threads: usize, per_thread: usize) -> usize {
    let counter = Arc::new(Mutex::new(0usize));
    let handles: Vec<_> = (0..threads)
        .map(|_| {
            let counter = Arc::clone(&counter);
            thread::spawn(move || {
                for _ in 0..per_thread {
                    *counter.lock().expect("lock poisoned") += 1;
                }
            })
        })
        .collect();
    for handle in handles {
        handle.join().expect("worker panicked");
    }
    let guard = counter.lock().expect("lock poisoned");
    *guard
}

/// The same counter as one atomic: no lock, borrowed by scoped threads instead of an `Arc`.
pub fn count_with_atomic(threads: usize, per_thread: usize) -> usize {
    let counter = AtomicUsize::new(0);
    thread::scope(|scope| {
        for _ in 0..threads {
            scope.spawn(|| {
                for _ in 0..per_thread {
                    // Relaxed is enough: only the final total matters, and the scope joins
                    // every thread before we read it.
                    counter.fetch_add(1, Ordering::Relaxed);
                }
            });
        }
    });
    counter.load(Ordering::Relaxed)
}

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn auto_traits_hold_for_common_types() {
        assert_send::<Vec<String>>();
        assert_send::<Arc<Mutex<u32>>>();
        assert_sync::<Arc<Mutex<u32>>>();
    }

    #[test]
    fn parallel_sum_matches_the_sequential_sum() {
        let values: Vec<u64> = (1..=100).collect();
        let expected: u64 = values.iter().map(|v| v * v).sum();
        for workers in [1, 3, 4, 200] {
            assert_eq!(parallel_sum_of_squares(&values, workers), expected);
        }
    }

    #[test]
    fn parallel_sum_of_nothing_is_zero() {
        assert_eq!(parallel_sum_of_squares(&[], 4), 0);
    }

    #[test]
    fn channel_collects_every_square() {
        assert_eq!(squares_via_channel(vec![3, 1, 2]), vec![1, 4, 9]);
    }

    #[test]
    fn both_counters_reach_the_same_total() {
        assert_eq!(count_with_mutex(4, 1000), 4000);
        assert_eq!(count_with_atomic(4, 1000), 4000);
    }

    #[test]
    fn a_panic_while_locked_poisons_the_mutex() {
        let shared = Arc::new(Mutex::new(0));
        let clone = Arc::clone(&shared);
        let result = thread::spawn(move || {
            let _guard = clone.lock().expect("lock");
            panic!("worker failed while holding the lock");
        })
        .join();
        assert!(result.is_err());
        assert!(shared.lock().is_err());
    }
}
