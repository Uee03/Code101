use hexagon::adapters::{FailingRepository, FixedClock, InMemoryTaskRepository};
use hexagon::ports::TaskRepository;
use hexagon::service::TaskService;

fn main() {
    // Composition root: the only place that knows which adapters are used.
    let storage = std::env::args()
        .nth(1)
        .unwrap_or_else(|| "memory".to_string());
    let repo: Box<dyn TaskRepository> = match storage.as_str() {
        "failing" => Box::new(FailingRepository),
        _ => Box::new(InMemoryTaskRepository::default()),
    };
    let mut service = TaskService::new(repo, FixedClock(1_700_000_000));

    for title in ["Write hexagon lesson", "Review ports", "   "] {
        match service.add_task(title) {
            Ok(task) => println!(
                "added #{} \"{}\" at {}",
                task.id, task.title, task.created_at
            ),
            Err(err) => println!("rejected: {err}"),
        }
    }
    match service.complete(1) {
        Ok(task) => println!("completed #{}", task.id),
        Err(err) => println!("failed: {err}"),
    }
    match service.open_titles() {
        Ok(titles) => println!("open: {titles:?}"),
        Err(err) => println!("failed: {err}"),
    }
}
