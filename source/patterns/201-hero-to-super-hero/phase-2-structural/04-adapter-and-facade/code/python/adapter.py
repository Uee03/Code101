from abc import ABC, abstractmethod


class TemperatureSource(ABC):
    @abstractmethod
    def celsius(self) -> int:
        ...


class CelsiusSensor(TemperatureSource):
    def __init__(self, degrees: int) -> None:
        self._degrees = degrees

    def celsius(self) -> int:
        return self._degrees


class FahrenheitSensor:
    def __init__(self, degrees: int) -> None:
        self._degrees = degrees

    def read_f(self) -> int:
        return self._degrees


class FahrenheitAdapter(TemperatureSource):
    def __init__(self, sensor: FahrenheitSensor) -> None:
        self._sensor = sensor

    def celsius(self) -> int:
        return (self._sensor.read_f() - 32) * 5 // 9


def report(source: TemperatureSource) -> str:
    return f"{source.celsius()} C"


def demo() -> None:
    print(report(CelsiusSensor(20)))
    print(report(FahrenheitAdapter(FahrenheitSensor(212))))
    print(report(FahrenheitAdapter(FahrenheitSensor(50))))
