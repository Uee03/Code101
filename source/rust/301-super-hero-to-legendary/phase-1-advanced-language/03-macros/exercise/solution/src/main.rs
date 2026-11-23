macro_rules! max_of {
    // A single expression is its own maximum.
    ($x:expr) => {
        $x
    };
    // Compare the first expression with the maximum of the rest.
    ($x:expr, $($rest:expr),+) => {{
        let first = $x;
        let others = max_of!($($rest),+);
        if first > others { first } else { others }
    }};
}

fn main() {
    println!("{}", max_of!(7));
    println!("{}", max_of!(3, 9, 4));
    println!("{}", max_of!(1.5, 0.5));
}
