package app

import (
	"fmt"

	"example.com/code101/go301/l04/try/domain"
)

// Mailer is defined where it is used and lists only what Billing calls.
type Mailer interface {
	Send(to, subject, body string) error
}

type Billing struct {
	mailer Mailer
}

func NewBilling(mailer Mailer) *Billing {
	return &Billing{mailer: mailer}
}

func (b *Billing) Send(inv domain.Invoice) error {
	subject := fmt.Sprintf("Invoice %d", inv.ID)
	body := fmt.Sprintf("Amount due: %d cents", inv.Cents)
	return b.mailer.Send(inv.Email, subject, body)
}
