# A variable is a labelled jar that holds a value.
name = "Ada"
age = 36
height_m = 1.65
is_student = False

print("Name:", name)
print("Age:", age)
print("Height in metres:", height_m)
print("Is a student:", is_student)

# type() tells us what kind of value is inside the jar.
print(type(name))
print(type(age))
print(type(height_m))
print(type(is_student))

# An f-string puts variables inside text.
print(f"{name} is {age} years old and {height_m} m tall.")

# A variable can be changed after it is created.
age = age + 1
print(f"Next year {name} will be {age}.")
