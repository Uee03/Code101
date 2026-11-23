#include <stdio.h>

int main(void) {
    int count = 0;
    printf("How many numbers to add (1 to 10)?\n");
    if (scanf("%d", &count) != 1 || count < 1 || count > 10) {
        printf("Use a whole number from 1 to 10.\n");
        return 1;
    }

    int sum = 0;
    for (int i = 1; i <= count; i++) {
        sum += i;
        printf("Added %d, sum is %d\n", i, sum);
    }

    printf("Countdown:\n");
    int n = count;
    while (n > 0) {
        printf("%d\n", n);
        n--;
    }
    printf("Liftoff!\n");

    int digits = 0;
    int value = sum;
    do {
        digits++;
        value /= 10;
    } while (value > 0);
    printf("The sum has %d digit(s)\n", digits);

    printf("Odd numbers up to %d:\n", count);
    for (int i = 1; i <= count; i++) {
        if (i % 2 == 0) {
            continue;
        }
        printf("%d\n", i);
    }

    for (int i = 1; i <= count; i++) {
        if (i % 3 == 0) {
            printf("First multiple of 3: %d\n", i);
            break;
        }
    }
    return 0;
}
