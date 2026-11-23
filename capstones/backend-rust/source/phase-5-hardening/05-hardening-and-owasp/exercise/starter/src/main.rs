use std::collections::HashMap;

/// A rate limiter whose clock is a parameter (`now`, in seconds), so it can be tried without waiting.
struct Limiter {
    limit: u32,
    window: u64,
    seen: HashMap<String, (u64, u32)>, // key -> (second the window started, calls used)
}

impl Limiter {
    fn new(limit: u32, window: u64) -> Self {
        Self { limit, window, seen: HashMap::new() }
    }

    /// Returns (allowed, remaining). A call that arrives after the window ended starts a new window.
    /// A refused call does not count.
    fn check(&mut self, key: &str, now: u64) -> (bool, u32) {
        todo!("start or continue the window of {key} at second {now}")
    }
}

fn main() {
    let mut limiter = Limiter::new(3, 60);
    for second in [0, 1, 2, 3, 59, 60, 61] {
        let (allowed, remaining) = limiter.check("ip:10.0.0.1", second);
        println!("t={second:>2} allowed={allowed} remaining={remaining}");
    }
    println!("other key: {:?}", limiter.check("ip:10.0.0.2", 3));
}
