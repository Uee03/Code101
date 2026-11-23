import after
import before

print("--- before ---")
before.OrderService().place_order("ana@example.com", "Notebook")

print("--- after ---")
after.OrderService(after.SmtpEmailSender()).place_order("ana@example.com", "Notebook")
after.OrderService(after.SmsSender()).place_order("+100", "Notebook")

fake = after.FakeSender()
after.OrderService(fake).place_order("test@example.com", "Notebook")
if fake.sent == [("test@example.com", "Thanks for ordering Notebook")]:
    print("Check passed: the fake saw exactly one message")
else:
    print("Check FAILED")
