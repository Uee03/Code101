package main

import "fmt"

type Expense struct {
	Label string
	Cents int
}

func (e Expense) String() string {
	return fmt.Sprintf("%s: %d cents", e.Label, e.Cents)
}

func (e *Expense) AddCents(extra int) {
	// TODO: provide a discount operation that reduces the original expense.
	e.Cents += extra
}

func main() {
	expense := Expense{Label: "Tea", Cents: 250}
	fmt.Println(expense.String())
	expense.AddCents(50)
	fmt.Println(expense.String())
	copyExpense := expense
	copyExpense.Label = "Copy"
	fmt.Println("Original label:", expense.Label)
}
