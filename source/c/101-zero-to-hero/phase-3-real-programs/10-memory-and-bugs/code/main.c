#include <stdio.h>
#include <stdlib.h>
#include <string.h>

int main(void) {
    int count = 0;
    printf("How many squares (1 to 20)?\n");
    if (scanf("%d", &count) != 1 || count < 1 || count > 20) {
        printf("Use a whole number from 1 to 20.\n");
        return 1;
    }

    int *squares = malloc((size_t)count * sizeof *squares);
    if (squares == NULL) {
        printf("Out of memory.\n");
        return 1;
    }
    for (int i = 0; i < count; i++) {
        squares[i] = (i + 1) * (i + 1);
    }
    for (int i = 0; i < count; i++) {
        printf("%d squared is %d\n", i + 1, squares[i]);
    }

    int *bigger = realloc(squares, (size_t)(count + 2) * sizeof *bigger);
    if (bigger == NULL) {
        free(squares);
        printf("Out of memory.\n");
        return 1;
    }
    squares = bigger;
    squares[count] = (count + 1) * (count + 1);
    squares[count + 1] = (count + 2) * (count + 2);
    printf("After growing: last is %d\n", squares[count + 1]);
    free(squares);
    squares = NULL;

    const char *word = "memory";
    char *copy = malloc(strlen(word) + 1);
    if (copy == NULL) {
        printf("Out of memory.\n");
        return 1;
    }
    strcpy(copy, word);
    copy[0] = 'M';
    printf("Copy: %s, original: %s\n", copy, word);
    free(copy);
    return 0;
}
