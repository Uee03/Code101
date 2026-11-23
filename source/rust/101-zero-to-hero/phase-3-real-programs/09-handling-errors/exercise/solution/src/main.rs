use std::io;

fn read_quantity() -> Result<i32, io::Error> {
    loop {
        println!("Quantity (1-99):");
        let mut text = String::new();
        if io::stdin().read_line(&mut text)? == 0 {
            return Err(io::Error::new(io::ErrorKind::UnexpectedEof, "Input ended"));
        }
        match text.trim().parse::<i32>() {
            Ok(value) => {
                if value >= 1 && value <= 99 {
                    return Ok(value);
                }
                println!("Use a quantity from 1 to 99.");
            }
            Err(_) => println!("Please use a whole number."),
        }
    }
}

fn main() -> Result<(), io::Error> {
    let quantity = read_quantity()?;
    println!("Accepted quantity: {quantity}");
    Ok(())
}
