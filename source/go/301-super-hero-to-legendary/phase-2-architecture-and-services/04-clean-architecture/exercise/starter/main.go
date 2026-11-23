package main

import (
	"fmt"
	"os"

	"example.com/code101/go301/l04/try/adapters/smtp"
	"example.com/code101/go301/l04/try/app"
	"example.com/code101/go301/l04/try/domain"
)

func main() {
	billing := app.NewBilling(smtp.Client{})
	if err := billing.Send(domain.Invoice{ID: 7, Email: "ada@example.com", Cents: 1250}); err != nil {
		fmt.Fprintln(os.Stderr, "error:", err)
		os.Exit(1)
	}
	fmt.Println("sent invoice 7")
}
