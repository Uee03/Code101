#include <stdio.h>
#include <stdlib.h>

int main(void) {
    int *numbers = malloc(3 * sizeof *numbers);
    if (numbers == NULL) {
        return 1;
    }
    numbers[0] = 10;
    numbers[1] = 20;
    numbers[2] = 30;
    free(numbers);
    printf("First number: %d\n", numbers[0]);
    return 0;
}
