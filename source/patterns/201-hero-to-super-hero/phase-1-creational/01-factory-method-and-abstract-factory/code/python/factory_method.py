from abc import ABC, abstractmethod


class Transport(ABC):
    @abstractmethod
    def deliver(self, cargo: str) -> str:
        ...


class Truck(Transport):
    def deliver(self, cargo: str) -> str:
        return f"Truck carries {cargo} by road"


class Ship(Transport):
    def deliver(self, cargo: str) -> str:
        return f"Ship carries {cargo} by sea"


class Logistics(ABC):
    def plan_delivery(self, cargo: str) -> str:
        transport = self.create_transport()
        return f"Plan: {transport.deliver(cargo)}"

    @abstractmethod
    def create_transport(self) -> Transport:
        ...


class RoadLogistics(Logistics):
    def create_transport(self) -> Transport:
        return Truck()


class SeaLogistics(Logistics):
    def create_transport(self) -> Transport:
        return Ship()


def demo() -> None:
    planners = {"road": RoadLogistics(), "sea": SeaLogistics()}
    for mode in ("road", "sea"):
        print(planners[mode].plan_delivery("5 crates"))
