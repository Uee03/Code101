package app

import (
	"testing"

	"example.com/code101/go301/l04/try/domain"
)

type recordingMailer struct {
	to, subject, body string
}

func (r *recordingMailer) Send(to, subject, body string) error {
	r.to, r.subject, r.body = to, subject, body
	return nil
}

func TestBillingSendsInvoiceEmail(t *testing.T) {
	m := &recordingMailer{}
	err := NewBilling(m).Send(domain.Invoice{ID: 7, Email: "ada@example.com", Cents: 1250})
	if err != nil {
		t.Fatal(err)
	}
	if m.to != "ada@example.com" || m.subject != "Invoice 7" || m.body != "Amount due: 1250 cents" {
		t.Fatalf("unexpected email %+v", m)
	}
}
