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

type Note struct {
	Text string
}

func (n Note) Summary() string {
	return n.Text
}

func main() {
	report := receipt.Receipt{Label: "Tea", Cents: 300}
	printReport(report)
	printReport(Note{Text: "Paid"})
}
