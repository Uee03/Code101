use fearless::{
    count_with_atomic, count_with_mutex, parallel_sum_of_squares, squares_via_channel,
};

fn main() {
    let values: Vec<u64> = (1..=100).collect();
    println!(
        "sum of squares 1..=100 with 4 workers: {}",
        parallel_sum_of_squares(&values, 4)
    );
    println!("squares via channel: {:?}", squares_via_channel(vec![3, 1, 2]));
    println!("mutex counter: {}", count_with_mutex(4, 1000));
    println!("atomic counter: {}", count_with_atomic(4, 1000));
}
