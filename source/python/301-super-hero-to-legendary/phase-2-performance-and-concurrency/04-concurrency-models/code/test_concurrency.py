import unittest

from bench import run_processes, run_serial, run_threads
from race import count
from workloads import cpu_work, io_work


class WorkloadTests(unittest.TestCase):
    def test_cpu_work_is_deterministic(self) -> None:
        self.assertEqual(cpu_work(10), 19)

    def test_io_work_returns_what_it_slept(self) -> None:
        self.assertEqual(io_work(0.01), 0.01)


class RunnerTests(unittest.TestCase):
    JOBS = [10, 20, 30]

    def test_every_model_returns_the_same_results_in_the_same_order(self) -> None:
        expected = run_serial(cpu_work, self.JOBS)
        self.assertEqual(run_threads(cpu_work, self.JOBS), expected)
        self.assertEqual(run_processes(cpu_work, self.JOBS), expected)


class RaceTests(unittest.TestCase):
    def test_a_lock_makes_the_count_exact(self) -> None:
        self.assertEqual(count(True, threads=4, per_thread=10_000), 40_000)

    def test_without_a_lock_the_count_is_never_above_expected(self) -> None:
        self.assertLessEqual(count(False, threads=4, per_thread=10_000), 40_000)


if __name__ == "__main__":
    unittest.main()
