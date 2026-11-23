fn main() {
    let mut countdown = 2;
    loop {
        println!("Countdown: {countdown}");
        countdown = countdown - 1;
        if countdown == 0 {
            break;
        }
    }
    let mut stock = 2;
    while stock > 0 {
        println!("Packing box {stock}");
        stock = stock - 1;
    }
    let mut total = 0;
    for number in 1..=3 {
        total = total + number;
    }
    println!("Total: {total}");
    for index in 0..2 {
        println!("Index: {index}");
    }
}
