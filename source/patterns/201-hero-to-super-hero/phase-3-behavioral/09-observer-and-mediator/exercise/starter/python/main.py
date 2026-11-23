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


# TODO 1: write FreezeWarning with update(degrees) that prints "warning: freezing" only when degrees is below 0.

thermometer = Thermometer()
thermometer.subscribe(Display())
# TODO 2: subscribe a FreezeWarning to the thermometer here
thermometer.set_temperature(5)
thermometer.set_temperature(-3)
