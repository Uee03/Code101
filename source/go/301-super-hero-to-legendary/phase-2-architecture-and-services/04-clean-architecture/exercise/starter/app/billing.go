package app

import (
	"fmt"

	"example.com/code101/go301/l04/try/adapters/smtp"
	"example.com/code101/go301/l04/try/domain"
)

// TODO: the dependency points the wrong way. app imports the concrete smtp
// adapter. Define a small interface here, at the consumer, with only the method
// Billing calls; make the field and NewBilling use it; delete the smtp import.
type Billing struct {
	mailer smtp.Client
}

func NewBilling(mailer smtp.Client) *Billing {
	return &Billing{mailer: mailer}
}

func (b *Billing) Send(inv domain.Invoice) error {
	subject := fmt.Sprintf("Invoice %d", inv.ID)
	body := fmt.Sprintf("Amount due: %d cents", inv.Cents)
	return b.mailer.Send(inv.Email, subject, body)
}
