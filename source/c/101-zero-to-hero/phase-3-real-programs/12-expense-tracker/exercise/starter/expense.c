#include "expense.h"

#include <stdio.h>
#include <stdlib.h>
#include <string.h>

void list_init(ExpenseList *list) {
    list->items = NULL;
    list->count = 0;
    list->capacity = 0;
}

void list_free(ExpenseList *list) {
    free(list->items);
    list_init(list);
}

int list_add(ExpenseList *list, const char *category, int cents) {
    if (list->count == list->capacity) {
        size_t new_capacity = list->capacity == 0 ? 4 : list->capacity * 2;
        Expense *bigger = realloc(list->items, new_capacity * sizeof *bigger);
        if (bigger == NULL) {
            return 0;
        }
        list->items = bigger;
        list->capacity = new_capacity;
    }
    Expense *slot = &list->items[list->count];
    snprintf(slot->category, sizeof slot->category, "%s", category);
    slot->cents = cents;
    list->count++;
    return 1;
}

long list_total(const ExpenseList *list) {
    long total = 0;
    for (size_t i = 0; i < list->count; i++) {
        total += list->items[i].cents;
    }
    return total;
}

int list_save(const ExpenseList *list, const char *path) {
    FILE *out = fopen(path, "w");
    if (out == NULL) {
        return 0;
    }
    for (size_t i = 0; i < list->count; i++) {
        fprintf(out, "%s,%d\n", list->items[i].category, list->items[i].cents);
    }
    fclose(out);
    return 1;
}

int list_load(ExpenseList *list, const char *path) {
    FILE *in = fopen(path, "r");
    if (in == NULL) {
        return 1;
    }
    char line[100];
    while (fgets(line, sizeof line, in) != NULL) {
        char category[CATEGORY_SIZE];
        int cents = 0;
        /* 19 is CATEGORY_SIZE minus one, leaving room for the end-of-text character. */
        if (sscanf(line, "%19[^,],%d", category, &cents) == 2 && cents > 0) {
            if (!list_add(list, category, cents)) {
                fclose(in);
                return 0;
            }
        }
    }
    fclose(in);
    return 1;
}
