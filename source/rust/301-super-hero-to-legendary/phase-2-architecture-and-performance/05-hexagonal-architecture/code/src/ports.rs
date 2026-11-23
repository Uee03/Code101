use crate::domain::{Task, TaskError};

/// Driven port: how the application stores tasks.
pub trait TaskRepository {
    fn insert(&mut self, title: &str, created_at: u64) -> Result<Task, TaskError>;
    fn mark_done(&mut self, id: u32) -> Result<Task, TaskError>;
    fn list(&self) -> Result<Vec<Task>, TaskError>;
}

/// Driven port: where the application gets the current time (seconds since 1970).
pub trait Clock {
    fn now(&self) -> u64;
}

// A boxed repository is a repository, so one service type serves both a concrete
// adapter chosen at compile time and a `Box<dyn TaskRepository>` chosen at run time.
impl<T: TaskRepository + ?Sized> TaskRepository for Box<T> {
    fn insert(&mut self, title: &str, created_at: u64) -> Result<Task, TaskError> {
        (**self).insert(title, created_at)
    }

    fn mark_done(&mut self, id: u32) -> Result<Task, TaskError> {
        (**self).mark_done(id)
    }

    fn list(&self) -> Result<Vec<Task>, TaskError> {
        (**self).list()
    }
}
