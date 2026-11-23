class OrderProcessor:
    def process(self, customer_type, channel, address, items):
        total = 0
        for _, price, qty in items:
            total += price * qty
        if customer_type == "vip":
            total = total - total * 20 // 100
        elif customer_type == "student":
            total = total - total * 10 // 100
        if channel == "email":
            print(f"Email to {address}: order total {total}")
        elif channel == "sms":
            print(f"SMS to {address}: order total {total}")
        print(f"Saved order for {address}")
