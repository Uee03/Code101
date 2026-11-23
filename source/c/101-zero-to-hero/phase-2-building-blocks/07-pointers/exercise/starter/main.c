#include <stdio.h>

void double_it(int *n);
void min_max(const int *values, int count, int *min, int *max);

int main(void) {
    int n = 21;
    double_it(&n);
    printf("n is %d\n", n);

    int values[5] = {7, 3, 9, 1, 5};
    int low = 0;
    int high = 0;
    min_max(values, 5, &low, &high);
    printf("low %d high %d\n", low, high);
    return 0;
}

void double_it(int *n) {
    /* TODO: make the number that n points to twice as big. */
}

void min_max(const int *values, int count, int *min, int *max) {
    /* TODO: store the smallest value in *min and the largest value in *max. */
}
