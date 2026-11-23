number = int(input("Times table number: "))

for multiplier in range(1, 4):
    product = number * multiplier
    print(f"{number} x {multiplier} = {product}")
