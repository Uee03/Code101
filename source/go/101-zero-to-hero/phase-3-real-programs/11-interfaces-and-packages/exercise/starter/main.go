package main

import (
	"example.com/code101/lesson11/receipt"
	"fmt"
)

type Reporter interface {
	Summary() string
}

func printReport(report Reporter) {
	fmt.Println(report.Summary())
}

// TODO: make Note usable by printReport; demonstrate a note reading Paid.
type Note struct {
	Text string
}

func main() {
	report := receipt.Receipt{Label: "Tea", Cents: 300}
	printReport(report)
}
