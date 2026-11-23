macro_rules! max_of {
    // A single expression is its own maximum.
    ($x:expr) => {
        $x
    };
    // TODO: compare the first expression with max_of! of the rest and return the larger one.
    // For now this arm returns only the first expression, so the output below is wrong.
    ($x:expr, $($rest:expr),+) => {
        $x
    };
}

fn main() {
    println!("{}", max_of!(7));
    println!("{}", max_of!(3, 9, 4));
    println!("{}", max_of!(1.5, 0.5));
}
