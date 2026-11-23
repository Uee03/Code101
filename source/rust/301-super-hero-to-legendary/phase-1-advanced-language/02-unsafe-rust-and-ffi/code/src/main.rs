use checksum_ffi::{checksum, split_halves_mut};

fn main() {
    println!("abc -> {:#010x}", checksum(b"abc"));
    println!("Wikipedia -> {:#010x}", checksum(b"Wikipedia"));

    let mut values = [1, 2, 3, 4, 5];
    let (left, right) = split_halves_mut(&mut values);
    left[0] = 10;
    right[0] = 30;
    println!("{values:?}");
}
