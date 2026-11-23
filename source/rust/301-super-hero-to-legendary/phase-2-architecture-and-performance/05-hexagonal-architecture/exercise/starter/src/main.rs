use std::cell::Cell;

pub trait Clock {
    fn now(&self) -> u64;
}

/// A fake clock for tests: every call to now() returns the next step.
pub struct StepClock {
    next: Cell<u64>,
    step: u64,
}

impl StepClock {
    pub fn new(start: u64, step: u64) -> Self {
        StepClock {
            next: Cell::new(start),
            step,
        }
    }
}

impl Clock for StepClock {
    fn now(&self) -> u64 {
        // TODO: return the current value of `next`, then advance `next` by `step`.
        0
    }
}

pub fn stamp_all<C: Clock>(clock: &C, labels: &[&str]) -> Vec<String> {
    labels
        .iter()
        .map(|label| format!("{label}@{}", clock.now()))
        .collect()
}

fn main() {
    let clock = StepClock::new(100, 10);
    println!("{:?}", stamp_all(&clock, &["a", "b", "c"]));
    println!("next: {}", clock.now());
}
