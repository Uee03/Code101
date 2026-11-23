package main

import (
	"fmt"
	"sync"
)

type Account struct {
	mu      sync.Mutex
	balance int
}

func (a *Account) Deposit(n int) {
	a.mu.Lock()
	defer a.mu.Unlock()
	a.balance += n
}

func (a *Account) Balance() int {
	a.mu.Lock()
	defer a.mu.Unlock()
	return a.balance
}

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
