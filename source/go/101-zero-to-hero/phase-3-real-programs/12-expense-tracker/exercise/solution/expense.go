package main

import (
	"bufio"
	"errors"
	"fmt"
	"os"
	"strconv"
	"strings"
)

type Expense struct {
	Label string
	Cents int
}

func money(cents int) string {
	return fmt.Sprintf("%d.%02d", cents/100, cents%100)
}

func (e Expense) String() string {
	return e.Label + ": " + money(e.Cents)
}

func parseRow(row string) (Expense, error) {
	fields := strings.Split(row, ",")
	if len(fields) != 2 {
		return Expense{}, errors.New("expected label,cents")
	}
	label := strings.TrimSpace(fields[0])
	if label == "" || strings.ContainsAny(label, "\"\r\n") {
		return Expense{}, errors.New("label must be nonempty, with no quotes or newlines")
	}
	cents, err := strconv.Atoi(fields[1])
	if err != nil {
		return Expense{}, fmt.Errorf("cents: %w", err)
	}
	if cents <= 0 || cents > 1000000 {
		return Expense{}, errors.New("cents must be from 1 to 1000000")
	}
	return Expense{Label: label, Cents: cents}, nil
}

func load(path string) ([]Expense, error) {
	data, err := os.ReadFile(path)
	if os.IsNotExist(err) {
		return []Expense{}, nil
	}
	if err != nil {
		return nil, fmt.Errorf("load: %w", err)
	}
	scanner := bufio.NewScanner(strings.NewReader(string(data)))
	if !scanner.Scan() || scanner.Text() != "label,cents" {
		return nil, errors.New("expected label,cents header")
	}
	expenses := []Expense{}
	for scanner.Scan() {
		expense, err := parseRow(scanner.Text())
		if err != nil {
			return nil, fmt.Errorf("row %d: %w", len(expenses)+2, err)
		}
		if len(expenses) >= 1000 {
			return nil, errors.New("maximum 1000 expenses")
		}
		expenses = append(expenses, expense)
	}
	if err := scanner.Err(); err != nil {
		return nil, err
	}
	return expenses, nil
}

func save(path string, expenses []Expense) error {
	text := "label,cents\n"
	for _, expense := range expenses {
		text += expense.Label + "," + strconv.Itoa(expense.Cents) + "\n"
	}
	return os.WriteFile(path, []byte(text), 0600)
}
