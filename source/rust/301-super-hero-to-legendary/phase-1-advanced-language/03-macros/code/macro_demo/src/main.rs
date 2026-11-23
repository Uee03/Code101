use macro_demo::{Order, OrderId, UserId, count, string_map, with_temp};

fn main() {
    let ages = string_map! { "carol" => 31, "alice" => 29 };
    println!("{ages:?}");
    println!("tokens: {}", count!(a b c d));

    let temp = 1;
    println!("hygiene: {}", with_temp!(temp * 2));

    println!("{} {}", UserId(42), OrderId(7));
    println!("order fields: {:?}", Order::FIELD_NAMES);
}
