package main

import "fmt"

type Expense struct {
	Label string
	Cents int
}

func (e Expense) String() string {
	return fmt.Sprintf("%s: %d cents", e.Label, e.Cents)
}

func (e *Expense) Discount(extra int) {
	e.Cents -= extra
}

func main() {
	expense := Expense{Label: "Tea", Cents: 250}
	fmt.Println(expense.String())
	expense.Discount(50)
	fmt.Println(expense.String())
	copyExpense := expense
	copyExpense.Label = "Copy"
	fmt.Println("Original label:", expense.Label)
}
