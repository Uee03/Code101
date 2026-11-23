#include <stdio.h>

int main(void) {
    int n = 0;
    printf("Table for which number (1 to 12)?\n");
    if (scanf("%d", &n) != 1 || n < 1 || n > 12) {
        printf("Use a whole number from 1 to 12.\n");
        return 1;
    }
    /* TODO: print the rows of the table for rows 1 to 10, one per line, in the form 3 x 1 = 3. */
    return 0;
}
