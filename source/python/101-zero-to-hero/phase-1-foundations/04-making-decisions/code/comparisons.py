# Comparisons ask a yes/no question. The answer is True or False.
print("5 > 3 :", 5 > 3)
print("5 < 3 :", 5 < 3)
print("5 == 5 :", 5 == 5)
print("5 != 5 :", 5 != 5)
print("5 >= 5 :", 5 >= 5)
print('"a" == "A" :', "a" == "A")

# and, or, not combine yes/no answers.
age = 20
has_ticket = True
print("adult with ticket:", age >= 18 and has_ticket)
print("child or has ticket:", age < 18 or has_ticket)
print("no ticket:", not has_ticket)
