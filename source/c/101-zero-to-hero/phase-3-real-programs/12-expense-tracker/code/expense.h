#ifndef EXPENSE_H
#define EXPENSE_H

#include <stddef.h>

#define CATEGORY_SIZE 20

typedef struct {
    char category[CATEGORY_SIZE];
    int cents;
} Expense;

typedef struct {
    Expense *items;
    size_t count;
    size_t capacity;
} ExpenseList;

void list_init(ExpenseList *list);
void list_free(ExpenseList *list);
int list_add(ExpenseList *list, const char *category, int cents);
long list_total(const ExpenseList *list);
int list_save(const ExpenseList *list, const char *path);
int list_load(ExpenseList *list, const char *path);

#endif
