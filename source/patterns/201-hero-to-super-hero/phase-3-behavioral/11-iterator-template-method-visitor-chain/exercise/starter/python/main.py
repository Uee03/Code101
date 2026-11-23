from typing import Optional


class Check:
    def __init__(self) -> None:
        self._next: Optional["Check"] = None

    def set_next(self, check: "Check") -> "Check":
        self._next = check
        return check

    def verify(self, password: str) -> str:
        problem = self.problem(password)
        if problem is not None:
            return problem
        if self._next is not None:
            return self._next.verify(password)
        return "ok"

    def problem(self, password: str) -> Optional[str]:
        return None


class MinLength(Check):
    def problem(self, password: str) -> Optional[str]:
        if len(password) < 8:
            return "too short"
        return None


# TODO 1: write HasDigit(Check): problem() returns "needs a digit" when the password has no digit, otherwise None.
#         Hint: any(character.isdigit() for character in password)

chain = MinLength()
# TODO 2: chain.set_next(HasDigit())
for password in ("short", "abcdefgh", "abcdefg1"):
    print(f"{password}: {chain.verify(password)}")
