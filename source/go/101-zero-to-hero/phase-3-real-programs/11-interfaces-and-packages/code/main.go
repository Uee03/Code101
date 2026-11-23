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

func main() {
	report := receipt.Receipt{Label: "Tea", Cents: 300}
	printReport(report)
}
