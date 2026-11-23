#include <stdio.h>

int main(void) {
    FILE *out = fopen("scores.txt", "w");
    if (out == NULL) {
        printf("Cannot write scores.txt\n");
        return 1;
    }
    fprintf(out, "72\n45\n90\n");
    fclose(out);

    int highest = 0;
    /* TODO: open scores.txt for reading, read every number from it, and keep the largest one in highest. */
    printf("Highest: %d\n", highest);
    return 0;
}
