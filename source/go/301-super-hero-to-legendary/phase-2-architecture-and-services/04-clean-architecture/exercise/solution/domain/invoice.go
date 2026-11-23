package domain

// Invoice is the business entity. It imports nothing.
type Invoice struct {
	ID    int
	Email string
	Cents int
}
