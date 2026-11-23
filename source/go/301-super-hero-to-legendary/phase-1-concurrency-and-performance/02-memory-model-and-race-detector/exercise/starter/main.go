package main

import (
	"fmt"
	"sync"
)

type Account struct {
	balance int
}

// TODO 1: add a sync.Mutex field and use it in both methods so that the
// balance printed by main is always 4000 and `go run -race .` reports nothing.
func (a *Account) Deposit(n int) { a.balance += n }
func (a *Account) Balance() int  { return a.balance }

func main() {
	acc := &Account{}
	var wg sync.WaitGroup
	for range 8 {
		wg.Go(func() {
			for range 500 {
				acc.Deposit(1)
			}
		})
	}
	wg.Wait()
	fmt.Println("balance:", acc.Balance())
}
