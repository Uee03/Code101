#include <stdio.h>
#include <string.h>

#include "expense.h"

#define DATA_FILE "expenses.csv"

static void print_money(long cents) {
    printf("%ld.%02ld", cents / 100, cents % 100);
}

static void print_help(void) {
    printf("Commands:\n");
    printf("  add <category> <amount>   for example: add food 12.50\n");
    printf("  list\n");
    printf("  total\n");
    printf("  quit\n");
}

static void do_add(ExpenseList *list, const char *args) {
    char category[CATEGORY_SIZE];
    double amount = 0.0;
    if (sscanf(args, "%19s %lf", category, &amount) != 2) {
        printf("Usage: add <category> <amount>\n");
        return;
    }
    if (strchr(category, ',') != NULL) {
        printf("The category cannot contain a comma.\n");
        return;
    }
    if (amount <= 0.0 || amount > 100000.0) {
        printf("Amount must be above 0 and at most 100000.\n");
        return;
    }
    int cents = (int)(amount * 100.0 + 0.5);
    if (!list_add(list, category, cents)) {
        printf("Out of memory.\n");
        return;
    }
    printf("Added %s ", category);
    print_money(cents);
    printf("\n");
}

static void do_list(const ExpenseList *list) {
    if (list->count == 0) {
        printf("No expenses yet.\n");
        return;
    }
    for (size_t i = 0; i < list->count; i++) {
        printf("%zu. %s ", i + 1, list->items[i].category);
        print_money(list->items[i].cents);
        printf("\n");
    }
}

int main(void) {
    ExpenseList list;
    list_init(&list);
    if (!list_load(&list, DATA_FILE)) {
        printf("Could not load %s.\n", DATA_FILE);
        list_free(&list);
        return 1;
    }
    printf("Expense tracker. %zu expense(s) loaded. Type help for commands.\n", list.count);

    char line[100];
    for (;;) {
        printf("> ");
        fflush(stdout);
        if (fgets(line, sizeof line, stdin) == NULL) {
            break;
        }
        char command[20];
        char rest[80] = "";
        int parts = sscanf(line, "%19s %79[^\n]", command, rest);
        if (parts < 1) {
            continue;
        }
        /* TODO: add a count command that prints "Expenses: " followed by how many expenses are in the list. */
        if (strcmp(command, "add") == 0) {
            do_add(&list, rest);
        } else if (strcmp(command, "list") == 0) {
            do_list(&list);
        } else if (strcmp(command, "total") == 0) {
            printf("Total: ");
            print_money(list_total(&list));
            printf("\n");
        } else if (strcmp(command, "help") == 0) {
            print_help();
        } else if (strcmp(command, "quit") == 0) {
            break;
        } else {
            printf("Unknown command: %s (type help)\n", command);
        }
    }

    int saved = list_save(&list, DATA_FILE);
    if (saved) {
        printf("Saved %zu expense(s) to %s.\n", list.count, DATA_FILE);
    } else {
        printf("Could not save %s.\n", DATA_FILE);
    }
    list_free(&list);
    return saved ? 0 : 1;
}
