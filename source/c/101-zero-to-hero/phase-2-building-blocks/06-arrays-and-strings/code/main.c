#include <stdio.h>
#include <string.h>

#define DAYS 5

int main(void) {
    int temps[DAYS] = {18, 21, 19, 25, 22};
    int sum = 0;
    int highest = temps[0];
    for (int i = 0; i < DAYS; i++) {
        sum += temps[i];
        if (temps[i] > highest) {
            highest = temps[i];
        }
    }
    printf("Average: %.1f\n", sum / (double)DAYS);
    printf("Highest: %d\n", highest);

    char name[32];
    printf("Your name:\n");
    if (fgets(name, sizeof name, stdin) == NULL) {
        printf("No name read.\n");
        return 1;
    }
    name[strcspn(name, "\r\n")] = '\0';
    printf("Hello, %s! Your name has %zu letters.\n", name, strlen(name));

    if (strcmp(name, "Ada") == 0) {
        printf("Welcome back, Ada.\n");
    }

    int count_a = 0;
    for (int i = 0; name[i] != '\0'; i++) {
        if (name[i] == 'a' || name[i] == 'A') {
            count_a++;
        }
    }
    printf("The letter a appears %d time(s).\n", count_a);
    return 0;
}
