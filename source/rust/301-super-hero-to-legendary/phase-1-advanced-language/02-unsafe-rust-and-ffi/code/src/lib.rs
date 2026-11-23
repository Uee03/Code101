unsafe extern "C" {
    fn c101_checksum(data: *const u8, len: usize) -> u32;
}

/// Adler-32 checksum of `data`, computed by the C code in `csrc/`.
pub fn checksum(data: &[u8]) -> u32 {
    // SAFETY: `data.as_ptr()` is valid for reads of `data.len()` bytes for the whole call.
    // The C function only reads that range and keeps no pointer after it returns.
    unsafe { c101_checksum(data.as_ptr(), data.len()) }
}

/// Callable from C as `int32_t c101_double(int32_t value)`.
#[unsafe(no_mangle)]
pub extern "C" fn c101_double(value: i32) -> i32 {
    value.wrapping_mul(2)
}

/// Splits a slice into two non-overlapping mutable halves. The left half is `len / 2` long.
pub fn split_halves_mut<T>(items: &mut [T]) -> (&mut [T], &mut [T]) {
    let len = items.len();
    let mid = len / 2;
    let ptr = items.as_mut_ptr();
    // SAFETY: `mid <= len`, so both ranges lie inside `items`. They do not overlap: the first
    // is `0..mid` and the second is `mid..len`. The input borrow is not used again while the
    // two returned borrows live, so nothing else can alias them.
    unsafe {
        (
            std::slice::from_raw_parts_mut(ptr, mid),
            std::slice::from_raw_parts_mut(ptr.add(mid), len - mid),
        )
    }
}

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn checksum_matches_known_values() {
        assert_eq!(checksum(b""), 1);
        assert_eq!(checksum(b"abc"), 0x024d_0127);
        assert_eq!(checksum(b"Wikipedia"), 0x11e6_0398);
    }

    #[test]
    fn halves_do_not_overlap() {
        let mut values = [1, 2, 3, 4, 5];
        let (left, right) = split_halves_mut(&mut values);
        left[0] = 10;
        right[0] = 30;
        assert_eq!(values, [10, 2, 30, 4, 5]);
    }

    #[test]
    fn empty_slice_gives_two_empty_halves() {
        let mut values: [u8; 0] = [];
        let (left, right) = split_halves_mut(&mut values);
        assert!(left.is_empty() && right.is_empty());
    }

    #[test]
    fn exported_function_doubles() {
        assert_eq!(c101_double(21), 42);
    }
}
