secret = "7"

while True:
    guess = input("Guess 1-10 (q to quit): ")
    if guess == "q":
        print("Goodbye!")
        break
    if guess == "":
        print("Type a guess first.")
        continue
    if guess == secret:
        print("Correct!")
        break
    print("Not yet. Try again.")
