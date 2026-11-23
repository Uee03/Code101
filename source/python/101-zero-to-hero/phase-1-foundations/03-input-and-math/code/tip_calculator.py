# Tip calculator: asks for a bill, works out the tip and the total.
bill_text = input("Bill amount: ")
tip_text = input("Tip percent: ")

# input() always gives text, so we turn the text into numbers.
bill = float(bill_text)
tip_percent = float(tip_text)

tip = bill * tip_percent / 100
total = bill + tip

print(f"Tip: {tip:.2f}")
print(f"Total: {total:.2f}")
