import after
import before

print("--- before ---")
for notifier in [before.EmailNotifier(), before.PhoneNotifier()]:
    result = before.notify_shipped(notifier, "ana@example.com")
    print(f"Result: '{result}'")

print("--- after ---")
email = after.EmailNotifier()
phone = after.PhoneNotifier()
print(after.notify_shipped(email, "ana@example.com"))
print(phone.send_sms("+100", "Order shipped"))
print(phone.send_push("ana-phone", "Order shipped"))
# after.notify_shipped(phone, "ana@example.com")  # a type checker flags this line
