#include <stdio.h>

#define COUNT 6

int main(void) {
    int scores[COUNT] = {72, 45, 90, 38, 66, 51};
    int lowest = scores[0];
    int passed = 0;
    for (int i = 0; i < COUNT; i++) {
        if (scores[i] < lowest) {
            lowest = scores[i];
        }
        if (scores[i] >= 50) {
            passed++;
        }
    }
    printf("Lowest: %d\n", lowest);
    printf("Passed: %d\n", passed);
    return 0;
}
