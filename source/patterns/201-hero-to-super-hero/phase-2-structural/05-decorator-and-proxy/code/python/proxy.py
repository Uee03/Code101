from abc import ABC, abstractmethod


class Forecast(ABC):
    @abstractmethod
    def get(self, city: str) -> str:
        ...


class SlowForecast(Forecast):
    def __init__(self) -> None:
        self.calls = 0

    def get(self, city: str) -> str:
        self.calls += 1
        print(f"(slow call for {city})")
        return f"forecast for {city}"


class CachingForecast(Forecast):
    def __init__(self, real: Forecast) -> None:
        self._real = real
        self._cache: dict[str, str] = {}

    def get(self, city: str) -> str:
        if city not in self._cache:
            self._cache[city] = self._real.get(city)
        return self._cache[city]


class GuardedForecast(Forecast):
    def __init__(self, real: Forecast, role: str) -> None:
        self._real = real
        self._role = role

    def get(self, city: str) -> str:
        if self._role != "member":
            raise PermissionError("members only")
        return self._real.get(city)


def demo() -> None:
    real = SlowForecast()
    cached = CachingForecast(real)
    print(cached.get("Oslo"))
    print(cached.get("Oslo"))
    print(cached.get("Rome"))
    print(f"real calls: {real.calls}")
    guarded = GuardedForecast(real, "guest")
    try:
        guarded.get("Oslo")
    except PermissionError as error:
        print(f"Denied: {error}")
