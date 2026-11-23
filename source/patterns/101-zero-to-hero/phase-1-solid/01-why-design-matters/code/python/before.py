def checkout(items, email):
    total = 0
    for name, price, qty in items:
        total = total + price * qty
    if total > 2500:
        total = total - total * 10 // 100
    print("INVOICE")
    for name, price, qty in items:
        line = price * qty
        print(name + " x" + str(qty) + " = " + str(line // 100) + "." + str(line % 100).zfill(2))
    print("Total: " + str(total // 100) + "." + str(total % 100).zfill(2))
    print("Email sent to " + email)
