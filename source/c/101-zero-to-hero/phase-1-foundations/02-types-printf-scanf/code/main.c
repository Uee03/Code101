#include <stdio.h>

int main(void) {
    double bill = 0.0;
    double percent = 0.0;
    int people = 0;

    printf("Bill amount (e.g. 80):\n");
    if (scanf("%lf", &bill) != 1) {
        printf("Use digits for the bill.\n");
        return 1;
    }
    printf("Tip percent (e.g. 15):\n");
    if (scanf("%lf", &percent) != 1) {
        printf("Use digits for the percent.\n");
        return 1;
    }
    printf("Number of people:\n");
    if (scanf("%d", &people) != 1) {
        printf("Use a whole number of people.\n");
        return 1;
    }
    if (bill < 0 || percent < 0 || people <= 0) {
        printf("Amounts must be nonnegative; people must be positive.\n");
        return 1;
    }

    double tip = bill * percent / 100;
    double total = bill + tip;
    double each = total / people;
    printf("Tip: %.2f\nTotal: %.2f\nEach: %.2f\n", tip, total, each);
    printf("Whole division: %d Remainder: %d\n", 7 / 2, 7 % 2);
    return 0;
}
