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
        # TODO 1: raise DomainError("a budget cannot be negative") when hours is below 0
        pass

    def spend(self, estimate: Estimate) -> "Budget":
        # TODO 2: return a NEW Budget with the estimate's hours subtracted
        # TODO 3: let the constructor refuse an overspend (do not repeat the check here)
        raise NotImplementedError


if __name__ == "__main__":
    budget = Budget(20.0)
    print(budget.spend(Estimate(8.0)))
    print(budget)
    try:
        budget.spend(Estimate(25.0))
    except DomainError as error:
        print(error)
