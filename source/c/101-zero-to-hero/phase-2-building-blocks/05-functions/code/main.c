#include <stdio.h>

double add_tip(double bill, double percent);
double split(double total, int people);
int square(int x);
void try_to_change(int n);

int main(void) {
    double total = add_tip(80.0, 15.0);
    printf("Total with tip: %.2f\n", total);
    printf("Each of 2: %.2f\n", split(total, 2));

    int n = 5;
    try_to_change(n);
    printf("n is still %d\n", n);

    printf("Square of 7 is %d\n", square(7));
    return 0;
}

double add_tip(double bill, double percent) {
    return bill + bill * percent / 100;
}

double split(double total, int people) {
    return total / people;
}

int square(int x) {
    return x * x;
}

void try_to_change(int n) {
    n = 99;
    printf("Inside the function n is %d\n", n);
}
