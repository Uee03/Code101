class Thermometer:
    def __init__(self) -> None:
        self._listeners: list = []

    def subscribe(self, listener) -> None:
        self._listeners.append(listener)

    def set_temperature(self, degrees: int) -> None:
        for listener in list(self._listeners):
            listener.update(degrees)


class Display:
    def update(self, degrees: int) -> None:
        print(f"display: {degrees} C")


class FreezeWarning:
    def update(self, degrees: int) -> None:
        if degrees < 0:
            print("warning: freezing")


thermometer = Thermometer()
thermometer.subscribe(Display())
thermometer.subscribe(FreezeWarning())
thermometer.set_temperature(5)
thermometer.set_temperature(-3)
