use anyhow::{Context, Result};
use quantity_errors::parse_quantity;

fn order(input: &str) -> Result<u16> {
    let quantity = parse_quantity(input).context("reading order quantity")?;
    Ok(quantity)
}

fn main() -> Result<()> {
    println!("quantity: {}", order("12")?);
    if let Err(error) = order("0") {
        for cause in error.chain() {
            println!("reason: {cause}");
        }
    }
    Ok(())
}
