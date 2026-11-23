#include <stdio.h>

#define LINE_SIZE 100

int main(void) {
    const char *path = "shopping.txt";

    FILE *out = fopen(path, "w");
    if (out == NULL) {
        printf("Cannot write %s\n", path);
        return 1;
    }
    fprintf(out, "milk,2,1.20\n");
    fprintf(out, "bread,1,2.50\n");
    fclose(out);

    out = fopen(path, "a");
    if (out == NULL) {
        printf("Cannot append to %s\n", path);
        return 1;
    }
    fprintf(out, "apples,6,0.40\n");
    fclose(out);

    FILE *in = fopen(path, "r");
    if (in == NULL) {
        printf("Cannot read %s\n", path);
        return 1;
    }
    char line[LINE_SIZE];
    int lines = 0;
    double total = 0.0;
    while (fgets(line, sizeof line, in) != NULL) {
        char name[30];
        int quantity = 0;
        double price = 0.0;
        if (sscanf(line, "%29[^,],%d,%lf", name, &quantity, &price) != 3) {
            printf("Skipping bad line: %s", line);
            continue;
        }
        lines++;
        printf("%s: %d x %.2f\n", name, quantity, price);
        total += quantity * price;
    }
    fclose(in);
    printf("Lines read: %d\n", lines);
    printf("Total: %.2f\n", total);

    FILE *missing = fopen("does-not-exist.txt", "r");
    if (missing == NULL) {
        printf("Could not open does-not-exist.txt (as expected)\n");
    } else {
        fclose(missing);
    }
    return 0;
}
