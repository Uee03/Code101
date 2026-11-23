#include <stdio.h>

int main(void) {
    int score = 0;
    printf("Score (0 to 100):\n");
    if (scanf("%d", &score) != 1) {
        printf("Use a whole number.\n");
        return 1;
    }
    if (score < 0 || score > 100) {
        printf("Invalid score\n");
        return 1;
    }
    if (score >= 90) {
        printf("Grade: A\n");
    } else if (score >= 80) {
        printf("Grade: B\n");
    } else if (score >= 70) {
        printf("Grade: C\n");
    } else {
        printf("Grade: F\n");
    }
    return 0;
}
