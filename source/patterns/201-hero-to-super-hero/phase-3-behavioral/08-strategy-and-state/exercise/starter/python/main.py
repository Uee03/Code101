from abc import ABC, abstractmethod


class LightState(ABC):
    @property
    @abstractmethod
    def color(self) -> str:
        ...

    @abstractmethod
    def next(self) -> "LightState":
        ...


class Red(LightState):
    @property
    def color(self) -> str:
        return "red"

    def next(self) -> LightState:
        return Green()


class Green(LightState):
    @property
    def color(self) -> str:
        return "green"

    def next(self) -> LightState:
        # TODO 1: return a Yellow state
        raise NotImplementedError("TODO 1")


# TODO 2: write Yellow(LightState): its color is "yellow" and next() returns Red().


class Light:
    def __init__(self) -> None:
        self._state: LightState = Red()

    def color(self) -> str:
        return self._state.color

    def advance(self) -> None:
        self._state = self._state.next()


light = Light()
for _ in range(4):
    print(light.color())
    light.advance()
