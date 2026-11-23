use std::io;

fn read_number() -> Result<f64, io::Error> {
    loop {
        println!("Number:");
        let mut text = String::new();
        if io::stdin().read_line(&mut text)? == 0 {
            return Err(io::Error::new(io::ErrorKind::UnexpectedEof, "Input ended"));
        }
        match text.trim().parse::<f64>() {
            Ok(value) => return Ok(value),
            Err(_) => println!("Please use digits, for example 12."),
        }
    }
}

fn main() -> Result<(), io::Error> {
    let value = read_number()?;
    println!("Accepted: {value:.2}");
    Ok(())
}
