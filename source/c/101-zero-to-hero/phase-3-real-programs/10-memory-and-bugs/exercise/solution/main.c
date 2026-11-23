#include <stdio.h>
#include <stdlib.h>

int main(void) {
    int n = 0;
    printf("How many numbers (1 to 10)?\n");
    if (scanf("%d", &n) != 1 || n < 1 || n > 10) {
        printf("Use a whole number from 1 to 10.\n");
        return 1;
    }
    int *numbers = malloc((size_t)n * sizeof *numbers);
    if (numbers == NULL) {
        printf("Out of memory.\n");
        return 1;
    }
    int sum = 0;
    for (int i = 0; i < n; i++) {
        if (scanf("%d", &numbers[i]) != 1) {
            printf("Use whole numbers.\n");
            free(numbers);
            return 1;
        }
        sum += numbers[i];
    }
    printf("Sum: %d\n", sum);
    free(numbers);
    return 0;
}
