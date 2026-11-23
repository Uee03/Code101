#include <stdio.h>

#define COUNT 6

int main(void) {
    int scores[COUNT] = {72, 45, 90, 38, 66, 51};
    int lowest = scores[0];
    int passed = 0;
    /* TODO: loop over the array to find the lowest score and to count the scores that are 50 or more. */
    printf("Lowest: %d\n", lowest);
    printf("Passed: %d\n", passed);
    return 0;
}
