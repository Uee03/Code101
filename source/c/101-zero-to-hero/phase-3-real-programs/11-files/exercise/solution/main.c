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
    FILE *in = fopen("scores.txt", "r");
    if (in == NULL) {
        printf("Cannot read scores.txt\n");
        return 1;
    }
    int value = 0;
    while (fscanf(in, "%d", &value) == 1) {
        if (value > highest) {
            highest = value;
        }
    }
    fclose(in);
    printf("Highest: %d\n", highest);
    return 0;
}
