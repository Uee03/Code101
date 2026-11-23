score = int(input("Score (0-100): "))

if score < 0 or score > 100:
    print("Invalid score")
elif score < 50:
    print("Fail")
elif score < 75:
    print("Pass")
else:
    print("Merit")
