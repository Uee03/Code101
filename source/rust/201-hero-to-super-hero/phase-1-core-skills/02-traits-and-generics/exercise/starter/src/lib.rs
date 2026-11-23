pub trait Summary {
    fn summary(&self) -> String;
}

pub struct Note {
    pub title: String,
}

pub struct Reminder {
    pub minutes: u32,
}

impl Summary for Note {
    fn summary(&self) -> String {
        format!("note: {}", self.title)
    }
}

impl Summary for Reminder {
    fn summary(&self) -> String {
        format!("reminder: {} min", self.minutes)
    }
}

pub fn render<T: Summary>(item: &T) -> String {
    // TODO: add the entry: prefix in the generic function.
    item.summary()
}

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn renders_two_implementations() {
        assert_eq!(render(&Note { title: "Rust".into() }), "entry: note: Rust");
        assert_eq!(render(&Reminder { minutes: 5 }), "entry: reminder: 5 min");
    }
}
