class SavingsJar:
    def __init__(self, label, cents):
        self.label = label
        self.cents = cents

    def deposit(self, cents):
        if cents <= 0:
            print("Deposit must be positive.")
            return
        self.cents = self.cents + cents

    def describe(self):
        return f"{self.label}: {self.cents} cents"


holiday = SavingsJar("Holiday", 500)
books = SavingsJar("Books", 200)
holiday.deposit(150)
print(holiday.describe())
print(books.describe())
