#include <stdio.h>
#include <stdlib.h>

int main(void) {
    int n = 0;
    printf("How many numbers (1 to 10)?\n");
    if (scanf("%d", &n) != 1 || n < 1 || n > 10) {
        printf("Use a whole number from 1 to 10.\n");
        return 1;
    }
    /* TODO: allocate room for n ints, stop with a message if that fails, and free the memory before the program ends. */
    int sum = 0;
    /* TODO: read n numbers into that memory with scanf and add them to sum. */
    printf("Sum: %d\n", sum);
    return 0;
}
