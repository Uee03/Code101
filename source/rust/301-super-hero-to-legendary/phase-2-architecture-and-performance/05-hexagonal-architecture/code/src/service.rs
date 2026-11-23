use crate::domain::{Task, TaskError, validate_title};
use crate::ports::{Clock, TaskRepository};

/// The application service: orchestrates domain rules and ports, knows no adapter.
pub struct TaskService<R: TaskRepository, C: Clock> {
    repo: R,
    clock: C,
}

impl<R: TaskRepository, C: Clock> TaskService<R, C> {
    pub fn new(repo: R, clock: C) -> Self {
        TaskService { repo, clock }
    }

    pub fn add_task(&mut self, raw_title: &str) -> Result<Task, TaskError> {
        let title = validate_title(raw_title)?;
        self.repo.insert(&title, self.clock.now())
    }

    pub fn complete(&mut self, id: u32) -> Result<Task, TaskError> {
        self.repo.mark_done(id)
    }

    pub fn open_titles(&self) -> Result<Vec<String>, TaskError> {
        let tasks = self.repo.list()?;
        Ok(tasks
            .into_iter()
            .filter(|task| !task.done)
            .map(|task| task.title)
            .collect())
    }
}

#[cfg(test)]
mod tests {
    use super::*;
    use crate::adapters::{FailingRepository, FixedClock, InMemoryTaskRepository};

    #[test]
    fn add_validates_and_stamps_the_time() {
        let mut service = TaskService::new(InMemoryTaskRepository::default(), FixedClock(500));
        let task = service.add_task("  write tests  ").expect("valid title");
        assert_eq!((task.id, task.title.as_str(), task.created_at), (1, "write tests", 500));
        assert_eq!(service.add_task("   "), Err(TaskError::EmptyTitle));
    }

    #[test]
    fn completed_tasks_leave_the_open_list() {
        let mut service = TaskService::new(InMemoryTaskRepository::default(), FixedClock(1));
        service.add_task("one").expect("valid title");
        service.add_task("two").expect("valid title");
        service.complete(1).expect("task one exists");
        assert_eq!(service.open_titles(), Ok(vec!["two".to_string()]));
    }

    #[test]
    fn unknown_ids_are_not_found() {
        let mut service = TaskService::new(InMemoryTaskRepository::default(), FixedClock(1));
        assert_eq!(service.complete(9), Err(TaskError::NotFound(9)));
    }

    #[test]
    fn storage_failures_reach_the_caller() {
        let mut service = TaskService::new(FailingRepository, FixedClock(1));
        assert_eq!(
            service.add_task("valid"),
            Err(TaskError::Storage("disk offline".to_string()))
        );
    }

    #[test]
    fn the_same_service_works_with_a_boxed_trait_object() {
        let repo: Box<dyn TaskRepository> = Box::new(InMemoryTaskRepository::default());
        let mut service = TaskService::new(repo, FixedClock(1));
        assert!(service.add_task("boxed").is_ok());
    }
}
