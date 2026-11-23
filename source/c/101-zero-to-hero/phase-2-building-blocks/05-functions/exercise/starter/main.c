#include <stdio.h>

int is_even(int n);
double average(int a, int b, int c);

int main(void) {
    printf("4 even? %d\n", is_even(4));
    printf("7 even? %d\n", is_even(7));
    printf("Average of 4, 7, 10: %.2f\n", average(4, 7, 10));
    return 0;
}

int is_even(int n) {
    /* TODO: return 1 when n is even, otherwise return 0. */
    return 0;
}

double average(int a, int b, int c) {
    /* TODO: return the average of the three numbers, keeping the decimals. */
    return 0.0;
}
