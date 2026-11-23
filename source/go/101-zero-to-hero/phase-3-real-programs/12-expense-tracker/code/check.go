package main

import "errors"

// selfCheck is a few plain checks, not a test framework.
func selfCheck() error {
	expense, err := parseRow("Tea,250")
	if err != nil {
		return err
	}
	if expense.Label != "Tea" || expense.Cents != 250 {
		return errors.New("row values differ")
	}
	if money(305) != "3.05" {
		return errors.New("money formatting differs")
	}
	_, err = parseRow("Tea,0")
	if err == nil {
		return errors.New("zero amount was accepted")
	}
	return nil
}
