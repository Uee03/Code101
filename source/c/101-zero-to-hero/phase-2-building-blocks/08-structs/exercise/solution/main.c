#include <stdio.h>

typedef struct {
    char title[30];
    int pages;
    double price;
} Book;

void print_book(const Book *book);
void discount(Book *book, double percent);

int main(void) {
    Book book = {"C Basics", 200, 40.00};
    print_book(&book);
    discount(&book, 25);
    print_book(&book);
    return 0;
}

void print_book(const Book *book) {
    printf("%s, %d pages, %.2f\n", book->title, book->pages, book->price);
}

void discount(Book *book, double percent) {
    book->price = book->price * (100 - percent) / 100;
}
