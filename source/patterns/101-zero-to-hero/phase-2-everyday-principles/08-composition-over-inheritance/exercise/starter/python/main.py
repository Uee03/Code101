class PostShipping:
    def cost_cents(self):
        return 300


class ExpressPostShipping(PostShipping):
    def cost_cents(self):
        return super().cost_cents() + 500


class CourierShipping:
    def cost_cents(self):
        return 800


class ExpressCourierShipping(CourierShipping):
    def cost_cents(self):
        return super().cost_cents() + 500


# TODO 1: make an abstract class Carrier (ABC) with base_cents(), and PostCarrier (300) and CourierCarrier (800).
# TODO 2: make an abstract class Speed (ABC) with surcharge_cents(), and StandardSpeed (0) and ExpressSpeed (500).
# TODO 3: make one class Shipping(carrier, speed) whose cost_cents() adds the carrier base and the speed surcharge.
# TODO 4: delete the four classes above. Replace the loop below with two nested loops over the carriers
#         [PostCarrier(), CourierCarrier()] and the speeds [StandardSpeed(), ExpressSpeed()], printing
#         Shipping(carrier, speed).cost_cents(). The output must not change.

for shipping in [PostShipping(), ExpressPostShipping(), CourierShipping(), ExpressCourierShipping()]:
    print(shipping.cost_cents())
