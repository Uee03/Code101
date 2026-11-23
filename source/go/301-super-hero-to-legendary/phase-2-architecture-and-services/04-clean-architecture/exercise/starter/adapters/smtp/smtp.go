package smtp

import "fmt"

// Client pretends to send mail by printing it.
type Client struct{}

func (Client) Send(to, subject, body string) error {
	fmt.Printf("fake smtp: to=%s subject=%q body=%q\n", to, subject, body)
	return nil
}
