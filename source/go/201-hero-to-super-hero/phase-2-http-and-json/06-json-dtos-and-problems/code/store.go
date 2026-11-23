package main

import "sync"

// Book is the internal (domain) type. Clients never receive it directly:
// InternalNote must not leak, so the API answers with BookResponse instead.
type Book struct {
	ID           int
	Title        string
	Author       string
	Pages        int
	InternalNote string
}

// Store keeps books in memory, safe for concurrent use.
type Store struct {
	mu     sync.Mutex
	nextID int
	books  map[int]Book
}

func NewStore() *Store {
	return &Store{nextID: 1, books: make(map[int]Book)}
}

// Create assigns the next ID, stores the book and returns it.
func (s *Store) Create(b Book) Book {
	s.mu.Lock()
	defer s.mu.Unlock()
	b.ID = s.nextID
	s.nextID++
	s.books[b.ID] = b
	return b
}

func (s *Store) Get(id int) (Book, bool) {
	s.mu.Lock()
	defer s.mu.Unlock()
	b, ok := s.books[id]
	return b, ok
}
