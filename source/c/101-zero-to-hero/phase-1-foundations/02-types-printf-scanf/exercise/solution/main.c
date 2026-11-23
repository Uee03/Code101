#include <stdio.h>

int main(void) {
    int bottles = 24;
    double price = 1.25;
    printf("Shop opened with %d bottles at %.2f each\n", bottles, price);
    int sold = 5;
    bottles = bottles - sold;
    printf("Bottles left: %d\n", bottles);
    printf("Income: %.2f\n", sold * price);
    return 0;
}
