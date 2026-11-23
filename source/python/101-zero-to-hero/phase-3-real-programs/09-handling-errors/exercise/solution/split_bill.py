bill = 90

while True:
    try:
        people = int(input("Number of people: "))
    except ValueError:
        print("Use a whole number.")
        continue
    if people < 1:
        print("At least one person is needed.")
        continue
    break

print(f"Each person pays {bill / people:.2f}")
