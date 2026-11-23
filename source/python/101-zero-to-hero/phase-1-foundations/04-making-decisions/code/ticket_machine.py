# Ticket machine: the price depends on the visitor's age.
age = int(input("How old are you? "))

if age < 0:
    print("Age cannot be negative.")
elif age < 5:
    print("Ticket: free")
elif age < 18:
    print("Ticket: child price, 5.00")
elif age < 65:
    print("Ticket: adult price, 10.00")
else:
    print("Ticket: senior price, 7.00")
