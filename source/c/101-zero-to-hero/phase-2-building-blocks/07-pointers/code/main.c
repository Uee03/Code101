#include <stdio.h>

void swap(int *a, int *b);
void add_bonus(int *points, int bonus);
int total(const int *values, int count);

int main(void) {
    int score = 10;
    int *p = &score;
    printf("score is %d\n", score);
    printf("through the pointer: %d\n", *p);
    if (p == &score) {
        printf("p holds the address of score\n");
    }
    *p = 20;
    printf("score after *p = 20: %d\n", score);

    int x = 3;
    int y = 8;
    swap(&x, &y);
    printf("x=%d y=%d\n", x, y);

    add_bonus(&score, 5);
    printf("score with bonus: %d\n", score);

    int values[4] = {1, 2, 3, 4};
    printf("total: %d\n", total(values, 4));
    int *start = values;
    printf("second value: %d\n", *(start + 1));

    int *nothing = NULL;
    if (nothing == NULL) {
        printf("nothing points nowhere\n");
    }
    return 0;
}

void swap(int *a, int *b) {
    int temp = *a;
    *a = *b;
    *b = temp;
}

void add_bonus(int *points, int bonus) {
    *points = *points + bonus;
}

int total(const int *values, int count) {
    int sum = 0;
    for (int i = 0; i < count; i++) {
        sum += values[i];
    }
    return sum;
}
