use std::time::{SystemTime, UNIX_EPOCH};

use crate::domain::{Task, TaskError};
use crate::ports::{Clock, TaskRepository};

#[derive(Debug, Default)]
pub struct InMemoryTaskRepository {
    tasks: Vec<Task>,
}

impl TaskRepository for InMemoryTaskRepository {
    fn insert(&mut self, title: &str, created_at: u64) -> Result<Task, TaskError> {
        let count = u32::try_from(self.tasks.len())
            .map_err(|_| TaskError::Storage("too many tasks".to_string()))?;
        let task = Task {
            id: count + 1,
            title: title.to_string(),
            created_at,
            done: false,
        };
        self.tasks.push(task.clone());
        Ok(task)
    }

    fn mark_done(&mut self, id: u32) -> Result<Task, TaskError> {
        match self.tasks.iter_mut().find(|task| task.id == id) {
            Some(task) => {
                task.done = true;
                Ok(task.clone())
            }
            None => Err(TaskError::NotFound(id)),
        }
    }

    fn list(&self) -> Result<Vec<Task>, TaskError> {
        Ok(self.tasks.clone())
    }
}

/// A repository whose storage is always down, to exercise the error path.
pub struct FailingRepository;

impl TaskRepository for FailingRepository {
    fn insert(&mut self, _title: &str, _created_at: u64) -> Result<Task, TaskError> {
        Err(TaskError::Storage("disk offline".to_string()))
    }

    fn mark_done(&mut self, _id: u32) -> Result<Task, TaskError> {
        Err(TaskError::Storage("disk offline".to_string()))
    }

    fn list(&self) -> Result<Vec<Task>, TaskError> {
        Err(TaskError::Storage("disk offline".to_string()))
    }
}

pub struct SystemClock;

impl Clock for SystemClock {
    fn now(&self) -> u64 {
        SystemTime::now()
            .duration_since(UNIX_EPOCH)
            .map(|elapsed| elapsed.as_secs())
            .unwrap_or(0)
    }
}

/// A clock that never moves, so tests and demos are deterministic.
pub struct FixedClock(pub u64);

impl Clock for FixedClock {
    fn now(&self) -> u64 {
        self.0
    }
}
