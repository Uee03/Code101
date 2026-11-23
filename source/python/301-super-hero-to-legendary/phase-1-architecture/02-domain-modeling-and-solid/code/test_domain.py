import unittest

from adapters import InMemoryProjectRepository, InMemoryUnitOfWork
from domain import DomainError, Estimate, Project, Task, WipLimitReached
from services import add_task


class EstimateTests(unittest.TestCase):
    def test_value_objects_compare_by_value(self) -> None:
        self.assertEqual(Estimate(2.0), Estimate(2.0))

    def test_rejects_values_outside_the_range(self) -> None:
        for hours in (0, -1, 41):
            with self.subTest(hours=hours):
                with self.assertRaises(DomainError):
                    Estimate(hours)


class TaskTests(unittest.TestCase):
    def test_entities_compare_by_identity_not_by_attributes(self) -> None:
        first = Task(1, "Write", Estimate(1.0))
        renamed = Task(1, "Write (renamed)", Estimate(2.0))
        other = Task(2, "Write", Estimate(1.0))
        self.assertEqual(first, renamed)
        self.assertNotEqual(first, other)


class ProjectTests(unittest.TestCase):
    def test_the_fourth_open_task_is_refused(self) -> None:
        project = Project(1, "Launch")
        for task_id in (1, 2, 3):
            project.add_task(Task(task_id, f"T{task_id}", Estimate(1.0)))
        with self.assertRaises(WipLimitReached):
            project.add_task(Task(4, "T4", Estimate(1.0)))

    def test_completing_a_task_frees_a_slot(self) -> None:
        project = Project(1, "Launch")
        for task_id in (1, 2, 3):
            project.add_task(Task(task_id, f"T{task_id}", Estimate(1.0)))
        project.complete(1)
        project.add_task(Task(4, "T4", Estimate(1.0)))
        self.assertEqual([task.id for task in project.open_tasks], [2, 3, 4])


class UnitOfWorkTests(unittest.TestCase):
    def test_a_refused_change_leaves_the_committed_state_alone(self) -> None:
        committed = {1: Project(1, "Launch")}
        uow = InMemoryUnitOfWork(committed)
        for task_id in (1, 2, 3):
            add_task(uow, 1, task_id, f"T{task_id}", 1.0)
        with self.assertRaises(WipLimitReached):
            add_task(uow, 1, 4, "T4", 1.0)
        self.assertEqual(len(committed[1].open_tasks), 3)
        self.assertEqual(uow.commits, 3)

    def test_unknown_project_is_a_domain_error(self) -> None:
        with self.assertRaises(DomainError):
            add_task(InMemoryUnitOfWork({}), 9, 1, "T1", 1.0)


class ProjectRepositoryContract:
    """Every adapter must pass these tests (Liskov substitution)."""

    def make_repository(self) -> InMemoryProjectRepository:
        raise NotImplementedError

    def test_get_of_an_unknown_id_returns_none(self) -> None:
        self.assertIsNone(self.make_repository().get(99))

    def test_add_then_get_returns_the_same_project(self) -> None:
        repository = self.make_repository()
        repository.add(Project(1, "Launch"))
        found = repository.get(1)
        self.assertIsNotNone(found)
        self.assertEqual(found.name, "Launch")


class InMemoryRepositoryTests(ProjectRepositoryContract, unittest.TestCase):
    def make_repository(self) -> InMemoryProjectRepository:
        return InMemoryProjectRepository({})


if __name__ == "__main__":
    unittest.main()
