import after
import before

ITEMS = [("Notebook", 1200, 2), ("Pen", 150, 4)]

print("--- before ---")
old_processor = before.OrderProcessor()
old_processor.process("vip", "email", "ana@example.com", ITEMS)
old_processor.process("student", "sms", "+100", ITEMS)
old_processor.process("regular", "email", "bo@example.com", ITEMS)

print("--- after ---")
store = after.OrderStore()
vip_by_email = after.OrderProcessor(after.PercentDiscount(20), after.EmailNotifier(), store)
student_by_sms = after.OrderProcessor(after.PercentDiscount(10), after.SmsNotifier(), store)
regular_by_email = after.OrderProcessor(after.NoDiscount(), after.EmailNotifier(), store)
vip_by_email.process("ana@example.com", ITEMS)
student_by_sms.process("+100", ITEMS)
regular_by_email.process("bo@example.com", ITEMS)
print(f"Stored orders: {store.count()}")
