fn tip(bill: f64, percent: f64) -> f64 {
    bill * percent / 100.0
}

fn show_total(label: &str, total: f64) {
    println!("{label}: {total:.2}");
}

fn main() {
    let bill = 80.0;
    let extra = tip(bill, 15.0);
    show_total("Tip", extra);
    show_total("Total", bill + extra);
}
