bill_text = input("Bill amount: ")
people_text = input("Number of people: ")

bill = float(bill_text)
people = int(people_text)

share = bill / people

print(f"Each person pays {share:.2f}")
