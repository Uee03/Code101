from abc import ABC, abstractmethod


class Carrier(ABC):
    @abstractmethod
    def base_cents(self):
        ...


class PostCarrier(Carrier):
    def base_cents(self):
        return 300


class CourierCarrier(Carrier):
    def base_cents(self):
        return 800


class Speed(ABC):
    @abstractmethod
    def surcharge_cents(self):
        ...


class StandardSpeed(Speed):
    def surcharge_cents(self):
        return 0


class ExpressSpeed(Speed):
    def surcharge_cents(self):
        return 500


class Shipping:
    def __init__(self, carrier: Carrier, speed: Speed):
        self.carrier = carrier
        self.speed = speed

    def cost_cents(self):
        return self.carrier.base_cents() + self.speed.surcharge_cents()


for carrier in [PostCarrier(), CourierCarrier()]:
    for speed in [StandardSpeed(), ExpressSpeed()]:
        print(Shipping(carrier, speed).cost_cents())
