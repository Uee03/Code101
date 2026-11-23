pub use describe_derive::FieldNames;

/// Builds a `BTreeMap<String, V>` from `key => value` pairs. A trailing comma is allowed.
#[macro_export]
macro_rules! string_map {
    ($($key:expr => $value:expr),* $(,)?) => {{
        #[allow(unused_mut)]
        let mut map = ::std::collections::BTreeMap::new();
        $( map.insert(($key).to_string(), $value); )*
        map
    }};
}

/// Counts the token trees it is given, at compile time.
#[macro_export]
macro_rules! count {
    () => { 0usize };
    ($head:tt $($tail:tt)*) => { 1usize + $crate::count!($($tail)*) };
}

/// Shows hygiene: the `temp` inside the macro is not the caller's `temp`.
#[macro_export]
macro_rules! with_temp {
    ($e:expr) => {{
        let temp = 100;
        $e + temp
    }};
}

/// Declares a numeric id newtype that prints as `prefix-0042`.
#[macro_export]
macro_rules! id_type {
    ($name:ident, $prefix:literal) => {
        #[derive(Debug, Clone, Copy, PartialEq, Eq, PartialOrd, Ord)]
        pub struct $name(pub u32);

        impl ::std::fmt::Display for $name {
            fn fmt(&self, f: &mut ::std::fmt::Formatter<'_>) -> ::std::fmt::Result {
                write!(f, "{}-{:04}", $prefix, self.0)
            }
        }
    };
}

id_type!(UserId, "usr");
id_type!(OrderId, "ord");

#[derive(FieldNames)]
pub struct Order {
    pub id: OrderId,
    pub user: UserId,
    pub total_cents: u64,
}

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn string_map_sorts_and_allows_a_trailing_comma() {
        let map = string_map! { "b" => 2, "a" => 1, };
        assert_eq!(format!("{map:?}"), r#"{"a": 1, "b": 2}"#);
    }

    #[test]
    fn count_counts_token_trees() {
        assert_eq!(count!(x y z), 3);
        assert_eq!(count!(), 0);
    }

    #[test]
    fn temp_is_hygienic() {
        let temp = 1;
        assert_eq!(with_temp!(temp * 2), 102);
    }

    #[test]
    fn ids_are_zero_padded() {
        assert_eq!(UserId(42).to_string(), "usr-0042");
        assert_eq!(OrderId(7).to_string(), "ord-0007");
    }

    #[test]
    fn derive_lists_field_names() {
        assert_eq!(Order::FIELD_NAMES, &["id", "user", "total_cents"]);
    }
}
