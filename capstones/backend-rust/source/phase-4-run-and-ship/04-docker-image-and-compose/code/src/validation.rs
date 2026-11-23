use crate::error::{AppError, FieldError};

pub trait Validate {
    fn validate(&self) -> Result<(), AppError>;
}

/// Collects every problem of a body, so the client sees all of them at once.
#[derive(Default)]
pub struct Check {
    errors: Vec<FieldError>,
}

impl Check {
    pub fn fail(&mut self, pointer: &str, detail: impl Into<String>) {
        self.errors.push(FieldError::new(pointer, detail));
    }

    /// Text whose trimmed length must be between `min` and `max` characters (the database checks `btrim`).
    pub fn text(&mut self, pointer: &str, value: &str, min: usize, max: usize) {
        let length = value.trim().chars().count();
        if length < min || length > max {
            self.fail(pointer, format!("must be between {min} and {max} characters"));
        }
    }

    pub fn max_chars(&mut self, pointer: &str, value: &str, max: usize) {
        if value.chars().count() > max {
            self.fail(pointer, format!("must be at most {max} characters"));
        }
    }

    pub fn finish(self) -> Result<(), AppError> {
        if self.errors.is_empty() { Ok(()) } else { Err(AppError::Validation(self.errors)) }
    }
}
