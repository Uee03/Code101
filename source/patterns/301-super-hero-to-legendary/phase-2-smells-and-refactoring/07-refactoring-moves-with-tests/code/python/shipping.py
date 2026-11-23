from dataclasses import dataclass


def legacy_cost(weight_kg, carrier, express, zone, insured, declared_value, fragile):
    if carrier == "post":
        cost = 500 + weight_kg * 120
    elif carrier == "fast":
        cost = 900 + weight_kg * 200
    elif carrier == "freight":
        cost = 2000 + weight_kg * 60
        if cost < 3000:
            cost = 3000
    else:
        raise ValueError("unknown carrier: " + carrier)
    if zone == "eu":
        cost += 400
    elif zone == "world":
        cost += 1500
    if express:
        cost = cost * 3 // 2
    if insured:
        cost += declared_value // 50
    if fragile:
        cost += 250
    return cost


@dataclass(frozen=True)
class Parcel:
    weight_kg: int
    zone: str
    express: bool
    insured: bool
    declared_value: int
    fragile: bool

    def surcharges(self):
        insurance = self.declared_value // 50 if self.insured else 0
        return insurance + (250 if self.fragile else 0)


def carrier_price(carrier, weight_kg):
    if carrier == "post":
        return 500 + weight_kg * 120
    if carrier == "fast":
        return 900 + weight_kg * 200
    if carrier == "freight":
        return max(3000, 2000 + weight_kg * 60)
    raise ValueError("unknown carrier: " + carrier)


def zone_fee(zone):
    if zone == "eu":
        return 400
    if zone == "world":
        return 1500
    return 0


def step1_cost(carrier, parcel):
    cost = carrier_price(carrier, parcel.weight_kg) + zone_fee(parcel.zone)
    if parcel.express:
        cost = cost * 3 // 2
    if parcel.insured:
        cost += parcel.declared_value // 50
    if parcel.fragile:
        cost += 250
    return cost


class Carrier:
    def __init__(self, base, per_kg):
        self.base = base
        self.per_kg = per_kg

    def price(self, weight_kg):
        return self.base + weight_kg * self.per_kg


class FreightCarrier(Carrier):
    def price(self, weight_kg):
        return max(3000, super().price(weight_kg))


CARRIERS = {"post": Carrier(500, 120), "fast": Carrier(900, 200), "freight": FreightCarrier(2000, 60)}
ZONE_FEES = {"domestic": 0, "eu": 400, "world": 1500}


def final_cost(carrier_name, parcel):
    carrier = CARRIERS.get(carrier_name)
    if carrier is None:
        raise ValueError("unknown carrier: " + carrier_name)
    cost = carrier.price(parcel.weight_kg) + ZONE_FEES.get(parcel.zone, 0)
    if parcel.express:
        cost = cost * 3 // 2
    return cost + parcel.surcharges()


def broken_cost(carrier_name, parcel):
    carrier = CARRIERS[carrier_name]
    cost = carrier.price(parcel.weight_kg) + ZONE_FEES.get(parcel.zone, 0) + parcel.surcharges()
    if parcel.express:
        cost = cost * 3 // 2
    return cost
