#include <stdio.h>

int main(void) {
    int n = 0;
    printf("Table for which number (1 to 12)?\n");
    if (scanf("%d", &n) != 1 || n < 1 || n > 12) {
        printf("Use a whole number from 1 to 12.\n");
        return 1;
    }
    for (int row = 1; row <= 10; row++) {
        printf("%d x %d = %d\n", n, row, n * row);
    }
    return 0;
}
