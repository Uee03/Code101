import after
import before

print("--- before ---")
for payment in [before.CardPayment(), before.GiftCardPayment()]:
    try:
        print(before.cancel_order(payment, 1500))
    except RuntimeError as error:
        print(f"Crash: {error}")

print("--- after ---")
card = after.CardPayment()
gift = after.GiftCardPayment()
for payable in [card, gift]:
    print(payable.pay(1500))
print(after.cancel_order(card, 1500))
# after.cancel_order(gift, 1500)  # a type checker flags this line before you run it
