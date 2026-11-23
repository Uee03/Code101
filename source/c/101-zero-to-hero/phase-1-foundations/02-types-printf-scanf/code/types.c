#include <stdio.h>

int main(void) {
    int apples = 12;
    double price = 0.5;
    char grade = 'A';
    const int dozen = 12;

    printf("Apples: %d\n", apples);
    printf("Price: %.2f\n", price);
    printf("Grade: %c\n", grade);
    printf("A dozen is %d\n", dozen);
    printf("Value: %.2f\n", apples * price);
    apples = apples + 3;
    printf("Apples now: %d\n", apples);
    return 0;
}
