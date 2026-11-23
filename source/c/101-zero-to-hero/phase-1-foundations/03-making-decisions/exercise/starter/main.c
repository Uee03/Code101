#include <stdio.h>

int main(void) {
    int score = 0;
    printf("Score (0 to 100):\n");
    if (scanf("%d", &score) != 1) {
        printf("Use a whole number.\n");
        return 1;
    }
    /* TODO: print "Invalid score" and stop when the score is below 0 or above 100. */
    /* TODO: print "Grade: A" for 90 or more, "Grade: B" for 80 to 89, "Grade: C" for 70 to 79, and "Grade: F" otherwise. */
    return 0;
}
