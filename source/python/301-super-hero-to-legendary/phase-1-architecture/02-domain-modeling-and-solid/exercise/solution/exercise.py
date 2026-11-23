from dataclasses import dataclass


class DomainError(Exception):
    pass


@dataclass(frozen=True)
class Estimate:
    hours: float


@dataclass(frozen=True)
class Budget:
    hours: float

    def __post_init__(self) -> None:
        if self.hours < 0:
            raise DomainError("a budget cannot be negative")

    def spend(self, estimate: Estimate) -> "Budget":
        return Budget(self.hours - estimate.hours)


if __name__ == "__main__":
    budget = Budget(20.0)
    print(budget.spend(Estimate(8.0)))
    print(budget)
    try:
        budget.spend(Estimate(25.0))
    except DomainError as error:
        print(error)
