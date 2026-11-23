use std::fmt;

mod sealed {
    pub trait Sealed {}
}

/// A state an invoice can be in. The trait is sealed: only this crate can add states.
pub trait State: sealed::Sealed {
    const NAME: &'static str;
}

#[derive(Debug)]
pub struct Draft;

#[derive(Debug)]
pub struct Submitted;

#[derive(Debug)]
pub struct Approved {
    approver: String,
}

impl sealed::Sealed for Draft {}
impl sealed::Sealed for Submitted {}
impl sealed::Sealed for Approved {}

impl State for Draft {
    const NAME: &'static str = "Draft";
}

impl State for Submitted {
    const NAME: &'static str = "Submitted";
}

impl State for Approved {
    const NAME: &'static str = "Approved";
}

#[derive(Debug)]
pub struct Invoice<S: State> {
    number: u32,
    lines: Vec<(String, u64)>,
    state: S,
}

impl Invoice<Draft> {
    pub fn new(number: u32) -> Self {
        Invoice {
            number,
            lines: Vec::new(),
            state: Draft,
        }
    }

    pub fn add_line(mut self, description: &str, cents: u64) -> Self {
        self.lines.push((description.to_string(), cents));
        self
    }

    /// An empty draft is handed back to the caller instead of being lost.
    pub fn submit(self) -> Result<Invoice<Submitted>, Invoice<Draft>> {
        if self.lines.is_empty() {
            return Err(self);
        }
        Ok(Invoice {
            number: self.number,
            lines: self.lines,
            state: Submitted,
        })
    }
}

impl Invoice<Submitted> {
    /// Only a submitted invoice can be approved. Approving a draft does not compile:
    ///
    /// ```compile_fail
    /// use invoice_states::Invoice;
    /// let draft = Invoice::new(1).add_line("work", 100);
    /// let _approved = draft.approve("ana");
    /// ```
    pub fn approve(self, approver: &str) -> Invoice<Approved> {
        Invoice {
            number: self.number,
            lines: self.lines,
            state: Approved {
                approver: approver.to_string(),
            },
        }
    }
}

impl Invoice<Approved> {
    pub fn approver(&self) -> &str {
        &self.state.approver
    }
}

impl<S: State> Invoice<S> {
    pub fn number(&self) -> u32 {
        self.number
    }

    pub fn total_cents(&self) -> u64 {
        self.lines.iter().map(|(_, cents)| cents).sum()
    }
}

impl<S: State> fmt::Display for Invoice<S> {
    fn fmt(&self, f: &mut fmt::Formatter<'_>) -> fmt::Result {
        let total = self.total_cents();
        write!(
            f,
            "invoice #{} [{}] total {}.{:02}",
            self.number,
            S::NAME,
            total / 100,
            total % 100
        )
    }
}

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn total_adds_all_lines() {
        let draft = Invoice::new(7).add_line("a", 100).add_line("b", 250);
        assert_eq!(draft.total_cents(), 350);
    }

    #[test]
    fn empty_draft_is_returned_not_lost() {
        match Invoice::new(2).submit() {
            Ok(_) => panic!("an empty draft must not be submitted"),
            Err(draft) => assert_eq!(draft.number(), 2),
        }
    }

    #[test]
    fn full_flow_reaches_approved() {
        let submitted = match Invoice::new(3).add_line("work", 1999).submit() {
            Ok(submitted) => submitted,
            Err(_) => panic!("the draft has a line"),
        };
        let approved = submitted.approve("ana");
        assert_eq!(approved.approver(), "ana");
        assert_eq!(approved.to_string(), "invoice #3 [Approved] total 19.99");
    }
}
